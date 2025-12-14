# QUICK REFERENCE - GPU-Only Runner

## What This Script Does

✅ Checks GPU **free memory** before submitting jobs
✅ Waits for GPU with ≥ 8000 MB free memory
✅ Runs ONE job per GPU
✅ NO CPU fallback - GPU only
✅ Dynamic submission based on real availability

## Run

```bash
bash run_equil_all_gpus.bash
```

## Monitor

```bash
bash monitor_equil.bash
```

## Configuration

Edit `run_equil_all_gpus.bash`:

```bash
REQUIRED_FREE_MEMORY=8000      # Change if needed (in MB)
NUM_GPUS=8                     # Number of GPUs to use
```

## How It Works

```
1. Script checks GPU 0: Has 11020 MB free ✓
2. Submits lig-afa to GPU 0
3. GPU 0 now has 4500 MB free (busy with job)
4. Script checks GPU 1: Has 11020 MB free ✓
5. Submits lig-afp to GPU 1
6. Continues until all GPUs have jobs
7. When GPU 0 finishes, checks memory again
8. If ≥ 8000 MB free, submits next job to GPU 0
9. Otherwise, waits and rechecks every 3 seconds
```

## What You'll See

```
[23:45:00] Starting lig-afa on GPU 0 (11020 MB free)

GPU Memory Status:
  GPU 0:  4500 MB free - BUSY: lig-afa
  GPU 1: 11020 MB free - AVAILABLE
  GPU 2: 11020 MB free - AVAILABLE
  ...

[23:45:02] Starting lig-afp on GPU 1 (11020 MB free)
```

## If All GPUs Busy

```
[23:45:10] All GPUs busy or insufficient memory, waiting...
[23:45:10] Waiting for GPU with 8000MB+ free memory...

GPU Memory Status:
  GPU 0:  4500 MB free - BUSY: lig-afa
  GPU 1:  4300 MB free - BUSY: lig-afp
  GPU 2:  4100 MB free - BUSY: lig-dac
  ...

[Script waits, checks every 3 seconds]

[23:46:15] ✓ Completed: lig-afa (GPU 0)
[23:46:16] Starting lig-lap on GPU 0 (10850 MB free)
```

## Files

- **run_equil_all_gpus.bash** - Main runner
- **monitor_equil.bash** - Progress monitor
- **check_status.bash** - Detailed status
- **cleanup_jobs.bash** - Kill stuck jobs
- **README.md** - Full documentation

## Troubleshooting

### Still getting OOM?
Increase memory requirement:
```bash
REQUIRED_FREE_MEMORY=10000  # 10 GB instead of 8 GB
```

### Check GPU memory manually:
```bash
nvidia-smi --query-gpu=memory.free --format=csv,noheader
```

### Clean up:
```bash
bash cleanup_jobs.bash
```

## Key Difference from Before

**OLD:** Checked if GPU utilization was low
**NEW:** Checks if GPU has enough **free memory** (≥ 8000 MB)

This prevents submitting jobs to GPUs that don't have enough memory, even if they appear "free"!
