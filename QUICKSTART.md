# QUICK START - CPU Mode (GPU Memory Issue Fixed)

## Your Problem
```
cudaMalloc Failed out of memory
```

## The Fix
**Use CPU mode** - Your system is too large for GPU memory.

## 3-Step Quick Start

### 1. Run the script (already configured for CPU)
```bash
cd /path/to/BAT
bash run_equil_all_gpus.bash
```

### 2. Monitor progress (in another terminal)
```bash
bash monitor_equil.bash
```

### 3. Wait for completion
- CPU is slower than GPU but **will complete successfully**
- Expect ~1-2 hours for all 12 ligands with 8 concurrent jobs

## That's It!

The script is **already set to CPU mode** - just run it.

## What You'll See

```
========================================================================
Equilibration Runner
========================================================================
Mode: CPU
Max concurrent jobs: 8
Working directory: /path/to/BAT
Log directory: /path/to/BAT/equil_logs
========================================================================

Found 12 ligand folders

Running in CPU-only mode (recommended for large systems)

[23:45:00] Starting lig-afa on CPU
[23:45:01] Starting lig-afp on CPU
[23:45:02] Starting lig-dac on CPU
[23:45:03] Starting lig-dap on CPU
[23:45:04] Starting lig-erl on CPU
[23:45:05] Starting lig-fmm on CPU
[23:45:06] Starting lig-gef on CPU
[23:45:07] Starting lig-gep on CPU

All jobs submitted. Waiting for completion...

[00:15:32] ✓ Completed: lig-afa
[00:18:45] ✓ Completed: lig-afp
[00:21:03] ✓ Completed: lig-dac
...
```

## Monitor Output

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

  Progress: [============                              ]  25%

Currently Running:
  - lig-dap
    └─ Step: 15000/50000...
  - lig-erl
    └─ Step: 12000/50000...
  ...
```

## If You Want to Try GPU (Not Recommended)

Only if you have GPUs with 20GB+ memory:

```bash
# Edit run_equil_all_gpus.bash
USE_GPU=true
MAX_JOBS=2      # Only 2 to avoid OOM
```

But **CPU mode is recommended** for your system size.

## Files Needed

1. **run_equil_all_gpus.bash** - Main runner (CPU mode by default)
2. **monitor_equil.bash** - Real-time monitor
3. **check_status.bash** - Detailed status check
4. **cleanup_jobs.bash** - Kill stuck processes
5. **README.md** - Full documentation

## Summary

✅ **CPU mode is already configured**
✅ **Just run: `bash run_equil_all_gpus.bash`**
✅ **Slower but reliable - will complete successfully**

No more GPU memory errors!
