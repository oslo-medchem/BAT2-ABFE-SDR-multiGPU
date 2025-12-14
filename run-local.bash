#!/bin/bash

###############################################################################
# Example run-local.bash for AMBER/PMEMD GPU simulations
# This file should be customized for your specific simulation
###############################################################################

# Exit on error
set -e

#=============================================================================
# Configuration
#=============================================================================

# Input files (adjust names as needed)
INPUT="md.in"              # AMBER input file
TOPOLOGY="complex.prmtop"  # Topology file
COORDS="complex.rst7"      # Starting coordinates

# Output files
OUTPUT="md.out"            # Output log
RESTART="md.rst7"          # Final coordinates
TRAJECTORY="md.nc"         # Trajectory file

#=============================================================================
# Run PMEMD.CUDA
#=============================================================================

# Basic command
pmemd.cuda -O \
    -i   $INPUT \
    -p   $TOPOLOGY \
    -c   $COORDS \
    -o   $OUTPUT \
    -r   $RESTART \
    -x   $TRAJECTORY

# Exit with PMEMD's exit code
exit $?

###############################################################################
# Alternative Examples
###############################################################################

# Example 1: With restraints
# pmemd.cuda -O \
#     -i   $INPUT \
#     -p   $TOPOLOGY \
#     -c   $COORDS \
#     -ref $COORDS \
#     -o   $OUTPUT \
#     -r   $RESTART \
#     -x   $TRAJECTORY

# Example 2: Multiple stages
# # Minimization
# pmemd.cuda -O -i min.in -p $TOPOLOGY -c $COORDS -o min.out -r min.rst7
# 
# # Heating
# pmemd.cuda -O -i heat.in -p $TOPOLOGY -c min.rst7 -o heat.out -r heat.rst7
# 
# # Equilibration
# pmemd.cuda -O -i equil.in -p $TOPOLOGY -c heat.rst7 -o equil.out -r equil.rst7
# 
# # Production
# pmemd.cuda -O -i md.in -p $TOPOLOGY -c equil.rst7 -o md.out -r md.rst7 -x md.nc

# Example 3: With free energy
# pmemd.cuda -O \
#     -i   $INPUT \
#     -p   $TOPOLOGY \
#     -c   $COORDS \
#     -o   $OUTPUT \
#     -r   $RESTART \
#     -x   $TRAJECTORY \
#     -dmdlout mdout.dat  # TI output

# Example 4: CPU fallback (if GPU fails)
# if ! pmemd.cuda -O -i $INPUT -p $TOPOLOGY -c $COORDS -o $OUTPUT -r $RESTART -x $TRAJECTORY; then
#     echo "GPU failed, trying CPU..."
#     pmemd.MPI -O -i $INPUT -p $TOPOLOGY -c $COORDS -o $OUTPUT -r $RESTART -x $TRAJECTORY
# fi

# Example 5: With logging
# {
#     echo "=== Starting simulation at $(date) ==="
#     echo "GPU: $CUDA_VISIBLE_DEVICES"
#     
#     pmemd.cuda -O \
#         -i   $INPUT \
#         -p   $TOPOLOGY \
#         -c   $COORDS \
#         -o   $OUTPUT \
#         -r   $RESTART \
#         -x   $TRAJECTORY
#     
#     exit_code=$?
#     echo "=== Finished at $(date) with exit code $exit_code ==="
#     exit $exit_code
# } 2>&1 | tee simulation.log
