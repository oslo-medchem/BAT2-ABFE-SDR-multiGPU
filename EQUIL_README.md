# SDR Equilibration GPU-Parallel Runner

Complete system for running SDR equilibration across all ligands using all available GPUs.

## Quick Start

### 1. Run All Equilibrations
```bash
bash run_equil_all_gpus.bash
```

This will:
- Find all ligand folders in `./equil/lig-*`
- Run `run-local.bash` in each folder
- Distribute jobs across 8 GPUs (one job per GPU)
- Track progress and handle failures
- Resume from checkpoint if interrupted

### 2. Monitor Progress (in another terminal)
```bash
bash monitor_equil.bash
```

This displays:
- Real-time GPU utilization
- Active jobs on each GPU
- Progress summary with completion percentage
- Recent activity
- Estimated time to completion

### 3. Manage Jobs
```bash
# Check status
bash manage_equil.bash status

# List completed ligands
bash manage_equil.bash list-completed

# List failed ligands
bash manage_equil.bash list-failed

# List pending ligands
bash manage_equil.bash list-pending

# Reset only failed jobs for retry
bash manage_equil.bash reset-failed

# Reset everything (start over)
bash manage_equil.bash reset

# Retry specific ligand
bash manage_equil.bash retry lig-FMM

# Clean log files
bash manage_equil.bash clean
```

## Files Generated

### Progress Tracking
- `equil_progress.txt` - Checkpoint file (completed jobs)
- `equil_logs/active_jobs.txt` - Currently running jobs
- `equil_logs/failed_jobs.txt` - Failed jobs with error info
- `equil_logs/skipped_jobs.txt` - Skipped jobs (missing scripts)

### Logs
- `equil_logs/lig-XXX_gpuN.log` - Standard output for each job
- `equil_logs/lig-XXX_gpuN.err` - Error output for each job
- `equil_logs/start_time.txt` - Job start timestamp for ETA calculation

## Features

### Automatic GPU Management
- Dynamically assigns jobs to available GPUs
- Maximum of 8 concurrent jobs (configurable)
- Automatic load balancing

### Checkpoint/Resume
- Tracks completed jobs in `equil_progress.txt`
- Automatically skips completed jobs on restart
- Can resume after interruption or failure

### Error Handling
- Logs all failures with error codes
- Can retry failed jobs selectively
- Validates presence of `run-local.bash` before starting

### Progress Monitoring
- Real-time GPU utilization from nvidia-smi
- Active job tracking with process IDs
- Progress bar and statistics
- ETA calculation based on average job time

## Configuration

Edit `run_equil_all_gpus.bash` to customize:

```bash
EQUIL_BASE="./equil"        # Base directory for ligands
MAX_GPUS=8                   # Maximum number of GPUs to use
LOG_DIR="./equil_logs"       # Log directory
CHECKPOINT_FILE="./equil_progress.txt"  # Checkpoint file
```

## Example Workflow

```bash
# Terminal 1: Start the jobs
bash run_equil_all_gpus.bash

# Terminal 2: Monitor progress
bash monitor_equil.bash

# Terminal 3: Check specific status
bash manage_equil.bash status
bash manage_equil.bash list-failed

# If some jobs failed, retry them
bash manage_equil.bash reset-failed
bash run_equil_all_gpus.bash
```

## Troubleshooting

### Jobs not starting
- Check that `run-local.bash` exists in each `lig-*` folder
- Verify GPU availability with `nvidia-smi`
- Check `equil_logs/skipped_jobs.txt` for reasons

### Jobs failing
- Check individual log files: `equil_logs/lig-XXX_gpuN.err`
- Review failed jobs: `bash manage_equil.bash list-failed`
- Retry specific ligand: `bash manage_equil.bash retry lig-XXX`

### Resume after crash
- Simply re-run `bash run_equil_all_gpus.bash`
- Completed jobs are automatically skipped
- To start fresh: `bash manage_equil.bash reset`

### Monitor not updating
- Ensure `nvidia-smi` is available
- Check that log directory exists
- Verify jobs are actually running: `bash manage_equil.bash status`

## Performance Tips

1. **GPU Memory**: If jobs fail with CUDA OOM, reduce MAX_GPUS
2. **I/O bottleneck**: Ensure fast storage for working directory
3. **Network filesystem**: May need to adjust sleep intervals for NFS
4. **Long jobs**: Monitor script refreshes every 5 seconds (configurable)

## Directory Structure

```
./
├── equil/
│   ├── lig-FMM/
│   │   └── run-local.bash
│   ├── lig-AFA/
│   │   └── run-local.bash
│   └── ...
├── equil_logs/
│   ├── lig-FMM_gpu0.log
│   ├── lig-FMM_gpu0.err
│   ├── active_jobs.txt
│   ├── failed_jobs.txt
│   └── ...
├── equil_progress.txt
├── run_equil_all_gpus.bash
├── monitor_equil.bash
└── manage_equil.bash
```

## Notes

- Each GPU runs one job at a time for optimal memory usage
- Jobs are assigned to GPUs in a round-robin fashion
- Log files are named by ligand and GPU assignment
- Checkpoint file allows safe interruption and resume
- Failed jobs can be retried without affecting completed ones
