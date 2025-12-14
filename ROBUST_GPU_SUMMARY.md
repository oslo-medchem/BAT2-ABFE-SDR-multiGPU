# ROBUST GPU RUNNER - What Changed

## Your Request
> "Checking GPU memory and availability is not working properly. Make robust check of GPU availability, and run only one GPU job at a time."

## Solution

### ✅ Robust GPU Availability Check

**OLD:** Counted background jobs - unreliable
**NEW:** Uses `nvidia-smi` to check actual GPU state

```bash
is_gpu_free() {
    # Query GPU utilization and memory
    nvidia-smi -i $gpu_id --query-gpu=utilization.gpu,memory.used
    
    # GPU is FREE if:
    # - Utilization < 10%
    # - Memory usage < 500 MB
}
```

### ✅ One Job Per GPU

**OLD:** Tried to run multiple jobs, caused memory issues
**NEW:** Exactly ONE job per GPU at any time

```bash
# Script tracks which GPU has which job
GPU_JOBS[0] = PID_12345  # GPU 0 busy
GPU_JOBS[1] = PID_12346  # GPU 1 busy
GPU_JOBS[2] = empty      # GPU 2 free
```

### ✅ Automatic Waiting

**OLD:** Started jobs even if no GPU available
**NEW:** Waits for GPU to become free

```bash
wait_for_gpu() {
    # Checks every 5 seconds
    # Returns when any GPU is free
}
```

## How It Works Now

```
1. Script starts
2. Finds first free GPU (e.g., GPU 0)
3. Starts lig-afa on GPU 0
4. Finds next free GPU (e.g., GPU 1)
5. Starts lig-afp on GPU 1
6. Continues until all 8 GPUs have jobs
7. When GPU 0 finishes, assigns next ligand to GPU 0
8. Continues until all ligands processed
```

## Key Features

### Real GPU Status Checking
```bash
# The script actually queries nvidia-smi:
nvidia-smi -i 0 --query-gpu=utilization.gpu,memory.used

# Example output: "5%, 234 MiB"
# If util < 10% AND mem < 500 MB → GPU is FREE
```

### Job Tracking
```bash
# Associative array tracks assignments:
GPU_JOBS[0] = 12345  # PID of job on GPU 0
GPU_JOBS[1] = 12346  # PID of job on GPU 1
...

# When PID finishes, GPU becomes available again
```

### Clean Status Display
```
Current GPU Assignments:
  GPU 0: BUSY (PID 12345)
  GPU 1: BUSY (PID 12346)
  GPU 2: FREE
  GPU 3: FREE
  GPU 4: BUSY (PID 12347)
  GPU 5: FREE
  GPU 6: FREE
  GPU 7: FREE
```

## What This Fixes

✅ **No more GPU OOM** - One job per GPU prevents overload
✅ **No more zombies** - Proper process tracking and cleanup
✅ **Accurate status** - Real nvidia-smi data, not guesses
✅ **Reliable execution** - Jobs run when GPU is actually free

## Usage

```bash
# Simple - just run it
bash run_equil_all_gpus.bash

# Monitor in another terminal
bash monitor_equil.bash

# Check detailed status
bash check_status.bash

# Clean up if needed
bash cleanup_jobs.bash
```

## Example Output

```
[23:45:00] Starting lig-afa on GPU 0

Current GPU Assignments:
  GPU 0: BUSY (PID 12345)
  GPU 1: FREE
  GPU 2: FREE
  ...

[23:45:02] Starting lig-afp on GPU 1

Current GPU Assignments:
  GPU 0: BUSY (PID 12345)
  GPU 1: BUSY (PID 12346)
  GPU 2: FREE
  ...

[23:50:00] ✓ Completed: lig-afa (GPU 0)
[23:50:02] Starting lig-dac on GPU 0

Current GPU Assignments:
  GPU 0: BUSY (PID 12350)  ← New job on freed GPU
  GPU 1: BUSY (PID 12346)
  GPU 2: FREE
  ...
```

## Files You Need

1. **run_equil_all_gpus.bash** - Main runner (UPDATED)
2. **monitor_equil.bash** - Simple monitor (UPDATED)
3. **check_status.bash** - Detailed diagnostics (NEW)
4. **cleanup_jobs.bash** - Kill stuck processes (NEW)
5. **README.md** - Usage instructions (UPDATED)
6. **TROUBLESHOOTING.md** - Problem solving guide (NEW)

All scripts are ready to use - just download and run!
