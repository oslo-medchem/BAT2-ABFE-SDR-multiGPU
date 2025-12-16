#!/bin/bash

###############################################################################
# BAT GPU Runner - Comprehensive Job Monitor
# Provides detailed statistics for equilibration and FEP simulations
###############################################################################

# Configuration
REFRESH_INTERVAL=3
EQUIL_LOG_DIR="./equil_logs"
FEP_LOG_DIR="./fe_logs"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

###############################################################################
# Function: Draw progress bar
###############################################################################
draw_progress_bar() {
    local current=$1
    local total=$2
    local width=50
    local percentage=0
    
    if [ $total -gt 0 ]; then
        percentage=$((current * 100 / total))
        local filled=$((current * width / total))
        
        printf "  ["
        for ((i=0; i<width; i++)); do
            if [ $i -lt $filled ]; then
                printf "${GREEN}█${NC}"
            else
                printf "░"
            fi
        done
        printf "] ${BOLD}%3d%%${NC} (%d/%d)\n" $percentage $current $total
    else
        printf "  [%-50s] ${BOLD}  0%%${NC} (0/0)\n" ""
    fi
}

###############################################################################
# Function: Format time
###############################################################################
format_time() {
    local seconds=$1
    local hours=$((seconds / 3600))
    local minutes=$(((seconds % 3600) / 60))
    local secs=$((seconds % 60))
    printf "%02d:%02d:%02d" $hours $minutes $secs
}

###############################################################################
# Function: Get GPU status
###############################################################################
get_gpu_status() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}GPU STATUS${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    if command -v nvidia-smi &> /dev/null; then
        nvidia-smi --query-gpu=index,name,utilization.gpu,memory.used,memory.total,temperature.gpu \
                   --format=csv,noheader,nounits 2>/dev/null | \
        while IFS=, read -r idx name util mem_used mem_total temp; do
            # Clean up whitespace
            idx=$(echo $idx | tr -d ' ')
            util=$(echo $util | tr -d ' ')
            mem_used=$(echo $mem_used | tr -d ' ')
            mem_total=$(echo $mem_total | tr -d ' ')
            temp=$(echo $temp | tr -d ' ')
            
            # Color code based on utilization
            if [ "$util" -gt 80 ]; then
                util_color=$GREEN
            elif [ "$util" -gt 30 ]; then
                util_color=$YELLOW
            else
                util_color=$NC
            fi
            
            # Color code based on temperature
            if [ "$temp" -gt 80 ]; then
                temp_color=$RED
            elif [ "$temp" -gt 70 ]; then
                temp_color=$YELLOW
            else
                temp_color=$NC
            fi
            
            printf "  GPU ${BOLD}%s${NC}: %-20s | ${util_color}%3s%%${NC} util | %5s/%5s MB | ${temp_color}%2s°C${NC}\n" \
                   "$idx" "$name" "$util" "$mem_used" "$mem_total" "$temp"
        done
    else
        echo "  nvidia-smi not available"
    fi
    echo ""
}

###############################################################################
# Function: Get process counts
###############################################################################
get_process_counts() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}ACTIVE PROCESSES${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    local bash_jobs=$(pgrep -fc "run-local.bash" 2>/dev/null || echo 0)
    local pmemd_jobs=$(pgrep -fc "pmemd" 2>/dev/null || echo 0)
    
    echo -e "  ${BOLD}run-local.bash:${NC} ${GREEN}$bash_jobs${NC}"
    echo -e "  ${BOLD}pmemd:${NC}          ${GREEN}$pmemd_jobs${NC}"
    echo ""
}

