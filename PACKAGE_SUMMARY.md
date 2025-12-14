# BAT GPU Runner - Complete Package Summary

## Overview

Professional GitHub package for GPU-accelerated AMBER Binding Affinity Tool (BAT) workflows with robust memory management and dynamic job scheduling.

## Package Contents

```
bat-gpu-runner/
├── README.md                       # Main documentation
├── LICENSE                         # MIT License
├── CHANGELOG.md                    # Version history
│
├── scripts/                        # Executable scripts
│   ├── equil/
│   │   └── run_equil_all_gpus.bash     # Equilibration runner
│   ├── fep/
│   │   └── run_fep_all_gpus.bash       # FEP simulation runner
│   └── utils/
│       ├── monitor.bash                # Real-time monitor
│       ├── check_status.bash           # Status checker
│       └── cleanup_jobs.bash           # Process cleanup
│
├── docs/                           # Documentation
│   ├── INSTALLATION.md             # Installation guide
│   ├── EQUILIBRATION.md            # Equilibration workflow
│   ├── FEP_SIMULATION.md           # FEP workflow
│   └── TROUBLESHOOTING.md          # Problem solving
│
└── examples/                       # Example files
    ├── directory_structure.txt     # Expected structure
    └── run-local.bash              # Example execution script
```

## Key Features

### 1. Equilibration Workflow
- **Script**: `scripts/equil/run_equil_all_gpus.bash`
- **Purpose**: Run SDR equilibration for all ligands
- **Input**: `BAT/equil/lig-*/`
- **Output**: `BAT/equil_logs/*.log`
- **Performance**: 12 ligands in ~20-40 minutes with 8 GPUs

### 2. FEP Simulation Workflow
- **Script**: `scripts/fep/run_fep_all_gpus.bash`
- **Purpose**: Run FEP across all windows (REST & SDR)
- **Input**: `BAT/fe/lig-*/rest/` and `BAT/fe/lig-*/sdr/`
- **Output**: `BAT/fe_logs/*.log`
- **Performance**: 528 windows in ~14-16 hours with 8 GPUs

### 3. Robust GPU Management
✅ **Memory Checking** - Verifies GPU has ≥8GB free before submission
✅ **Dynamic Scheduling** - Waits for GPU availability
✅ **One Job Per GPU** - Prevents memory conflicts
✅ **Auto Recovery** - Handles GPU OOM gracefully

### 4. Monitoring & Diagnostics
- **Real-time Monitor** - Live job progress and GPU status
- **Status Checker** - Detailed job analysis
- **Cleanup Utility** - Kill stuck processes

## Quick Start

```bash
# 1. Download package
wget https://github.com/yourusername/bat-gpu-runner/archive/v1.0.0.tar.gz
tar -xzf v1.0.0.tar.gz
cd bat-gpu-runner

# 2. Make executable
chmod +x scripts/**/*.bash

# 3. Run equilibration
cd /path/to/BAT
bash /path/to/bat-gpu-runner/scripts/equil/run_equil_all_gpus.bash

# 4. Run FEP simulations
bash /path/to/bat-gpu-runner/scripts/fep/run_fep_all_gpus.bash

# 5. Monitor (in another terminal)
bash /path/to/bat-gpu-runner/scripts/utils/monitor.bash
```

## Technical Specifications

### Requirements
- **OS**: Linux (Ubuntu 20.04+, CentOS 7+)
- **Shell**: Bash 5.0+
- **GPUs**: NVIDIA with CUDA 11.0+
- **Software**: AMBER 20+, nvidia-smi

### Configuration
```bash
# Edit scripts to adjust:
REQUIRED_FREE_MEMORY=8000  # Minimum GPU memory (MB)
NUM_GPUS=8                 # Number of GPUs to use
```

### Performance Metrics

**Equilibration:**
| System Size | Time/Ligand | 12 Ligands (8 GPUs) |
|-------------|-------------|---------------------|
| Small (~20K atoms) | 10-15 min | ~20 min |
| Medium (~50K atoms) | 15-25 min | ~30 min |
| Large (~100K atoms) | 25-40 min | ~50 min |

**FEP Simulation:**
| System Size | Time/Window | 528 Windows (8 GPUs) |
|-------------|-------------|----------------------|
| Small | 5-10 min | ~6-8 hours |
| Medium | 10-15 min | ~10-12 hours |
| Large | 15-25 min | ~14-18 hours |

## Documentation

### Main Documentation
- **README.md** - Project overview and quick start
- **INSTALLATION.md** - Detailed installation instructions
- **EQUILIBRATION.md** - Complete equilibration workflow
- **FEP_SIMULATION.md** - Complete FEP workflow
- **TROUBLESHOOTING.md** - Problem solving guide

### Examples
- **directory_structure.txt** - Expected BAT structure
- **run-local.bash** - Sample execution script

## Usage Examples

