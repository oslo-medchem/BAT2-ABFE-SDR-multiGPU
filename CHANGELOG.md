# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-12-14

### Added
- Initial release of BAT GPU Runner
- Equilibration workflow script with GPU memory checking
- FEP simulation workflow script with automatic window discovery
- Real-time monitoring utility
- Job status checker utility
- Process cleanup utility
- Comprehensive documentation
  - Installation guide
  - Equilibration workflow guide
  - FEP simulation workflow guide
  - Troubleshooting guide
- Example files and directory structure
- MIT License

### Features
- Robust GPU memory checking before job submission
- Dynamic job scheduling based on GPU availability
- One job per GPU to prevent memory conflicts
- Automatic window discovery for FEP simulations
- Support for both REST and SDR methods
- Case-insensitive ligand folder matching
- Comprehensive error logging
- Progress tracking and monitoring

### Performance
- Parallel execution across up to 8 GPUs
- Automatic GPU reallocation when jobs complete
- Efficient memory usage monitoring

## [Unreleased]

### Planned
- Support for CPU fallback when GPU memory insufficient
- Resume capability for interrupted runs
- Email notifications on completion/failure
- Integration with job schedulers (SLURM, PBS)
- Web-based monitoring dashboard
- Automatic analysis pipeline integration

---

## Version History

### Version 1.0.0 (2025-12-14)
First stable release with full equilibration and FEP simulation support.
