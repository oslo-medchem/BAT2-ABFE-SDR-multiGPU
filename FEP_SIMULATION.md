# FEP Simulation Workflow

Complete guide for running Free Energy Perturbation (FEP) simulations with GPU-based job management.

## Overview

The FEP workflow runs molecular dynamics simulations across all windows in REST and SDR methods for binding free energy calculations. The script automatically discovers and processes all windows for all ligands.

## Directory Structure

```
BAT/
├── fe/
│   ├── lig-fmm/
│   │   ├── rest/
│   │   │   ├── c00/
│   │   │   │   └── run-local.bash
│   │   │   ├── c01/
│   │   │   ├── ...
│   │   │   ├── c09/
│   │   │   ├── m00/
│   │   │   ├── ...
│   │   │   └── m09/
│   │   └── sdr/
│   │       ├── e00/
│   │       ├── ...
│   │       ├── e11/
│   │       ├── v00/
│   │       ├── ...
│   │       └── v11/
│   ├── lig-gef/
│   │   ├── rest/
│   │   └── sdr/
│   └── ...
└── fe_logs/  # Created by script
```

### Window Types

**REST method:**
- `c00-c09`: Coupling windows (electrostatic/van der Waals)
- `m00-m09`: Additional coupling windows

**SDR method:**
- `e00-e11`: Attach/pull windows
- `v00-v11`: Volume correction windows

**Note:** Script automatically detects ALL windows - not limited to these patterns.

## Quick Start

```bash
# Navigate to BAT directory
cd /path/to/BAT

# Run FEP simulations
bash /path/to/bat-gpu-runner/scripts/fep/run_fep_all_gpus.bash

# Monitor progress (in another terminal)
bash /path/to/bat-gpu-runner/scripts/utils/monitor.bash
```

## Step-by-Step Guide

### 1. Prepare Input Files

Ensure each window folder contains:
- `run-local.bash` - Execution script for that window
- Input files specific to that window

**Example window structure:**
```
fe/lig-fmm/rest/c00/
├── run-local.bash
├── md.in
├── *.rst7
└── *.prmtop
```

### 2. Run FEP Simulations

```bash
cd /path/to/BAT
bash /path/to/bat-gpu-runner/scripts/fep/run_fep_all_gpus.bash
```

### 3. Monitor Progress

**Console output:**
```
========================================================================
GPU-Only FEP Simulation Runner
========================================================================
Working directory: /path/to/BAT
FE directory: ./fe
Log directory: /path/to/BAT/fe_logs
Number of GPUs: 8
Required free memory: 8000 MB
========================================================================

Scanning lig-fmm...
  Found: lig-fmm/rest/c00
  Found: lig-fmm/rest/c01
  ...
  Found: lig-fmm/sdr/e00
  ...

Total windows found: 528

[23:45:00] Starting fe/lig-fmm/rest/c00 on GPU 0 (11020 MB free)
[23:45:02] Starting fe/lig-fmm/rest/c01 on GPU 1 (11020 MB free)
...
```

**Real-time monitor:**
```bash
bash scripts/utils/monitor.bash
```

### 4. Review Results

**Check completion:**
```bash
ls fe_logs/*.log | wc -l  # Should match total windows
```

**View specific window:**
```bash
tail -50 fe_logs/fe_lig-fmm_rest_c00_gpu0.log
```

## What the Script Does

### 1. Window Discovery

```
Scanning ligands...
├── lig-fmm/
│   ├── rest/ → Found: c00, c01, ..., c09, m00, ..., m09
│   └── sdr/  → Found: e00, ..., e11, v00, ..., v11
├── lig-gef/
│   ├── rest/ → Found: c00, ..., c09, m00, ..., m09
│   └── sdr/  → Found: e00, ..., e11, v00, ..., v11
...

Total: 528 windows (12 ligands × 44 windows each)
```

### 2. GPU Assignment

```
For each window:
1. Check GPU availability and memory
2. Assign window to first GPU with ≥ 8000 MB free
3. If all GPUs busy, wait and recheck every 3 seconds
4. Run: cd window_dir && CUDA_VISIBLE_DEVICES=X bash run-local.bash
```

### 3. Progress Tracking

```
GPU Status:
  GPU 0:  4500 MB free - BUSY: fe/lig-fmm/rest/c00
  GPU 1:  4300 MB free - BUSY: fe/lig-fmm/rest/c01
  GPU 2: 11020 MB free - AVAILABLE
  ...

[23:50:00] ✓ Completed: fe/lig-fmm/rest/c00 (GPU 0)
[23:50:02] Starting fe/lig-fmm/rest/c10 on GPU 0 (10850 MB free)
```

## Configuration

### Memory Requirements

Edit `scripts/fep/run_fep_all_gpus.bash`:

```bash
REQUIRED_FREE_MEMORY=8000  # Default: 8 GB

# For large systems:
REQUIRED_FREE_MEMORY=10000

# For small systems:
REQUIRED_FREE_MEMORY=6000
```

### Number of GPUs

```bash
NUM_GPUS=8  # Use all 8 GPUs

# Or limit:
NUM_GPUS=4
```

## Output Files

### Log Files

**Location:** `fe_logs/`

**Naming:** `fe_lig-{ligand}_{method}_{window}_gpu{id}.log`

**Examples:**
```
fe_logs/
├── fe_lig-fmm_rest_c00_gpu0.log
├── fe_lig-fmm_rest_c01_gpu1.log
├── fe_lig-fmm_sdr_e00_gpu2.log
├── fe_lig-gef_rest_c00_gpu3.log
└── ...
```

