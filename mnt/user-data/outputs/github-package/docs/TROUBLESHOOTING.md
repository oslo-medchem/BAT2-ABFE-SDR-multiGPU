# Troubleshooting Guide

Common issues and solutions for BAT GPU Runner.

## Table of Contents

- [Installation Issues](#installation-issues)
- [GPU Detection Issues](#gpu-detection-issues)
- [Memory Issues](#memory-issues)
- [Job Execution Issues](#job-execution-issues)
- [Performance Issues](#performance-issues)
- [Error Messages](#error-messages)

## Installation Issues

### nvidia-smi not found

**Symptom:**
```
ERROR: nvidia-smi not found
```

**Solution:**
```bash
# Check if NVIDIA drivers are installed
nvidia-smi

# If not, install drivers
sudo ubuntu-drivers autoinstall
# OR
sudo apt install nvidia-driver-510

# Reboot
sudo reboot

# Verify
nvidia-smi
```

### Scripts not executable

**Symptom:**
```
bash: ./run_equil_all_gpus.bash: Permission denied
```

**Solution:**
```bash
# Make scripts executable
chmod +x scripts/**/*.bash

# Verify
ls -l scripts/equil/run_equil_all_gpus.bash
# Should show: -rwxr-xr-x
```

### AMBER not found

**Symptom:**
```
bash: pmemd.cuda: command not found
```

**Solution:**
```bash
# Load AMBER environment
source /path/to/amber/amber.sh

# OR if using modules
module load amber

# Verify
which pmemd.cuda
```

## GPU Detection Issues

### No GPUs detected

**Symptom:**
```
ERROR: No GPUs found
```

**Check:**
```bash
# List GPUs
nvidia-smi --list-gpus

# Check CUDA
nvcc --version
```

**Solution:**
```bash
# Ensure NVIDIA drivers are loaded
lsmod | grep nvidia

# If not loaded
sudo modprobe nvidia

# Check again
nvidia-smi
```

### Wrong number of GPUs

**Symptom:**
Script detects 4 GPUs but you have 8.

**Solution:**
```bash
# Check actual GPU count
nvidia-smi --list-gpus | wc -l

# Update script
NUM_GPUS=8  # Edit in script
```

### GPU already in use

**Symptom:**
```
GPU 0:   500 MB free - LOW MEMORY
```

**Check who's using it:**
```bash
# Show processes using GPUs
nvidia-smi

# Check specific GPU
fuser -v /dev/nvidia0
```

**Solution:**
```bash
# Wait for jobs to finish
# OR kill if they're yours
pkill -f pmemd.cuda

# OR use different GPUs
NUM_GPUS=4  # Skip busy GPUs
```

## Memory Issues

### GPU Out of Memory (OOM)

**Symptom:**
```
cudaMalloc Failed out of memory
float of length = 1580544
```

**Immediate solution:**
```bash
# Increase memory threshold in script
REQUIRED_FREE_MEMORY=10000  # Was 8000
```

**Long-term solutions:**

1. **Reduce concurrent jobs:**
```bash
NUM_GPUS=4  # Use fewer GPUs
```

2. **Use GPUs with more memory:**
```bash
# Check GPU memory
nvidia-smi --query-gpu=index,name,memory.total --format=csv

# Assign jobs only to high-memory GPUs
```

3. **Reduce system size:**
```bash
# Check atom count
grep "natom" your_topology.prmtop

# Consider smaller simulation box or fewer waters
```

4. **Check for memory leaks:**
```bash
# Monitor memory during run
watch -n 1 nvidia-smi
```

### Insufficient system RAM

**Symptom:**
```
Cannot allocate memory
```

**Check:**
```bash
free -h
```

**Solution:**
```bash
# Reduce concurrent jobs
NUM_GPUS=4

# Close other applications
# Add swap if needed (not recommended for HPC)
```

## Job Execution Issues

### Jobs not starting

**Symptom:**
Script runs but no jobs start.

**Diagnose:**
```bash
# Check if script is finding ligands/windows
bash run_equil_all_gpus.bash 2>&1 | tee startup.log
grep "Found" startup.log

# Check directory structure
ls -R equil/ | head -50
```

**Common causes:**

1. **Wrong directory:**
```bash
# Must run from BAT directory
pwd  # Should show .../BAT
ls equil/  # Should show lig-* folders
```

2. **Missing run-local.bash:**
```bash
# Check for scripts
find equil/ -name "run-local.bash"

# If missing, create them
```

3. **Insufficient GPU memory:**
```bash
# All GPUs may have < 8000 MB free
nvidia-smi --query-gpu=memory.free --format=csv,noheader

# Lower threshold temporarily
REQUIRED_FREE_MEMORY=6000
```

### Jobs failing immediately

**Symptom:**
```
[23:45:00] ✗ FAILED: lig-fmm (GPU 0, exit: 1)
```

**Check log:**
```bash
tail -100 equil_logs/lig-fmm_gpu0.log
```

**Common errors and solutions:**

| Error | Cause | Solution |
|-------|-------|----------|
| `Cannot open file` | Missing input | Check file paths in run-local.bash |
| `SHAKE failure` | Constraint issues | Adjust SHAKE in .in file |
| `vlimit exceeded` | Bad coords | Check .rst7 file quality |
| `Segmentation fault` | Memory/corruption | Try different GPU or CPU |

### Zombie processes

**Symptom:**
```
ps aux | grep pmemd
# Shows many defunct processes
```

**Solution:**
```bash
# Kill all related processes
bash scripts/utils/cleanup_jobs.bash

# Verify cleanup
ps aux | grep pmemd
```

### Jobs hanging

**Symptom:**
Jobs start but never complete.

**Check:**
```bash
# Is process still running?
ps aux | grep pmemd

# Is GPU being used?
nvidia-smi

# Is output file growing?
watch -n 5 'ls -lh equil/lig-fmm/*.out'
```

**Solution:**
```bash
# Set timeout in run-local.bash
timeout 2h pmemd.cuda ...

# Or kill and restart
```

## Performance Issues

### GPUs underutilized

**Symptom:**
```
nvidia-smi
# Shows GPUs at 10-20% utilization
```

**Possible causes:**

1. **CPU bottleneck:**
```bash
htop  # Check CPU usage
```

2. **I/O bottleneck:**
```bash
iostat -x 1
# Check %util column
```

3. **Small system:**
```bash
# Small systems may not saturate GPU
# This is normal
```

### Slow job completion

**Expected times:**
- Equilibration: 10-40 minutes per ligand
- FEP window: 5-25 minutes per window

**If slower:**

1. **Check GPU performance:**
```bash
nvidia-smi dmon -s pucvmet
```

2. **Check system specs:**
```bash
# GPU model
nvidia-smi --query-gpu=name --format=csv

# CUDA version
nvcc --version
```

3. **Check simulation parameters:**
```bash
# Timestep, nsteps in .in files
grep "dt\|nstlim" equil/*/*.in
```

## Error Messages

### PMEMD Terminated Abnormally

**Full error:**
```
STOP PMEMD Terminated Abnormally!
```

**Solutions:**

1. **Check log for specific error:**
```bash
grep -B 20 "Terminated Abnormally" logfile.log
```

2. **Common sub-errors:**

**vlimit exceeded:**
```
# System explosion - bad coordinates
# Solution: Check initial structure
vmd -parm complex.prmtop -rst7 complex.rst7
```

**SHAKE failure:**
```
# Constraints failing
# Solution: Loosen SHAKE tolerance or disable
ntc=1, ntf=1  # in .in file
```

**Precision loss:**
```
# Numerical instability
# Solution: Reduce timestep
dt=0.001  # Instead of 0.002
```

### File I/O Errors

**Cannot open file:**
```bash
# Check file exists
ls -l path/to/file

# Check permissions
ls -l path/to/file

# Check path is correct
cat run-local.bash
```

**Disk full:**
```bash
# Check space
df -h .

# Clean up if needed
rm -rf old_runs/
```

### Network filesystem issues

**NFS or shared storage:**
```bash
# May cause delays or locks
# Solution: Copy to local disk
cp -r fe/ /tmp/fe_local/
cd /tmp/fe_local/
# Run jobs
# Copy results back
```

## Diagnostic Commands

### Quick Health Check

```bash
# GPU status
nvidia-smi

# Running jobs
ps aux | grep -E "pmemd|run-local"

# Recent completions
tail equil_logs/*.log | grep "Exit Code"

# Disk space
df -h .

# System load
uptime
```

### Detailed Diagnostics

```bash
# GPU information
nvidia-smi -q | grep -A 10 "GPU 0"

# CUDA info
nvcc --version
cat /usr/local/cuda/version.txt

# AMBER info
pmemd.cuda -h 2>&1 | head -20

# System info
uname -a
cat /etc/os-release
```

### Log Analysis

```bash
# Find errors
grep -r "ERROR\|FAILED\|FATAL" equil_logs/

# Count completions
grep -c "Exit Code: 0" equil_logs/*.log

# Find slow jobs
for log in equil_logs/*.log; do
    echo "$log: $(grep "Started\|Finished" $log)"
done
```

## Getting Help

### Before asking for help:

1. **Check this guide**
2. **Review error logs**
3. **Test simple case** (one ligand manually)
4. **Collect diagnostic info**

### Information to provide:

```bash
# System info
nvidia-smi --query-gpu=index,name,memory.total --format=csv
nvcc --version
bash --version
pmemd.cuda -h 2>&1 | head -5

# Error details
cat problem.log
ls -R problem_directory/

# What you tried
echo "Describe steps taken"
```

### Support channels:

- GitHub Issues: [link]
- GitHub Discussions: [link]
- Email: [your-email]

## Advanced Debugging

### Enable verbose logging

```bash
# Add to scripts
set -x  # Show all commands

# Run with debug
bash -x run_equil_all_gpus.bash 2>&1 | tee debug.log
```

### Test minimal case

```bash
# Test single GPU job manually
cd equil/lig-test
export CUDA_VISIBLE_DEVICES=0
bash run-local.bash

# Monitor
watch -n 1 nvidia-smi
```

### Check library versions

```bash
# CUDA libraries
ls /usr/local/cuda/lib64/

# AMBER libraries
ldd $(which pmemd.cuda)
```

## Prevention

### Best Practices

1. **Test first:**
   - Run one job manually before batch
   - Verify all input files exist

2. **Monitor:**
   - Use real-time monitor
   - Check logs periodically

3. **Backup:**
   - Keep copies of input files
   - Save intermediate results

4. **Document:**
   - Note what works
   - Record error solutions

5. **Resources:**
   - Check disk space before starting
   - Ensure sufficient GPU memory
   - Avoid oversubscription
