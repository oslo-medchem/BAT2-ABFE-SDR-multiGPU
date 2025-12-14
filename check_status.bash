#!/bin/bash

###############################################################################
# Diagnostic Script - Check Equilibration Job Status
###############################################################################

LOG_DIR="./equil_logs"

echo "========================================================================"
echo "Equilibration Job Diagnostics"
echo "========================================================================"
echo ""

# Check if log directory exists
if [ ! -d "$LOG_DIR" ]; then
    echo "ERROR: No log directory found at $LOG_DIR"
    exit 1
fi

# Check for log files
log_count=$(ls -1 "$LOG_DIR"/*.log 2>/dev/null | wc -l)
if [ $log_count -eq 0 ]; then
    echo "No log files found yet"
    exit 0
fi

echo "Found $log_count log files"
echo ""

echo "========================================================================"
echo "Job Status Summary"
echo "========================================================================"

# Check each log file
for log in "$LOG_DIR"/*.log; do
    ligand=$(basename "$log" | sed 's/_job[0-9]*\.log//')
    
    # Check for various status indicators
    if grep -q "SUCCESS" "$log" 2>/dev/null; then
        echo "✓ $ligand - COMPLETED"
    elif grep -q "GPU OUT OF MEMORY" "$log" 2>/dev/null; then
        if grep -q "SUCCESS" "$log" 2>/dev/null; then
            echo "⚠ $ligand - COMPLETED (CPU fallback after GPU OOM)"
        else
            echo "⧗ $ligand - RETRYING ON CPU (after GPU OOM)"
        fi
    elif grep -q "PMEMD Terminated Abnormally" "$log" 2>/dev/null; then
        echo "✗ $ligand - PMEMD CRASHED"
    elif grep -q "FAILED" "$log" 2>/dev/null; then
        echo "✗ $ligand - FAILED"
    elif grep -q "cudaMalloc Failed\|out of memory" "$log" 2>/dev/null; then
        echo "✗ $ligand - GPU OUT OF MEMORY"
    else
        # Check if still running
        if pgrep -f "run-local.bash.*$(dirname $log | xargs basename)" > /dev/null; then
            echo "⧗ $ligand - RUNNING"
        else
            echo "? $ligand - UNKNOWN STATUS"
        fi
    fi
done

echo ""
echo "========================================================================"
echo "Error Analysis"
echo "========================================================================"

# Count errors
pmemd_crashes=$(grep -l "PMEMD Terminated Abnormally" "$LOG_DIR"/*.log 2>/dev/null | wc -l)
oom_errors=$(grep -l "cudaMalloc Failed\|out of memory" "$LOG_DIR"/*.log 2>/dev/null | wc -l)
other_failures=$(grep -l "FAILED" "$LOG_DIR"/*.log 2>/dev/null | wc -l)

echo "PMEMD crashes: $pmemd_crashes"
echo "GPU OOM errors: $oom_errors"
echo "Other failures: $other_failures"
echo ""

if [ $pmemd_crashes -gt 0 ]; then
    echo "========================================================================"
    echo "PMEMD Crash Details"
    echo "========================================================================"
    
    for log in "$LOG_DIR"/*.log; do
        if grep -q "PMEMD Terminated Abnormally" "$log"; then
            ligand=$(basename "$log" | sed 's/_job[0-9]*\.log//')
            echo ""
            echo "--- $ligand ---"
            # Show context around the error
            grep -B 5 -A 5 "PMEMD Terminated Abnormally\|ERROR\|FATAL" "$log" | head -20
        fi
    done
fi

echo ""
echo "========================================================================"
echo "Recent Log Activity"
echo "========================================================================"
# Show last few lines from each active/recent log
for log in "$LOG_DIR"/*.log; do
    ligand=$(basename "$log" | sed 's/_job[0-9]*\.log//')
    echo ""
    echo "--- $ligand (last 3 lines) ---"
    tail -3 "$log"
done

echo ""
echo "========================================================================"
echo "To view full log for a specific ligand:"
echo "  tail -f equil_logs/lig-XXX_jobN.log"
echo "========================================================================"
