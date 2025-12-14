# TROUBLESHOOTING: PMEMD Crashes & Zombie Processes

## Current Problem

Your monitor shows:
- ZOMBIE processes (dead processes not cleaned up)
- PMEMD crashes: "PMEMD Terminated Abnormally!"
- Same PIDs appearing multiple times (monitor bug)

## Immediate Steps

### 1. Check What's Actually Happening
```bash
bash check_status.bash
```

This shows:
- Which jobs completed
- Which jobs crashed
- Specific PMEMD error messages
- Recent log activity

### 2. Clean Up Zombie Processes
```bash
bash cleanup_jobs.bash
```

This kills:
- All run-local.bash processes
- All PMEMD processes
- Allows fresh restart

### 3. View Detailed Errors
```bash
# Pick a failed ligand and check its log
tail -50 equil_logs/lig-afa_job0.log
```

## Common PMEMD Crash Causes

### 1. GPU Out of Memory (Most Likely)
**Symptom:** `cudaMalloc Failed out of memory`

**Solution:** Script already handles this - it retries on CPU

**If still failing:**
```bash
# Edit run_equil_all_gpus.bash
MAX_CONCURRENT=2      # Run only 2 at once
# or
USE_GPU=false         # Force CPU-only
```

### 2. Input File Errors
**Symptom:** PMEMD crashes immediately or errors about coordinates/restraints

**Check:**
```bash
# Go into a failed ligand folder
cd equil/lig-afa

# Check if input files exist
ls -lh *.in *.rst7 *.prmtop

# Check for NaN or extreme values in coordinates
grep -i "nan\|inf\|9999" *.rst7
```

**Common issues:**
- Missing restraint masks
- Incorrect residue names
- Bad initial coordinates
- Incompatible parameter files

### 3. AMBER/PMEMD Installation Issues
**Check PMEMD:**
```bash
which pmemd.cuda
pmemd.cuda -h
```

**If not found or errors:** AMBER may not be properly installed/loaded

### 4. File Path Issues
**Check run-local.bash:**
```bash
cd equil/lig-afa
cat run-local.bash
```

Make sure paths are correct and files exist.

## Diagnosing Specific Errors

### Error: "STOP PMEMD Terminated Abnormally"

**Check the log file for context:**
```bash
grep -B 20 "STOP PMEMD" equil_logs/lig-afa_job0.log
```

Common patterns:
- `vlimit exceeded` - Bad coordinates, system exploding
- `shake` - SHAKE algorithm failure (bond constraints)
- `out of memory` - GPU OOM
- `Cannot open file` - Missing input file

### Error: Multiple Same PIDs

This is a monitor display bug - not a real problem. The actual jobs may be fine.

**Check real process status:**
```bash
ps aux | grep run-local.bash
ps aux | grep pmemd
```

## Solutions by Error Type

### If GPU OOM everywhere:
```bash
# Force all to CPU
USE_GPU=false
MAX_CONCURRENT=8
```

### If restraint/coordinate errors:
You may need to regenerate input files. Check if:
- Restraint masks match your topology
- Ligand residue names are correct
- Coordinates are reasonable

### If random crashes:
```bash
# Run one ligand manually to see full error
cd equil/lig-afa
bash run-local.bash
# Watch for specific error messages
```

## Restart After Fixing

```bash
# 1. Clean up
bash cleanup_jobs.bash

# 2. Fix configuration if needed
# Edit run_equil_all_gpus.bash

# 3. Restart
bash run_equil_all_gpus.bash

# 4. Monitor
bash monitor_equil.bash
# or
bash check_status.bash
```

## If Everything Fails

Try running ONE ligand manually:
```bash
cd equil/lig-afa
export CUDA_VISIBLE_DEVICES=0
bash run-local.bash 2>&1 | tee manual_test.log
```

This shows exact errors without backgrounding.

## Getting Help

Provide:
1. Output from `check_status.bash`
2. Full log from one failed job: `cat equil_logs/lig-afa_job0.log`
3. Contents of `run-local.bash` from that ligand folder
4. Error messages from manual run
