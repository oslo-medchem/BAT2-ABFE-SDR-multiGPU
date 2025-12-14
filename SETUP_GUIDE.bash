#!/bin/bash
# Quick Setup Guide for SDR Equilibration Runner

cat << 'EOF'
================================================================================
                SDR Equilibration Runner - Quick Setup
================================================================================

IMPORTANT: Run all scripts from the PARENT directory that contains 'equil/'

Your directory structure should look like:

    your-project-directory/          ← Run scripts from HERE
    ├── equil/
    │   ├── lig-afa/
    │   │   └── run-local.bash
    │   ├── lig-gef/
    │   │   └── run-local.bash
    │   ├── lig-dac/
    │   │   └── run-local.bash
    │   └── ...
    ├── run_equil_all_gpus.bash
    ├── monitor_equil.bash
    ├── manage_equil.bash
    └── validate_equil_setup.bash

================================================================================

STEP-BY-STEP SETUP:

1. Place all scripts in the parent directory of 'equil/':
   
   cd /path/to/your/project   # Directory that CONTAINS equil/
   
   # Copy scripts here (not inside equil/)

2. Make sure each ligand folder has run-local.bash:
   
   ls equil/*/run-local.bash   # Should list all scripts

3. Make scripts executable:
   
   chmod +x *.bash

4. Validate your setup:
   
   bash validate_equil_setup.bash

5. If validation passes, start the jobs:
   
   bash run_equil_all_gpus.bash

6. Monitor in another terminal:
   
   bash monitor_equil.bash

================================================================================

COMMON MISTAKES:

✗ Running scripts from INSIDE equil/ directory
  → Move UP one level: cd ..

✗ Placing scripts inside a lig-* folder
  → Move scripts to parent of equil/

✗ Not having run-local.bash in each lig-* folder
  → Copy run-local.bash to all ligand folders

================================================================================

QUICK CHECKS:

# Are you in the right directory?
pwd                    # Should show path to parent of equil/
ls -d equil/lig-*      # Should list your ligand folders

# Do ligands have run scripts?
ls equil/*/run-local.bash

# Are GPUs available?
nvidia-smi

================================================================================

If you see "No lig-* folders found" error:
→ You're probably in the wrong directory
→ Run: pwd
→ Then: cd to the directory that contains equil/

================================================================================
EOF