### Equilibration
```bash
cd /path/to/BAT

# Run all equilibrations
bash /path/to/bat-gpu-runner/scripts/equil/run_equil_all_gpus.bash

# Output appears in equil_logs/
ls equil_logs/
# lig-fmm_gpu0.log
# lig-gef_gpu1.log
# ...
```

### FEP Simulations
```bash
cd /path/to/BAT

# Run all FEP windows
bash /path/to/bat-gpu-runner/scripts/fep/run_fep_all_gpus.bash

# Output appears in fe_logs/
ls fe_logs/
# fe_lig-fmm_rest_c00_gpu0.log
# fe_lig-fmm_rest_c01_gpu1.log
# ...
```

### Monitoring
```bash
# Real-time monitor
bash /path/to/bat-gpu-runner/scripts/utils/monitor.bash

# Check status
bash /path/to/bat-gpu-runner/scripts/utils/check_status.bash

# Clean up stuck jobs
bash /path/to/bat-gpu-runner/scripts/utils/cleanup_jobs.bash
```

## How It Works

### GPU Selection Algorithm
1. Query nvidia-smi for GPU free memory
2. Check if GPU has ≥ REQUIRED_FREE_MEMORY (default 8000 MB)
3. Assign job to first available GPU
4. If all GPUs busy, wait and recheck every 3 seconds
5. When job completes, GPU becomes available for next job

### Window Discovery (FEP)
1. Scan all `fe/lig-*/` directories
2. Check for `rest/` and `sdr/` subdirectories
3. Find all folders containing `run-local.bash`
4. Process windows dynamically as GPUs become available

## Troubleshooting

### Common Issues

**GPU Out of Memory:**
```bash
# Increase memory threshold
REQUIRED_FREE_MEMORY=10000  # 10 GB instead of 8 GB
```

**Jobs Not Starting:**
```bash
# Check GPU memory
nvidia-smi --query-gpu=memory.free --format=csv
```

**PMEMD Crashes:**
```bash
# Check log files
tail -50 equil_logs/lig-fmm_gpu0.log
```

See full [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) guide.

## Advanced Features

### Custom Configuration
- Adjustable memory thresholds
- Flexible GPU assignment
- Configurable number of concurrent jobs

### Robust Error Handling
- Comprehensive logging
- Exit code tracking
- Error message capture

### Scalability
- Supports 1-8+ GPUs
- Handles 100s of jobs
- Automatic load balancing

## Support & Contributing

### Getting Help
- **Documentation**: See `/docs` directory
- **GitHub Issues**: Report bugs and request features
- **GitHub Discussions**: Ask questions and share tips

### Contributing
Contributions welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Test your changes
4. Submit a pull request

## License

MIT License - See [LICENSE](LICENSE) file

## Citation

```bibtex
@software{bat_gpu_runner,
  title = {BAT GPU Runner: GPU Job Management for AMBER BAT Workflows},
  year = {2025},
  url = {https://github.com/yourusername/bat-gpu-runner}
}
```

## Version Information

- **Current Version**: 1.0.0
- **Release Date**: 2025-12-14
- **Compatibility**: AMBER 20+, CUDA 11.0+

## Files Summary

### Scripts (5 files)
1. `run_equil_all_gpus.bash` - Equilibration runner (9.9 KB)
2. `run_fep_all_gpus.bash` - FEP runner (10.5 KB)
3. `monitor.bash` - Real-time monitor (3.2 KB)
4. `check_status.bash` - Status checker (3.9 KB)
5. `cleanup_jobs.bash` - Cleanup utility (1.8 KB)

### Documentation (6 files)
1. `README.md` - Main documentation (7.1 KB)
2. `INSTALLATION.md` - Installation guide (5.8 KB)
3. `EQUILIBRATION.md` - Equilibration workflow (8.2 KB)
4. `FEP_SIMULATION.md` - FEP workflow (9.1 KB)
5. `TROUBLESHOOTING.md` - Troubleshooting (10.3 KB)
6. `CHANGELOG.md` - Version history (1.5 KB)

### Examples (2 files)
1. `directory_structure.txt` - Structure guide (6.1 KB)
2. `run-local.bash` - Example script (2.8 KB)

### Other (1 file)
1. `LICENSE` - MIT License (1.1 KB)

**Total**: 14 files, ~70 KB uncompressed, ~21 KB compressed

## Package Distribution

- **GitHub Repository**: Clone/fork from GitHub
- **Release Tarball**: `bat-gpu-runner-v1.0.0.tar.gz` (21 KB)
- **Direct Download**: Available from GitHub Releases

## Next Steps

After installation:
1. Read [INSTALLATION.md](docs/INSTALLATION.md)
2. Prepare your BAT directory structure
3. Test with a single ligand
4. Run full workflow
5. Monitor and analyze results

## Acknowledgments

- AMBER molecular dynamics software
- Binding Affinity Tool (BAT.py)
- NVIDIA CUDA toolkit
- Open source community
