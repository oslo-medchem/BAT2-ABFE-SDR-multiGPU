# Equilibration Workflow

Complete guide for running equilibration simulations with GPU-based job management.

## Overview

The equilibration workflow runs SDR (structure refinement) equilibration simulations for all ligands in your BAT project. Each ligand gets its own equilibration job assigned to an available GPU.

## Directory Structure

```
BAT/
├── equil/
│   ├── lig-fmm/
│   │   ├── run-local.bash
│   │   ├── equil.in
│   │   ├── *.rst7
│   │   └── *.prmtop
│   ├── lig-gef/
│   │   ├── run-local.bash
│   │   └── ...
│   └── ...
└── equil_logs/  # Created by script
```

## Quick Start

```bash
# Navigate to BAT directory
cd /path/to/BAT

# Run equilibration
bash /path/to/bat-gpu-runner/scripts/equil/run_equil_all_gpus.bash

# Monitor progress (in another terminal)
bash /path/to/bat-gpu-runner/scripts/utils/monitor.bash
```

## Step-by-Step Guide

### 1. Prepare Input Files

Ensure each ligand folder contains:
- `run-local.bash` - Execution script
- Equilibration input files (`.in`)
- Coordinate files (`.rst7`)
- Topology files (`.prmtop`)

**Example run-local.bash:**
```bash
#!/bin/bash
pmemd.cuda -O -i equil.in -p complex.prmtop -c complex.rst7 -r equil.rst7 -o equil.out
```

### 2. Run Equilibration

```bash
cd /path/to/BAT
bash /path/to/bat-gpu-runner/scripts/equil/run_equil_all_gpus.bash
```

### 3. Monitor Progress

**Real-time monitor:**
```bash
bash /path/to/bat-gpu-runner/scripts/utils/monitor.bash
```

**Output:**
```
========================================================================
Equilibration Monitor - 23:50:15
========================================================================

Running Processes:
  run-local.bash: 8
  pmemd: 8

Job Status:
  Total started: 12
  ✓ Completed: 3
  ⧗ Running: 8
  ✗ Failed: 0

  Progress: [============                    ]  25%
```

**Check detailed status:**
```bash
bash /path/to/bat-gpu-runner/scripts/utils/check_status.bash
```

### 4. Review Results

**Check completion:**
```bash
ls equil_logs/*.log | wc -l  # Should match number of ligands
```

**View specific log:**
```bash
tail -50 equil_logs/lig-fmm_gpu0.log
```

**Check for errors:**
```bash
grep -l "FAILED\|ERROR" equil_logs/*.log
```

## What the Script Does

### 1. GPU Detection
```bash
# Queries each GPU for free memory
GPU 0: 11020 MB free ✓
GPU 1: 11020 MB free ✓
GPU 2: 500 MB free   ✗ (insufficient)
```

### 2. Job Assignment
```
- Finds ligand: lig-fmm
- Checks GPU 0: 11020 MB free ✓
- Assigns lig-fmm to GPU 0
- Runs: cd equil/lig-fmm && CUDA_VISIBLE_DEVICES=0 bash run-local.bash
```

### 3. Dynamic Scheduling
```
[23:45:00] Starting lig-fmm on GPU 0 (11020 MB free)
[23:45:02] Starting lig-gef on GPU 1 (11020 MB free)
...
[23:50:00] ✓ Completed: lig-fmm (GPU 0)
[23:50:02] Starting lig-afa on GPU 0 (10850 MB free)  ← Reuses freed GPU
```

## Configuration

### Memory Requirements

Edit `scripts/equil/run_equil_all_gpus.bash`:

```bash
REQUIRED_FREE_MEMORY=8000  # Default: 8 GB

# For large systems:
REQUIRED_FREE_MEMORY=10000  # 10 GB

# For small systems:
REQUIRED_FREE_MEMORY=6000   # 6 GB
```

### Number of GPUs

```bash
NUM_GPUS=8  # Use all 8 GPUs

# Or limit to fewer:
NUM_GPUS=4  # Use only 4 GPUs
```

## Output Files

### Log Files

**Location:** `equil_logs/`

