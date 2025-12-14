# BAT GPU Runner - Complete Delivery

## What You've Received

### 1. Complete GitHub Package
**File**: `bat-gpu-runner-v1.0.0.tar.gz` (21 KB)

This is a professional, production-ready GitHub repository containing:
- Complete documentation
- All scripts organized in proper structure
- Examples and guides
- MIT License

### 2. Standalone Scripts
**For immediate use without unpacking:**

- `run_equil_all_gpus.bash` - Equilibration runner
- `run_fep_all_gpus.bash` - FEP simulation runner

### 3. Full Documentation
**In the `github-package/` directory:**

- README.md - Project overview
- docs/INSTALLATION.md - Installation guide
- docs/EQUILIBRATION.md - Equilibration workflow
- docs/FEP_SIMULATION.md - FEP workflow
- docs/TROUBLESHOOTING.md - Problem solving
- PACKAGE_SUMMARY.md - Complete summary

## Quick Start (Standalone Scripts)

### For Equilibration

```bash
# Navigate to your BAT directory
cd /path/to/BAT

# Run equilibration (adjust path to script)
bash /path/to/run_equil_all_gpus.bash
```

### For FEP Simulations

```bash
# Navigate to your BAT directory
cd /path/to/BAT

# Run FEP simulations (adjust path to script)
bash /path/to/run_fep_all_gpus.bash
```

## Full Package Installation

### Option 1: Extract Tarball

```bash
# Extract
tar -xzf bat-gpu-runner-v1.0.0.tar.gz
cd github-package

# Make scripts executable
chmod +x scripts/**/*.bash

# Use from BAT directory
cd /path/to/BAT
bash /path/to/github-package/scripts/equil/run_equil_all_gpus.bash
bash /path/to/github-package/scripts/fep/run_fep_all_gpus.bash
```

### Option 2: Use Unpacked Directory

The `github-package/` directory is already unpacked and ready to use:

```bash
cd github-package

# Make scripts executable
chmod +x scripts/**/*.bash

# Use from BAT directory
cd /path/to/BAT
bash /path/to/github-package/scripts/equil/run_equil_all_gpus.bash
```

## What Each Script Does

### Equilibration Runner (`run_equil_all_gpus.bash`)

**Purpose**: Runs equilibration for all ligands in `equil/lig-*/`

**Features**:
- Checks GPU free memory before submission
- Waits for GPU with ≥8GB free
- Runs one job per GPU
- Logs to `equil_logs/`

**Usage**:
```bash
cd /path/to/BAT
bash /path/to/run_equil_all_gpus.bash
```

**Configuration**:
```bash
# Edit script to change:
REQUIRED_FREE_MEMORY=8000  # Minimum free memory (MB)
NUM_GPUS=8                 # Number of GPUs to use
```

### FEP Simulation Runner (`run_fep_all_gpus.bash`)

**Purpose**: Runs FEP simulations across all windows

**Features**:
- Automatically discovers windows in REST and SDR folders
- Checks GPU memory before each job
- Dynamic job scheduling
- Logs to `fe_logs/`

**Usage**:
```bash
cd /path/to/BAT
bash /path/to/run_fep_all_gpus.bash
```

**Configuration**:
```bash
# Edit script to change:
REQUIRED_FREE_MEMORY=8000  # Minimum free memory (MB)
NUM_GPUS=8                 # Number of GPUs to use
```

## Directory Structure Expected

Your BAT directory should look like:

```
BAT/
├── equil/
│   ├── lig-fmm/
│   │   └── run-local.bash
│   ├── lig-gef/
│   │   └── run-local.bash
│   └── ...
├── fe/
│   ├── lig-fmm/
│   │   ├── rest/
│   │   │   ├── c00/
│   │   │   │   └── run-local.bash
│   │   │   └── ...
│   │   └── sdr/
│   │       ├── e00/
│   │       │   └── run-local.bash
│   │       └── ...
│   └── ...
├── equil_logs/    # Created by script
└── fe_logs/       # Created by script
```

See `github-package/examples/directory_structure.txt` for details.

