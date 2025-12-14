# FIXES APPLIED - SDR Equilibration Runner

## Issues Fixed

### 1. ✅ Log Directory Creation Error
**Problem:** 
```
./equil_logs/lig-afa_gpu0.log: No such file or directory
```

**Root Cause:**
- The subshell runs `cd "$lig_dir"` to enter the ligand directory
- Log paths were relative (`./equil_logs/...`)
- After `cd`, relative paths no longer pointed to the correct location

**Solution:**
- Converted all paths to **absolute paths** at script initialization
- Added explicit initialization of log files to prevent missing file errors

### 2. ✅ Case-Insensitive Ligand Folder Matching
**Problem:**
- Original scripts only found `lig-*` with exact case
- Your folders are lowercase: `lig-afa`, `lig-gef`, etc.

**Solution:**
- Added `shopt -s nocaseglob` to enable case-insensitive pattern matching
- Updated all scripts to use this consistently

### 3. ✅ "Too Many Arguments" Error
**Problem:**
```
line 146: [: too many arguments
```

**Root Cause:**
- Could occur if checkpoint file has malformed entries
- Empty log files before initialization

**Solution:**
- Initialize all tracking files at script start:
  - `equil_logs/active_jobs.txt`
  - `equil_logs/failed_jobs.txt`
  - `equil_logs/skipped_jobs.txt`
  - `equil_progress.txt`

## Changes Made

### run_equil_all_gpus.bash
```bash
# OLD (relative paths)
LOG_DIR="./equil_logs"
CHECKPOINT_FILE="./equil_progress.txt"

# NEW (absolute paths)
EQUIL_BASE=$(cd "$EQUIL_BASE" 2>/dev/null && pwd) || EQUIL_BASE="$(pwd)/equil"
LOG_DIR="$(pwd)/equil_logs"
CHECKPOINT_FILE="$(pwd)/equil_progress.txt"

# Initialize all tracking files
touch "$LOG_DIR/active_jobs.txt"
touch "$LOG_DIR/failed_jobs.txt"
touch "$LOG_DIR/skipped_jobs.txt"
```

### All Scripts
- Added case-insensitive glob matching
- Added directory validation checks
- Better error messages

## Testing

Your setup should now work correctly:

```bash
# From BAT/ directory
bash validate_equil_setup.bash
# Should detect: lig-afa, lig-gef, lig-dac, etc.

bash run_equil_all_gpus.bash
# Should run without path errors
```

## What to Expect

When you run `run_equil_all_gpus.bash`, you should see:

```
=========================================================================
SDR Equilibration GPU-Parallel Runner
=========================================================================
Equilibration base: /full/path/to/BAT/equil
Maximum GPUs: 8
Log directory: /full/path/to/BAT/equil_logs
=========================================================================
Found 12 ligand folders

[2025-12-13 23:45:00] Starting lig-afa on GPU 0
[2025-12-13 23:45:02] Starting lig-afp on GPU 1
[2025-12-13 23:45:04] Starting lig-dac on GPU 2
...
```

All paths will be absolute, preventing the directory change issues.

## Files Created During Execution

```
BAT/
├── equil_logs/
│   ├── lig-afa_gpu0.log
│   ├── lig-afa_gpu0.err
│   ├── lig-afp_gpu1.log
│   ├── lig-afp_gpu1.err
│   ├── active_jobs.txt
│   ├── failed_jobs.txt
│   └── skipped_jobs.txt
├── equil_progress.txt
└── (your scripts)
```
