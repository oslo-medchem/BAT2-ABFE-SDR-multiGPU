# BAT GPU Runner

High-performance GPU job management system for AMBER Binding Affinity Tool (BAT) workflows.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Bash](https://img.shields.io/badge/bash-5.0+-green.svg)](https://www.gnu.org/software/bash/)
[![CUDA](https://img.shields.io/badge/CUDA-11.0+-blue.svg)](https://developer.nvidia.com/cuda-toolkit)

## Features

✅ **Robust GPU Memory Checking** - Monitors actual free GPU memory before job submission  
✅ **Dynamic Job Scheduling** - Automatically waits for GPU availability  
✅ **One Job Per GPU** - Prevents memory conflicts and system overload  
✅ **Parallel Processing** - Utilizes all available GPUs efficiently  
✅ **Progress Monitoring** - Real-time job status and GPU utilization tracking  
✅ **Error Recovery** - Comprehensive logging and cleanup utilities

## Quick Start

```bash
# Clone repository
git clone https://github.com/yourusername/bat-gpu-runner.git
cd bat-gpu-runner

# Make scripts executable
chmod +x scripts/**/*.bash

# Run equilibration
cd /path/to/your/BAT/directory
bash /path/to/bat-gpu-runner/scripts/equil/run_equil_all_gpus.bash

# Run FEP simulations
bash /path/to/bat-gpu-runner/scripts/fep/run_fep_all_gpus.bash
```

## Requirements

- **AMBER** (with GPU support)
- **CUDA** 11.0 or later
- **nvidia-smi** for GPU monitoring
- **Bash** 5.0 or later
- **Linux** operating system

## Workflows Supported

### 1. Equilibration
Runs equilibration simulations for all ligands in `equil/lig-*` directories.

```bash
bash scripts/equil/run_equil_all_gpus.bash
```

### 2. FEP Simulations
Runs free energy perturbation simulations across all windows in `fe/lig-*/rest/` and `fe/lig-*/sdr/` directories.

```bash
bash scripts/fep/run_fep_all_gpus.bash
```

## Directory Structure

Your BAT project should be organized as follows:

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
│   │   │   ├── c01/
│   │   │   ├── ...
│   │   │   ├── m00/
│   │   │   └── ...
│   │   └── sdr/
│   │       ├── e00/
│   │       ├── ...
│   │       ├── v00/
│   │       └── ...
│   └── ...
├── equil_logs/     # Created automatically
└── fe_logs/        # Created automatically
```

## Configuration

### GPU Memory Threshold

Edit the `REQUIRED_FREE_MEMORY` parameter in the scripts:

```bash
REQUIRED_FREE_MEMORY=8000  # Minimum free memory in MB (default: 8 GB)
```

Increase this value if you continue to experience GPU out-of-memory errors.

### Number of GPUs

```bash
NUM_GPUS=8  # Number of GPUs to use (default: 8)
```

## Monitoring

### Real-time Monitor
```bash
bash scripts/utils/monitor.bash
```

Shows:
- GPU utilization and memory
- Active jobs
- Progress statistics
- Recent completions/failures

### Detailed Status
```bash
bash scripts/utils/check_status.bash
```

Shows:
- Individual job status
- Error messages
- PMEMD crash details

### GPU Memory
```bash
watch -n 1 nvidia-smi
```

Live view of GPU status.

## Utilities

### Cleanup Stuck Processes
```bash
bash scripts/utils/cleanup_jobs.bash
```

Kills all `run-local.bash` and PMEMD processes.

## Documentation

- [Installation Guide](docs/INSTALLATION.md)
- [Equilibration Workflow](docs/EQUILIBRATION.md)
- [FEP Simulation Workflow](docs/FEP_SIMULATION.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)

## How It Works

### GPU Selection Algorithm

1. **Check GPU Availability**: Query nvidia-smi for free memory on each GPU
2. **Memory Validation**: Ensure GPU has ≥ REQUIRED_FREE_MEMORY (default 8GB)
3. **Job Assignment**: Assign exactly one job to selected GPU
4. **Wait if Needed**: If all GPUs busy, wait and recheck every 3 seconds
5. **Dynamic Reallocation**: When job completes, GPU becomes available for next job

### Memory Checking

The scripts check **actual free GPU memory**, not just utilization:

```bash
# GPU utilization may be low but memory full
GPU 0: 5% utilization, 500 MB free  ← Not available

# Only submit when sufficient free memory
GPU 1: 10% utilization, 9500 MB free  ← Available
```

This prevents "cudaMalloc Failed out of memory" errors even when GPU appears "free".

## Example Output

```
========================================================================
GPU-Only Equilibration Runner
========================================================================
Working directory: /path/to/BAT
Log directory: /path/to/BAT/equil_logs
Number of GPUs: 8
Required free memory: 8000 MB
========================================================================

Initial GPU Status:
  GPU 0: NVIDIA GPU | Total: 11264 MiB | Free: 11020 MiB
  GPU 1: NVIDIA GPU | Total: 11264 MiB | Free: 11020 MiB
  ...

Found 12 ligand folders

[23:45:00] Starting lig-fmm on GPU 0 (11020 MB free)
[23:45:02] Starting lig-gef on GPU 1 (11020 MB free)
...

[00:15:32] ✓ Completed: lig-fmm (GPU 0)
[00:18:45] ✓ Completed: lig-gef (GPU 1)
```

## Performance

### Equilibration
- **~10-30 minutes per ligand** (GPU-dependent)
- **Parallel execution** across 8 GPUs
- **Example**: 12 ligands in ~20-40 minutes with 8 GPUs

### FEP Simulations
- **~5-15 minutes per window** (GPU-dependent)
- **Example**: 12 ligands × 44 windows = 528 total windows
- With 8 GPUs: ~6-12 hours total

## Troubleshooting

### Still Getting Out of Memory Errors?

Increase the memory requirement:
```bash
REQUIRED_FREE_MEMORY=10000  # 10 GB instead of 8 GB
```

### Jobs Not Starting?

Check GPU memory manually:
```bash
nvidia-smi --query-gpu=index,memory.free --format=csv,noheader
```

Ensure at least one GPU has ≥ 8000 MB free.

### Jobs Failing?

Check log files:
```bash
tail -50 equil_logs/lig-fmm_gpu0.log
# or
tail -50 fe_logs/fe_lig-fmm_rest_c00_gpu0.log
```

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Citation

If you use this software in your research, please cite:

```bibtex
@software{bat_gpu_runner,
  title = {BAT GPU Runner: GPU Job Management for AMBER BAT Workflows},
  author = {Your Name},
  year = {2025},
  url = {https://github.com/yourusername/bat-gpu-runner}
}
```

## Acknowledgments

- AMBER molecular dynamics software
- Binding Affinity Tool (BAT)
- NVIDIA CUDA toolkit

## Support

- **Issues**: [GitHub Issues](https://github.com/yourusername/bat-gpu-runner/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/bat-gpu-runner/discussions)

## Related Projects

- [AMBER](http://ambermd.org/) - Molecular dynamics software
- [BAT.py](https://github.com/GilsonLabUCSD/BAT.py) - Binding Affinity Tool