###############################################################################
# Function: Analyze equilibration logs
###############################################################################
analyze_equilibration() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}EQUILIBRATION STATUS${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    if [ ! -d "$EQUIL_LOG_DIR" ]; then
        echo "  No equilibration logs found"
        echo ""
        return
    fi
    
    # Count total expected ligands
    local total_ligands=0
    if [ -d "./equil" ]; then
        shopt -s nullglob nocaseglob
        local lig_folders=(./equil/lig-*)
        shopt -u nullglob nocaseglob
        total_ligands=${#lig_folders[@]}
    fi
    
    # Count logs
    local total_logs=$(ls -1 "$EQUIL_LOG_DIR"/*.log 2>/dev/null | wc -l)
    local completed=0
    local failed=0
    local running=0
    
    if [ $total_logs -gt 0 ]; then
        for log in "$EQUIL_LOG_DIR"/*.log; do
            if grep -q "Exit Code: 0" "$log" 2>/dev/null; then
                ((completed++))
            elif grep -q "Exit Code:" "$log" 2>/dev/null; then
                ((failed++))
            else
                ((running++))
            fi
        done
    fi
    
    local pending=$((total_ligands - total_logs))
    
    echo -e "  ${BOLD}Total Ligands:${NC}      ${CYAN}$total_ligands${NC}"
    echo -e "  ${GREEN}✓${NC} ${BOLD}Completed:${NC}        ${GREEN}$completed${NC}"
    echo -e "  ${YELLOW}⧗${NC} ${BOLD}Running:${NC}          ${YELLOW}$running${NC}"
    echo -e "  ${RED}✗${NC} ${BOLD}Failed:${NC}           ${RED}$failed${NC}"
    echo -e "  ${BLUE}○${NC} ${BOLD}Pending:${NC}          ${BLUE}$pending${NC}"
    echo ""
    
    # Progress bar
    echo -e "  ${BOLD}Progress:${NC}"
    draw_progress_bar $completed $total_ligands
    echo ""
    
    # Time estimates
    if [ -f "$EQUIL_LOG_DIR/start_time.txt" ]; then
        local start_time=$(cat "$EQUIL_LOG_DIR/start_time.txt")
        local current_time=$(date +%s)
        local elapsed=$((current_time - start_time))
        
        if [ $completed -gt 0 ]; then
            local avg_time=$((elapsed / completed))
            local remaining=$((total_ligands - completed))
            local eta=$((remaining * avg_time / 8))  # Assuming 8 parallel jobs
            
            echo -e "  ${BOLD}Elapsed Time:${NC}     $(format_time $elapsed)"
            echo -e "  ${BOLD}Avg per Job:${NC}      $(format_time $avg_time)"
            if [ $remaining -gt 0 ]; then
                echo -e "  ${BOLD}Estimated ETA:${NC}    $(format_time $eta)"
            fi
        else
            echo -e "  ${BOLD}Elapsed Time:${NC}     $(format_time $elapsed)"
        fi
    else
        echo $(date +%s) > "$EQUIL_LOG_DIR/start_time.txt" 2>/dev/null
    fi
    
    echo ""
}

###############################################################################
# Function: Analyze FEP logs
###############################################################################
analyze_fep() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}FEP SIMULATION STATUS${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    if [ ! -d "$FEP_LOG_DIR" ]; then
        echo "  No FEP logs found"
        echo ""
        return
    fi
    
    # Count total expected windows
    local total_windows=0
    if [ -d "./fe" ]; then
        total_windows=$(find ./fe -name "run-local.bash" 2>/dev/null | wc -l)
    fi
    
    # Count logs
    local total_logs=$(ls -1 "$FEP_LOG_DIR"/*.log 2>/dev/null | wc -l)
    local completed=0
    local failed=0
    local running=0
    
    if [ $total_logs -gt 0 ]; then
        for log in "$FEP_LOG_DIR"/*.log; do
            if grep -q "Exit Code: 0" "$log" 2>/dev/null; then
                ((completed++))
            elif grep -q "Exit Code:" "$log" 2>/dev/null; then
                ((failed++))
            else
                ((running++))
            fi
        done
    fi
    
    local pending=$((total_windows - total_logs))
    
    echo -e "  ${BOLD}Total Windows:${NC}      ${CYAN}$total_windows${NC}"
    echo -e "  ${GREEN}✓${NC} ${BOLD}Completed:${NC}        ${GREEN}$completed${NC}"
    echo -e "  ${YELLOW}⧗${NC} ${BOLD}Running:${NC}          ${YELLOW}$running${NC}"
    echo -e "  ${RED}✗${NC} ${BOLD}Failed:${NC}           ${RED}$failed${NC}"
    echo -e "  ${BLUE}○${NC} ${BOLD}Pending:${NC}          ${BLUE}$pending${NC}"
    echo ""
    
    # Progress bar
    echo -e "  ${BOLD}Progress:${NC}"
    draw_progress_bar $completed $total_windows
    echo ""
    
    # Breakdown by method
    local rest_completed=0
    local sdr_completed=0
    
    if [ $total_logs -gt 0 ]; then
        rest_completed=$(grep -l "Exit Code: 0" "$FEP_LOG_DIR"/*_rest_*.log 2>/dev/null | wc -l)
        sdr_completed=$(grep -l "Exit Code: 0" "$FEP_LOG_DIR"/*_sdr_*.log 2>/dev/null | wc -l)
    fi
    
    echo -e "  ${BOLD}Method Breakdown:${NC}"
    echo -e "    REST completed:  ${GREEN}$rest_completed${NC}"
    echo -e "    SDR completed:   ${GREEN}$sdr_completed${NC}"
    echo ""
    
    # Time estimates
    if [ -f "$FEP_LOG_DIR/start_time.txt" ]; then
        local start_time=$(cat "$FEP_LOG_DIR/start_time.txt")
        local current_time=$(date +%s)
        local elapsed=$((current_time - start_time))
        
        if [ $completed -gt 0 ]; then
            local avg_time=$((elapsed / completed))
            local remaining=$((total_windows - completed))
            local eta=$((remaining * avg_time / 8))  # Assuming 8 parallel jobs
            
            echo -e "  ${BOLD}Elapsed Time:${NC}     $(format_time $elapsed)"
            echo -e "  ${BOLD}Avg per Window:${NC}   $(format_time $avg_time)"
            if [ $remaining -gt 0 ]; then
                echo -e "  ${BOLD}Estimated ETA:${NC}    $(format_time $eta)"
            fi
        else
            echo -e "  ${BOLD}Elapsed Time:${NC}     $(format_time $elapsed)"
        fi
    else
        echo $(date +%s) > "$FEP_LOG_DIR/start_time.txt" 2>/dev/null
    fi
    
    echo ""
}

###############################################################################
# Function: Show recent activity
###############################################################################
show_recent_activity() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}RECENT ACTIVITY${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    # Combine recent events from both logs
    {
        if [ -d "$EQUIL_LOG_DIR" ]; then
            grep -h "Starting\|Completed\|FAILED" "$EQUIL_LOG_DIR"/*.log 2>/dev/null | tail -5
        fi
        if [ -d "$FEP_LOG_DIR" ]; then
            grep -h "Starting\|Completed\|FAILED" "$FEP_LOG_DIR"/*.log 2>/dev/null | tail -5
        fi
    } | tail -10 | while read line; do
        if echo "$line" | grep -q "✓ Completed"; then
            echo -e "  ${GREEN}$line${NC}"
        elif echo "$line" | grep -q "✗ FAILED"; then
            echo -e "  ${RED}$line${NC}"
        elif echo "$line" | grep -q "Starting"; then
            echo -e "  ${YELLOW}$line${NC}"
        else
            echo "  $line"
        fi
    done
    
    echo ""
}

###############################################################################
# Function: Show currently running jobs
###############################################################################
show_running_jobs() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}CURRENTLY RUNNING${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    local count=0
    
    # Check equilibration logs
    if [ -d "$EQUIL_LOG_DIR" ]; then
        for log in "$EQUIL_LOG_DIR"/*.log; do
            if [ ! -f "$log" ]; then continue; fi
            
            if ! grep -q "Exit Code:" "$log" 2>/dev/null; then
                local job=$(basename "$log" | sed 's/_gpu[0-9]*\.log//')
                local gpu=$(basename "$log" | grep -o 'gpu[0-9]*' | sed 's/gpu//')
                local last_line=$(tail -1 "$log" 2>/dev/null | cut -c1-50)
                
                if pgrep -f "run-local.bash.*$job" >/dev/null 2>&1; then
                    echo -e "  ${YELLOW}[EQUIL]${NC} $job ${BOLD}(GPU $gpu)${NC}"
                    if [ -n "$last_line" ]; then
                        echo "    └─ $last_line..."
                    fi
                    ((count++))
                fi
            fi
        done
    fi
    
    # Check FEP logs
    if [ -d "$FEP_LOG_DIR" ]; then
        for log in "$FEP_LOG_DIR"/*.log; do
            if [ ! -f "$log" ]; then continue; fi
            
            if ! grep -q "Exit Code:" "$log" 2>/dev/null; then
                local job=$(basename "$log" | sed 's/_gpu[0-9]*\.log//' | sed 's/^fe_//' | tr '_' '/')
                local gpu=$(basename "$log" | grep -o 'gpu[0-9]*' | sed 's/gpu//')
                local last_line=$(tail -1 "$log" 2>/dev/null | cut -c1-45)
                
                if pgrep -f "run-local.bash" >/dev/null 2>&1; then
                    echo -e "  ${YELLOW}[FEP]${NC} $job ${BOLD}(GPU $gpu)${NC}"
                    if [ -n "$last_line" ]; then
                        echo "    └─ $last_line..."
                    fi
                    ((count++))
                fi
            fi
        done
    fi
    
    if [ $count -eq 0 ]; then
        echo "  No jobs currently running"
    fi
    
    echo ""
}

###############################################################################
# Function: Show failure summary
###############################################################################
show_failures() {
    local equil_failed=0
    local fep_failed=0
    
    if [ -d "$EQUIL_LOG_DIR" ]; then
        equil_failed=$(find "$EQUIL_LOG_DIR" -name "*.log" -exec grep -l "Exit Code: [^0]" {} + 2>/dev/null | wc -l)
    fi
    
    if [ -d "$FEP_LOG_DIR" ]; then
        fep_failed=$(find "$FEP_LOG_DIR" -name "*.log" -exec grep -l "Exit Code: [^0]" {} + 2>/dev/null | wc -l)
    fi
    
    local total_failed=$((equil_failed + fep_failed))
    
    if [ $total_failed -gt 0 ]; then
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${BOLD}${RED}FAILURES DETECTED${NC}"
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        
        if [ $equil_failed -gt 0 ]; then
            echo -e "  ${RED}Equilibration failures: $equil_failed${NC}"
            find "$EQUIL_LOG_DIR" -name "*.log" -exec grep -l "Exit Code: [^0]" {} + 2>/dev/null | head -3 | while read log; do
                local job=$(basename "$log" | sed 's/_gpu[0-9]*\.log//')
                echo "    - $job"
            done
            if [ $equil_failed -gt 3 ]; then
                echo "    ... and $((equil_failed - 3)) more"
            fi
        fi
        
        if [ $fep_failed -gt 0 ]; then
            echo -e "  ${RED}FEP failures: $fep_failed${NC}"
            find "$FEP_LOG_DIR" -name "*.log" -exec grep -l "Exit Code: [^0]" {} + 2>/dev/null | head -3 | while read log; do
                local job=$(basename "$log" | sed 's/_gpu[0-9]*\.log//' | sed 's/^fe_//' | tr '_' '/')
                echo "    - $job"
            done
            if [ $fep_failed -gt 3 ]; then
                echo "    ... and $((fep_failed - 3)) more"
            fi
        fi
        
        echo ""
        echo "  Run 'bash check_status.bash' for detailed error analysis"
        echo ""
    fi
}

###############################################################################
# Main monitoring loop
###############################################################################

# Check if any logs exist
if [ ! -d "$EQUIL_LOG_DIR" ] && [ ! -d "$FEP_LOG_DIR" ]; then
    echo "No log directories found. Have you started any jobs?"
    echo ""
    echo "Start equilibration: bash run_equil_all_gpus.bash"
    echo "Start FEP:           bash run_fep_all_gpus.bash"
    exit 0
fi

# Continuous monitoring
while true; do
    clear
    
    # Header
    echo -e "${BOLD}${CYAN}"
    echo "╔════════════════════════════════════════════════════════════════════╗"
    echo "║        BAT GPU RUNNER - COMPREHENSIVE JOB MONITOR                 ║"
    echo "╚════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo -e "${BOLD}Timestamp:${NC} $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""
    
    # Display sections
    get_gpu_status
    get_process_counts
    
    # Show equilibration if logs exist
    if [ -d "$EQUIL_LOG_DIR" ] && [ "$(ls -A $EQUIL_LOG_DIR 2>/dev/null)" ]; then
        analyze_equilibration
    fi
    
    # Show FEP if logs exist
    if [ -d "$FEP_LOG_DIR" ] && [ "$(ls -A $FEP_LOG_DIR 2>/dev/null)" ]; then
        analyze_fep
    fi
    
    show_running_jobs
    show_failures
    show_recent_activity
    
    # Footer
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}Refreshing every ${REFRESH_INTERVAL} seconds...${NC} Press ${BOLD}Ctrl+C${NC} to exit"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    sleep $REFRESH_INTERVAL
done
