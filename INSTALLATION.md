# Installation Guide

## Prerequisites

### System Requirements
- **Operating System**: Linux (Ubuntu 20.04+, CentOS 7+, or similar)
- **Shell**: Bash 5.0 or later
- **GPUs**: NVIDIA GPUs with CUDA support
- **Memory**: Sufficient system RAM (128GB+ recommended)

### Software Requirements
- **AMBER** (version 20 or later) with GPU support
- **CUDA Toolkit** 11.0 or later
- **nvidia-smi** (usually comes with NVIDIA drivers)
- **BAT.py** - Binding Affinity Tool

### Check Prerequisites

```bash
# Check Bash version
bash --version

# Check CUDA
nvcc --version

# Check nvidia-smi
nvidia-smi

# Check AMBER
which pmemd.cuda

# Check number of GPUs
nvidia-smi --list-gpus
```

## Installation

### Method 1: Git Clone (Recommended)

```bash
# Clone the repository
git clone https://github.com/yourusername/bat-gpu-runner.git

# Navigate to directory
cd bat-gpu-runner

# Make scripts executable
chmod +x scripts/**/*.bash

# Verify installation
ls -l scripts/equil/
ls -l scripts/fep/
ls -l scripts/utils/
```

### Method 2: Download ZIP

```bash
# Download from GitHub
wget https://github.com/yourusername/bat-gpu-runner/archive/main.zip

# Extract
unzip main.zip
cd bat-gpu-runner-main

# Make scripts executable
chmod +x scripts/**/*.bash
```

### Method 3: Copy Scripts Directly

```bash
# Create directory structure
mkdir -p ~/bat-gpu-runner/{equil,fep,utils}

# Copy scripts (adjust paths as needed)
cp run_equil_all_gpus.bash ~/bat-gpu-runner/equil/
cp run_fep_all_gpus.bash ~/bat-gpu-runner/fep/
cp monitor.bash check_status.bash cleanup_jobs.bash ~/bat-gpu-runner/utils/

# Make executable
chmod +x ~/bat-gpu-runner/**/*.bash
```

## Configuration

### 1. Set GPU Memory Threshold

Edit the scripts to adjust memory requirements:

**For Equilibration:**
```bash
# Edit scripts/equil/run_equil_all_gpus.bash
REQUIRED_FREE_MEMORY=8000  # 8 GB (default)

# For large systems, increase to:
REQUIRED_FREE_MEMORY=10000  # 10 GB
```

**For FEP Simulations:**
```bash
# Edit scripts/fep/run_fep_all_gpus.bash
REQUIRED_FREE_MEMORY=8000  # 8 GB (default)
```

### 2. Set Number of GPUs

```bash
# Both scripts
NUM_GPUS=8  # Adjust based on your system
```

To find your GPU count:
```bash
nvidia-smi --list-gpus | wc -l
```

### 3. Optional: Add to PATH

```bash
# Add to ~/.bashrc
export BAT_GPU_RUNNER=/path/to/bat-gpu-runner
export PATH=$BAT_GPU_RUNNER/scripts/equil:$BAT_GPU_RUNNER/scripts/fep:$BAT_GPU_RUNNER/scripts/utils:$PATH

# Reload
source ~/.bashrc

# Now you can run from anywhere
run_equil_all_gpus.bash
run_fep_all_gpus.bash
```

## Verify Installation

### Test GPU Access

```bash
# Check GPU status
nvidia-smi

# Expected output:
# +-----------------------------------------------------------------------------+
# | NVIDIA-SMI 510.47.03    Driver Version: 510.47.03    CUDA Version: 11.6     |
# |-------------------------------+----------------------+----------------------+
# | GPU  Name        Persistence-M| Bus-Id        Disp.A | Volatile Uncorr. ECC |
# | Fan  Temp  Perf  Pwr:Usage/Cap|         Memory-Usage | GPU-Util  Compute M. |
# |===============================+======================+======================|
# |   0  NVIDIA GPU      Off  | 00000000:01:00.0 Off |                    0 |
# ...
```

### Test Scripts

```bash
# Test that scripts are executable
ls -l scripts/equil/run_equil_all_gpus.bash
# Should show: -rwxr-xr-x

# Test help/version (if implemented)
bash scripts/equil/run_equil_all_gpus.bash --help
```

## Directory Setup

Create the BAT directory structure:

```bash
# Create main BAT directory
mkdir -p ~/projects/BAT

# Create subdirectories
mkdir -p ~/projects/BAT/equil
mkdir -p ~/projects/BAT/fe
```

Your structure should look like:
```
~/projects/BAT/
├── equil/
│   ├── lig-fmm/
│   ├── lig-gef/
│   └── ...
└── fe/
    ├── lig-fmm/
    │   ├── rest/
    │   └── sdr/
    └── ...
```

## Environment Setup

### AMBER Environment

Ensure AMBER is properly loaded:

```bash
# Add to ~/.bashrc (adjust path)
source /path/to/amber/amber.sh

# Or if using modules
module load amber/20
```

### CUDA Environment

```bash
# Add to ~/.bashrc (adjust path)
export CUDA_HOME=/usr/local/cuda
export PATH=$CUDA_HOME/bin:$PATH
export LD_LIBRARY_PATH=$CUDA_HOME/lib64:$LD_LIBRARY_PATH
```

## Troubleshooting Installation

### nvidia-smi not found

```bash
# Install NVIDIA drivers
sudo ubuntu-drivers autoinstall
# or
sudo apt install nvidia-driver-510

# Reboot
sudo reboot
```

### Permission denied when running scripts

```bash
# Make sure scripts are executable
chmod +x scripts/**/*.bash

# Check permissions
ls -l scripts/equil/run_equil_all_gpus.bash
```

### Bash version too old

```bash
# Check version
bash --version

# Update bash (Ubuntu/Debian)
sudo apt update
sudo apt install bash

# Update bash (CentOS/RHEL)
sudo yum update bash
```

### AMBER not found

```bash
# Check if AMBER is installed
which pmemd.cuda

# If not found, install AMBER or load module
module load amber
# or
source /path/to/amber/amber.sh
```

## Next Steps

After installation:

1. **Read Documentation**: See [EQUILIBRATION.md](EQUILIBRATION.md) and [FEP_SIMULATION.md](FEP_SIMULATION.md)
2. **Prepare Input Files**: Ensure your BAT structure is set up correctly
3. **Test Run**: Start with a single ligand to verify everything works
4. **Full Run**: Execute full workflow

## Uninstallation

```bash
# Remove directory
rm -rf /path/to/bat-gpu-runner

# Remove from PATH (if added to ~/.bashrc)
# Edit ~/.bashrc and remove the BAT_GPU_RUNNER lines

# Reload
source ~/.bashrc
```

## Support

If you encounter issues:
1. Check [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
2. Review log files in `equil_logs/` or `fe_logs/`
3. Open an issue on GitHub