## Monitoring

Both scripts provide console output showing:
- Which GPU is running which job
- GPU free memory at job start
- Completion/failure notifications

**Example output**:
```
[23:45:00] Starting lig-fmm on GPU 0 (11020 MB free)
[23:45:02] Starting lig-gef on GPU 1 (11020 MB free)
...
[00:15:32] ✓ Completed: lig-fmm (GPU 0)
[00:18:45] ✗ FAILED: lig-gef (GPU 1, exit: 1)
```

## Common Issues

### GPU Out of Memory

**Error**: `cudaMalloc Failed out of memory`

**Solution**: Increase memory threshold in script:
```bash
REQUIRED_FREE_MEMORY=10000  # 10 GB instead of 8 GB
```

### Jobs Not Starting

**Check GPU memory**:
```bash
nvidia-smi --query-gpu=memory.free --format=csv
```

Ensure at least one GPU has ≥8000 MB free.

### Script Can't Find Directories

**Make sure you're in the BAT directory**:
```bash
pwd  # Should show: /path/to/BAT
ls equil/  # Should show: lig-* folders
ls fe/     # Should show: lig-* folders
```

## Full Documentation

For comprehensive information, see the GitHub package:

```bash
cd github-package

# Read main documentation
cat README.md

# Installation guide
cat docs/INSTALLATION.md

# Equilibration workflow
cat docs/EQUILIBRATION.md

# FEP workflow
cat docs/FEP_SIMULATION.md

# Troubleshooting
cat docs/TROUBLESHOOTING.md

# Complete summary
cat PACKAGE_SUMMARY.md
```

## GitHub Repository Structure

The complete package is organized as:

```
github-package/
├── README.md                    # Main documentation
├── LICENSE                      # MIT License
├── CHANGELOG.md                 # Version history
├── PACKAGE_SUMMARY.md           # This summary
│
├── scripts/
│   ├── equil/
│   │   └── run_equil_all_gpus.bash
│   ├── fep/
│   │   └── run_fep_all_gpus.bash
│   └── utils/
│       ├── monitor.bash
│       ├── check_status.bash
│       └── cleanup_jobs.bash
│
├── docs/
│   ├── INSTALLATION.md
│   ├── EQUILIBRATION.md
│   ├── FEP_SIMULATION.md
│   └── TROUBLESHOOTING.md
│
└── examples/
    ├── directory_structure.txt
    └── run-local.bash
```

## Support

### Documentation
- Start with: `github-package/README.md`
- Installation: `github-package/docs/INSTALLATION.md`
- Workflows: `github-package/docs/EQUILIBRATION.md` and `FEP_SIMULATION.md`
- Problems: `github-package/docs/TROUBLESHOOTING.md`

### GitHub (when you publish)
- Report issues
- Request features
- Ask questions in Discussions

## Summary

You have everything needed for:

✅ **Equilibration workflow** - GPU-accelerated, memory-safe
✅ **FEP simulation workflow** - Automatic window discovery
✅ **Comprehensive documentation** - Installation to troubleshooting
✅ **Production-ready package** - Professional GitHub structure
✅ **MIT Licensed** - Free to use and modify

**Total delivery**: 14 files, complete documentation, ready to deploy!

## Next Steps

1. **Test with one ligand**:
   ```bash
   cd /path/to/BAT/equil/lig-test
   export CUDA_VISIBLE_DEVICES=0
   bash run-local.bash
   ```

2. **Run full equilibration**:
   ```bash
   cd /path/to/BAT
   bash /path/to/run_equil_all_gpus.bash
   ```

3. **Run FEP simulations**:
   ```bash
   bash /path/to/run_fep_all_gpus.bash
   ```

4. **Monitor and analyze results**

## Files Included

1. **bat-gpu-runner-v1.0.0.tar.gz** - Complete package (21 KB)
2. **github-package/** - Unpacked directory structure
3. **run_equil_all_gpus.bash** - Standalone equilibration script
4. **run_fep_all_gpus.bash** - Standalone FEP script
5. **DELIVERY_README.md** - This file

Ready to use immediately!
