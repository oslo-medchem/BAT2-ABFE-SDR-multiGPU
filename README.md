# GPU-Only Equilibration Runner

## Overview

This script runs equilibration jobs on GPUs with **robust memory checking**:
- ✅ Checks actual GPU free memory before submitting jobs
- ✅ Waits for GPU with sufficient free memory
- ✅ One job per GPU at a time
- ✅ NO CPU fallback
- ✅ Dynamic job submission based on real GPU availability

## How It Works

### Memory Checking
Before submitting a job, the script:
1. Queries `nvidia-smi` for GPU free memory
2. Checks if free memory ≥ 8000 MB (configurable)
3. Only submits job if enough memory is available
4. Otherwise, waits and rechecks every 3 seconds

### Job Assignment
- Finds first GPU with enough free memory
- Assigns exactly ONE job to that GPU
- Tracks which GPU is running which job
- When job finishes, GPU becomes available again

### Waiting for Availability
If all GPUs are busy or have insufficient memory:
- Script waits and displays status every 30 seconds
- Shows memory status for each GPU
- Automatically submits job when GPU becomes ready

## Usage

```bash
# From BAT directory
bash run_equil_all_gpus.bash
```

## Configuration

Edit these parameters at the top of the script:

```bash
NUM_GPUS=8                     # Number of GPUs to use (0-7)
REQUIRED_FREE_MEMORY=8000      # Minimum free memory in MB
EQUIL_DIR="./equil"
```

### Adjusting Memory Requirement

If you need more/less memory per job:
```bash
REQUIRED_FREE_MEMORY=10000     # 10 GB
REQUIRED_FREE_MEMORY=6000      # 6 GB
```

## What You'll See

```
========================================================================
GPU-Only Equilibration Runner with Memory Checking
========================================================================
Working directory: /path/to/BAT
Log directory: /path/to/BAT/equil_logs
Number of GPUs: 8
Required free memory: 8000 MB
========================================================================

Initial GPU Status:
  GPU 0: NVIDIA GPU | Total: 11264 MiB | Free: 11020 MiB | Used: 244 MiB
  GPU 1: NVIDIA GPU | Total: 11264 MiB | Free: 11020 MiB | Used: 244 MiB
  ...

Found 12 ligand folders

[23:45:00] Starting lig-afa on GPU 0 (11020 MB free)

GPU Memory Status:
  GPU 0:  4500 MB free - BUSY: lig-afa
  GPU 1: 11020 MB free - AVAILABLE
  GPU 2: 11020 MB free - AVAILABLE
  ...

[23:45:02] Starting lig-afp on GPU 1 (11020 MB free)

GPU Memory Status:
  GPU 0:  4500 MB free - BUSY: lig-afa
  GPU 1:  4300 MB free - BUSY: lig-afp
  GPU 2: 11020 MB free - AVAILABLE
  ...
```

### When Waiting for Memory

```
[23:45:10] All GPUs busy or insufficient memory, waiting...
[23:45:10] Waiting for GPU with 8000MB+ free memory...

GPU Memory Status:
  GPU 0:  4500 MB free - BUSY: lig-afa
  GPU 1:  4300 MB free - BUSY: lig-afp
  GPU 2:  4100 MB free - BUSY: lig-dac
  GPU 3:  4000 MB free - BUSY: lig-dap
  GPU 4:  3900 MB free - BUSY: lig-erl
  GPU 5:  3800 MB free - BUSY: lig-fmm
  GPU 6:  3700 MB free - BUSY: lig-gef
  GPU 7:  3600 MB free - BUSY: lig-gep

[23:46:15] ✓ Completed: lig-afa (GPU 0)
[23:46:16] Starting lig-lap on GPU 0 (10850 MB free)
```

## Output Files

Logs saved to `equil_logs/`:
```
equil_logs/
├── lig-afa_gpu0.log
├── lig-afp_gpu1.log
├── lig-dac_gpu2.log
└── ...
```

Each log contains:
```
=== Job Started: Fri Dec 13 23:45:00 2025 ===
Ligand: lig-afa
GPU: 0
GPU Free Memory at Start: 11020 MB
Working Directory: /path/to/BAT/equil/lig-afa

[... run-local.bash output ...]

=== Job Finished: Fri Dec 13 23:55:00 2025 ===
Exit Code: 0
```

## Monitoring

### Real-time Monitor
```bash
bash monitor_equil.bash
```

### Check Status
```bash
bash check_status.bash
```

### Watch GPU Memory
```bash
watch -n 1 nvidia-smi
```

## Summary After Completion

```
Summary:
  Total: 12
  ✓ Completed: 10
  ✗ Failed: 2

Failed jobs:
  - lig-lap
  - lig-pdp

Logs in: /path/to/BAT/equil_logs
```

## Troubleshooting

### Jobs not starting?

**Check GPU memory manually:**
```bash
nvidia-smi --query-gpu=index,memory.free --format=csv,noheader
```

Make sure at least one GPU has ≥ 8000 MB free.

### Still getting OOM errors?

**Increase the memory requirement:**
```bash
# Edit run_equil_all_gpus.bash
REQUIRED_FREE_MEMORY=10000     # Require 10 GB instead of 8 GB
```

### Jobs failing immediately?

**Check a log file:**
```bash
tail -50 equil_logs/lig-afa_gpu0.log
```

**Run one manually to see full error:**
```bash
cd equil/lig-afa
export CUDA_VISIBLE_DEVICES=0
bash run-local.bash
```

### Clean up stuck processes

```bash
bash cleanup_jobs.bash
```

## How This Solves Your Issue

**Problem:** GPUs showed as "free" but jobs failed with OOM

**Solution:** 
- Script now checks **actual free memory** (not just utilization)
- Only submits job when GPU has ≥ 8000 MB free
- Waits for sufficient memory before submission
- One job per GPU prevents memory competition

## Key Features

✅ **Robust memory checking** - Uses real nvidia-smi memory data
✅ **Dynamic submission** - Waits for actual availability
✅ **One job per GPU** - No overloading
✅ **NO CPU fallback** - GPU-only as requested
✅ **Clear status** - Shows which GPU has which job

## Performance

With 8 GPUs and proper memory:
- All 8 GPUs working simultaneously
- ~10-30 minutes per ligand (GPU speed)
- 12 ligands in ~20-40 minutes total (with parallelization)

Much faster than CPU if memory requirements are met!
