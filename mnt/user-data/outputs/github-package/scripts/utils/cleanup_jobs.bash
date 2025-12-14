#!/bin/bash

###############################################################################
# Cleanup Script - Kill Running/Zombie Jobs
###############################################################################

echo "========================================================================"
echo "Equilibration Job Cleanup"
echo "========================================================================"
echo ""

# Find and kill run-local.bash processes
echo "Looking for run-local.bash processes..."
pids=$(pgrep -f "run-local.bash" | tr '\n' ' ')

if [ -z "$pids" ]; then
    echo "No run-local.bash processes found"
else
    echo "Found PIDs: $pids"
    echo ""
    read -p "Kill these processes? (yes/no): " confirm
    
    if [ "$confirm" = "yes" ]; then
        for pid in $pids; do
            echo "Killing PID $pid"
            kill -9 $pid 2>/dev/null
        done
        echo "Done"
    else
        echo "Cancelled"
        exit 0
    fi
fi

echo ""

# Find and kill PMEMD processes
echo "Looking for PMEMD processes..."
pmemd_pids=$(pgrep -f "pmemd" | tr '\n' ' ')

if [ -z "$pmemd_pids" ]; then
    echo "No PMEMD processes found"
else
    echo "Found PIDs: $pmemd_pids"
    echo ""
    read -p "Kill these processes? (yes/no): " confirm
    
    if [ "$confirm" = "yes" ]; then
        for pid in $pmemd_pids; do
            echo "Killing PID $pid"
            kill -9 $pid 2>/dev/null
        done
        echo "Done"
    else
        echo "Cancelled"
        exit 0
    fi
fi

echo ""
echo "========================================================================"
echo "Cleanup complete"
echo "========================================================================"
echo ""
echo "You can now restart with:"
echo "  bash run_equil_all_gpus.bash"