**Naming:** `lig-{name}_gpu{id}.log`

**Example:**
```
equil_logs/
├── lig-fmm_gpu0.log
├── lig-gef_gpu1.log
├── lig-afa_gpu2.log
└── ...
```

### Log Contents

Each log contains:
```
=== Job Started: Fri Dec 13 23:45:00 2025 ===
Ligand: lig-fmm
GPU: 0
GPU Free Memory: 11020 MB
Working Directory: /path/to/BAT/equil/lig-fmm

[... pmemd.cuda output ...]

=== Job Finished: Fri Dec 13 23:55:00 2025 ===
Exit Code: 0
```

## Performance

### Typical Timing
- **Small systems** (~20,000 atoms): 10-15 minutes per ligand
- **Medium systems** (~50,000 atoms): 15-25 minutes per ligand
- **Large systems** (~100,000 atoms): 25-40 minutes per ligand

### Example Workflow
```
12 ligands with 8 GPUs:
- First 8 ligands: start immediately
- Last 4 ligands: start as GPUs become free
- Total time: ~20-40 minutes (vs. 4-8 hours sequential)
```

## Troubleshooting

### Jobs Not Starting

**Check GPU memory:**
```bash
nvidia-smi --query-gpu=index,memory.free --format=csv
```

**Expected:** At least one GPU with ≥ 8000 MB free

**If all GPUs have low memory:**
- Wait for existing jobs to finish
- Or reduce `REQUIRED_FREE_MEMORY` (not recommended)

### GPU Out of Memory Errors

**Symptoms:**
```
cudaMalloc Failed out of memory
```

**Solutions:**

1. **Increase memory threshold:**
```bash
REQUIRED_FREE_MEMORY=10000  # Require more free memory
```

2. **Run fewer concurrent jobs:**
```bash
NUM_GPUS=4  # Use only 4 GPUs instead of 8
```

3. **Check system size:**
```bash
# Count atoms in topology
grep "POINTERS" equil/lig-fmm/*.prmtop
```

### Jobs Failing

**Check log:**
```bash
tail -100 equil_logs/lig-fmm_gpu0.log
```

**Common errors:**

| Error | Cause | Solution |
|-------|-------|----------|
| `Cannot open file` | Missing input file | Check `run-local.bash` paths |
| `vlimit exceeded` | Bad coordinates | Check `.rst7` file |
| `SHAKE` failure | Constraint issues | Adjust SHAKE tolerance in `.in` |
| `PMEMD Terminated Abnormally` | Various | Check full log for details |

### Clean Up Stuck Jobs

```bash
# Kill all equilibration jobs
bash /path/to/bat-gpu-runner/scripts/utils/cleanup_jobs.bash
```

## Best Practices

### 1. Test First
```bash
# Test with one ligand
cd equil/lig-fmm
export CUDA_VISIBLE_DEVICES=0
bash run-local.bash

# Check output
ls -l *.rst7 *.out
```

### 2. Monitor Resource Usage
```bash
# Watch GPU memory during run
watch -n 1 nvidia-smi
```

### 3. Backup Important Data
```bash
# Before running
tar -czf equil_backup.tar.gz equil/
```

### 4. Check Disk Space
```bash
# Equilibration can generate large files
df -h .
```

## Advanced Usage

### Rerun Failed Jobs

```bash
# Find failed jobs
bash scripts/utils/check_status.bash | grep FAILED

# Rerun specific ligand manually
cd equil/lig-failed
export CUDA_VISIBLE_DEVICES=0
bash run-local.bash
```

### Run Subset of Ligands

```bash
# Edit script or use temporary directory
mkdir equil_subset
cp -r equil/lig-fmm equil/lig-gef equil_subset/
# Run on subset
# (then copy results back)
```

### Custom GPU Assignment

```bash
# Run on specific GPUs only
NUM_GPUS=4  # Edit in script
# Script will use GPUs 0-3
```

## Next Steps

After equilibration completes:
1. **Verify** all jobs completed successfully
2. **Check** equilibration quality (RMSD, energies)
3. **Proceed** to FEP simulations: See [FEP_SIMULATION.md](FEP_SIMULATION.md)