### Log Contents

```
=== Job Started: Fri Dec 13 23:45:00 2025 ===
Window: fe/lig-fmm/rest/c00
GPU: 0
GPU Free Memory: 11020 MB
Working Directory: /path/to/BAT/fe/lig-fmm/rest/c00

[... pmemd.cuda output ...]

=== Job Finished: Fri Dec 13 23:55:00 2025 ===
Exit Code: 0
```

## Performance

### Typical Timing

**Per window:**
- **Small systems**: 5-10 minutes
- **Medium systems**: 10-15 minutes
- **Large systems**: 15-25 minutes

**Full workflow:**
```
Example: 12 ligands × 44 windows = 528 total windows

With 8 GPUs:
- Average: 12 minutes per window
- Total sequential time: 528 × 12 = 6,336 minutes (105 hours)
- With 8 GPUs parallel: 6,336 / 8 = 792 minutes (13 hours)
- Actual time (accounting for startup/cleanup): 14-16 hours
```

### Optimization Tips

1. **Use all available GPUs:**
```bash
NUM_GPUS=8  # Maximum parallelization
```

2. **Start with fast windows:**
- Script processes in order discovered
- Similar windows have similar timing
- Good natural load balancing

3. **Monitor efficiency:**
```bash
watch -n 10 'nvidia-smi --query-gpu=index,utilization.gpu,memory.used --format=csv,noheader'
```

## Troubleshooting

### Jobs Not Starting

**Check window structure:**
```bash
# Verify run-local.bash exists in windows
find fe/ -name "run-local.bash" | head -10
```

**Check GPU memory:**
```bash
nvidia-smi --query-gpu=index,memory.free --format=csv
```

### Incomplete Window Discovery

**Script found fewer windows than expected:**

```bash
# Manual count
find fe/ -name "run-local.bash" | wc -l

# Expected for 12 ligands with standard BAT:
# 12 ligands × (20 REST + 24 SDR) = 528 windows
```

**Solution:**
- Verify all window directories have `run-local.bash`
- Check for typos in directory names
- Ensure `fe/` directory structure is correct

### GPU Out of Memory

**Symptoms:**
```
cudaMalloc Failed out of memory
```

**Solutions:**

1. **Increase memory requirement:**
```bash
REQUIRED_FREE_MEMORY=10000  # 10 GB
```

2. **Reduce concurrent jobs:**
```bash
NUM_GPUS=4  # Fewer GPUs
```

3. **Check window system size:**
```bash
# Large systems need more memory
grep "natom" fe/lig-fmm/rest/c00/*.out
```

### Failed Windows

**Find failed windows:**
```bash
bash scripts/utils/check_status.bash | grep FAILED
```

**Check specific window:**
```bash
tail -100 fe_logs/fe_lig-fmm_rest_c00_gpu0.log
```

**Rerun specific window:**
```bash
cd fe/lig-fmm/rest/c00
export CUDA_VISIBLE_DEVICES=0
bash run-local.bash
```

### Slow Progress

**Monitor GPU usage:**
```bash
nvidia-smi dmon -s mu
# Should show high GPU utilization (>80%)
```

**Check system load:**
```bash
htop  # CPU shouldn't be bottleneck
```

**Verify GPU jobs:**
```bash
ps aux | grep pmemd.cuda
# Should see 8 processes (one per GPU)
```

## Best Practices

### 1. Test Single Window

```bash
# Test one window before full run
cd fe/lig-fmm/rest/c00
export CUDA_VISIBLE_DEVICES=0
bash run-local.bash

# Verify completion
ls -l *.out *.nc
```

### 2. Run in Screen/Tmux

```bash
# Long-running jobs - use screen
screen -S fep_run
cd /path/to/BAT
bash /path/to/bat-gpu-runner/scripts/fep/run_fep_all_gpus.bash

# Detach: Ctrl+A, D
# Reattach: screen -r fep_run
```

### 3. Checkpoint Progress

```bash
# Periodically check status
bash scripts/utils/check_status.bash > fep_status_$(date +%Y%m%d_%H%M).txt
```

### 4. Disk Space

```bash
# FEP generates large trajectory files
df -h .

# Each window: ~100-500 MB
# 528 windows: ~50-250 GB
```

## Advanced Usage

### Selective Reruns

**Rerun only failed windows:**

```bash
# Get list of failed windows
bash scripts/utils/check_status.bash | grep FAILED > failed_windows.txt

# Edit script to process only these windows
# or rerun manually
```

### Custom Window Sets

**Run specific method only:**

```bash
# Modify script or create subset:
mkdir fe_rest_only
for lig in fe/lig-*/; do
    cp -r $lig/rest fe_rest_only/$(basename $lig)/
done

# Run on subset
```

### Parallel REST and SDR

```bash
# Run both in parallel (if enough GPUs)
# Terminal 1: Run REST windows
# Terminal 2: Run SDR windows
# (requires script modification or manual coordination)
```

## Analysis After Completion

### Verify All Windows Completed

```bash
# Count successful completions
grep -l "Exit Code: 0" fe_logs/*.log | wc -l

# Should equal total windows
```

### Extract Free Energies

```bash
# Example: Extract TI values from output
find fe/ -name "*.out" -exec grep "DV/DL" {} + > all_dvdl.txt
```

### Run BAT Analysis

```bash
# Use BAT.py analysis tools
python analyze_bat.py --fe fe/
```

## Next Steps

After FEP simulations complete:
1. **Verify** all windows completed
2. **Extract** free energy data
3. **Analyze** results with BAT.py
4. **Calculate** binding free energies
