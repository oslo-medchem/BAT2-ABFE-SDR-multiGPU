#!/bin/bash

###############################################################################
# Simple Monitor for Equilibration Jobs
###############################################################################

LOG_DIR="./equil_logs"

while true; do
    clear
    echo "========================================================================"
    echo "Equilibration Monitor - $(date '+%H:%M:%S')"
    echo "========================================================================"
    echo ""
    
    # Count processes
    bash_jobs=$(pgrep -fc "run-local.bash" 2>/dev/null || echo 0)
    pmemd_jobs=$(pgrep -fc "pmemd" 2>/dev/null || echo 0)
    
    echo "Running Processes:"
    echo "  run-local.bash: $bash_jobs"
    echo "  pmemd: $pmemd_jobs"
    echo ""
    
    # Job status from logs
    if [ -d "$LOG_DIR" ] && ls "$LOG_DIR"/*.log >/dev/null 2>&1; then
        total=$(ls -1 "$LOG_DIR"/*.log 2>/dev/null | wc -l)
        completed=0
        failed=0
        running=0
        
        for log in "$LOG_DIR"/*.log; do
            if grep -q "Exit code: 0" "$log" 2>/dev/null; then
                ((completed++))
            elif grep -q "Exit code:" "$log" 2>/dev/null; then
                ((failed++))
            else
                ((running++))
            fi
        done
        
        echo "Job Status:"
        echo "  Total started: $total"
        echo "  ✓ Completed: $completed"
        echo "  ⧗ Running: $running"
        echo "  ✗ Failed: $failed"
        echo ""
        
        # Progress bar
        if [ $total -gt 0 ]; then
            percent=$((completed * 100 / total))
            bar_width=50
            filled=$((completed * bar_width / total))
            
            printf "  Progress: ["
            for ((i=0; i<bar_width; i++)); do
                if [ $i -lt $filled ]; then
                    printf "="
                else
                    printf " "
                fi
            done
            printf "] %3d%%\n" $percent
        fi
        echo ""
        
        # Currently running jobs
        if [ $running -gt 0 ]; then
            echo "Currently Running:"
            for log in "$LOG_DIR"/*.log; do
                if ! grep -q "Exit code:" "$log" 2>/dev/null; then
                    ligand=$(basename "$log" .log)
                    # Check if actually running
                    if pgrep -f "run-local.bash.*$ligand" >/dev/null 2>&1; then
                        last_line=$(tail -1 "$log" 2>/dev/null | cut -c1-60)
                        echo "  - $ligand"
                        if [ -n "$last_line" ]; then
                            echo "    └─ $last_line..."
                        fi
                    fi
                fi
            done
            echo ""
        fi
        
        # Recent completions
        echo "Recent Completions:"
        grep -h "Completed\|FAILED" "$LOG_DIR"/*.log 2>/dev/null | tail -5 || echo "  None yet"
        
    else
        echo "No logs yet - jobs not started"
    fi
    
    echo ""
    echo "========================================================================"
    echo "Refreshing every 3 seconds... (Ctrl+C to exit)"
    echo ""
    echo "Commands: check_status.bash | cleanup_jobs.bash"
    
    sleep 3
done
