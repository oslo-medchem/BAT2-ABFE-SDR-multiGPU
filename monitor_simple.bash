#!/bin/bash

###############################################################################
# BAT GPU Runner - Simple Summary Monitor
# - Shows only summary information (no clearing screen)
# - Updates every 5 minutes
# - Checks actual md-03.out and md-02.out files
# - Easy to follow on screen
###############################################################################

REFRESH_INTERVAL=300  # 5 minutes
EQUIL_DIR="./equil"
FE_DIR="./fe"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

###############################################################################
# Check if equilibration is complete (md-03.out with TIMINGS)
###############################################################################
is_equil_complete() {
    local lig_dir="$1"
    if [ -f "$lig_dir/md-03.out" ]; then
        if grep -q "TIMINGS" "$lig_dir/md-03.out" 2>/dev/null && \
           grep -q "Total wall time:" "$lig_dir/md-03.out" 2>/dev/null; then
            return 0
        fi
    fi
    return 1
}

###############################################################################
# Check if FEP window is complete (md-02.out with TIMINGS)
###############################################################################
is_fep_complete() {
    local window_dir="$1"
    if [ -f "$window_dir/md-02.out" ]; then
        if grep -q "TIMINGS" "$window_dir/md-02.out" 2>/dev/null && \
           grep -q "Total wall time:" "$window_dir/md-02.out" 2>/dev/null; then
            return 0
        fi
    fi
    return 1
}

###############################################################################
# Show simple status
###############################################################################

echo ""
echo "=========================================================================="
echo "BAT GPU Monitor - Starting..."
echo "Checking actual output files: md-03.out (equil) and md-02.out (FEP)"
echo "Updates every 5 minutes"
echo "=========================================================================="
echo ""

while true; do
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo "[$timestamp] STATUS UPDATE"
    echo "-------------------------------------------"
    
    # GPU summary
    if command -v nvidia-smi &> /dev/null; then
        busy_gpus=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits | awk '$1 > 50' | wc -l)
        total_gpus=$(nvidia-smi --query-gpu=index --format=csv,noheader | wc -l)
        echo "GPUs: $busy_gpus/$total_gpus busy"
    fi
    
    # Process count
    pmemd_count=$(pgrep -fc "pmemd" 2>/dev/null || echo 0)
    echo "pmemd processes: $pmemd_count"
    
    # Equilibration
    if [ -d "$EQUIL_DIR" ]; then
        shopt -s nullglob
        lig_folders=("$EQUIL_DIR"/lig-*)
        shopt -u nullglob
        
        total_lig=${#lig_folders[@]}
        completed_lig=0
        
        for lig_dir in "${lig_folders[@]}"; do
            is_equil_complete "$lig_dir" && ((completed_lig++))
        done
        
        if [ $total_lig -gt 0 ]; then
            pct=$((completed_lig * 100 / total_lig))
            echo -e "Equilibration: ${GREEN}$completed_lig${NC}/$total_lig complete (${pct}%)"
        fi
    fi
    
    # FEP
    if [ -d "$FE_DIR" ]; then
        total_win=0
        completed_win=0
        
        shopt -s nullglob
        lig_folders=("$FE_DIR"/lig-*)
        shopt -u nullglob
        
        for lig_dir in "${lig_folders[@]}"; do
            for subdir in rest REST sdr SDR; do
                [ ! -d "$lig_dir/$subdir" ] && continue
                
                shopt -s nullglob
                windows=("$lig_dir/$subdir"/*)
                shopt -u nullglob
                
                for window in "${windows[@]}"; do
                    [ ! -d "$window" ] && continue
                    [[ "$(basename "$window")" == .* ]] && continue
                    
                    ((total_win++))
                    is_fep_complete "$window" && ((completed_win++))
                done
            done
        done
        
        if [ $total_win -gt 0 ]; then
            pct=$((completed_win * 100 / total_win))
            remaining=$((total_win - completed_win))
            echo -e "FEP Windows: ${GREEN}$completed_win${NC}/$total_win complete (${pct}%) | ${YELLOW}$remaining${NC} remaining"
        fi
    fi
    
    echo "-------------------------------------------"
    next_update=$(date -d "+5 minutes" '+%H:%M:%S')
    echo "Next update at: $next_update"
    echo ""
    
    sleep $REFRESH_INTERVAL
done
