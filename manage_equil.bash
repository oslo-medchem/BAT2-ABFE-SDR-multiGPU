#!/bin/bash

#=============================================================================
# Equilibration Job Management Utility
# Provides utilities for managing equilibration runs
#=============================================================================

LOG_DIR="./equil_logs"
CHECKPOINT_FILE="./equil_progress.txt"

# Ensure we're in the right directory (one that contains equil/)
if [ ! -d "./equil" ]; then
    echo -e "${RED}Error: Must run from directory containing 'equil/' folder${NC}"
    exit 1
fi

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

#=============================================================================
# Function: Show usage
#=============================================================================
show_usage() {
    cat << EOF
Equilibration Job Management Utility

Usage: $0 <command> [options]

Commands:
  status              Show current status of all jobs
  reset               Reset checkpoint (restart all jobs)
  reset-failed        Reset only failed jobs
  clean               Clean up log files
  list-completed      List all completed ligands
  list-failed         List all failed ligands
  list-pending        List pending ligands
  retry <ligand>      Retry a specific failed ligand
  help                Show this help message

Examples:
  $0 status
  $0 reset-failed
  $0 retry lig-FMM
  $0 clean

EOF
}

#=============================================================================
# Function: Show status
#=============================================================================
show_status() {
    echo -e "${BLUE}Equilibration Job Status${NC}"
    echo "========================================================================="
    
    # Count ligands (case-insensitive)
    shopt -s nullglob nocaseglob
    lig_folders=(./equil/lig-*)
    shopt -u nullglob nocaseglob
    total=${#lig_folders[@]}
    
    completed=$(grep -c "^COMPLETED:" "$CHECKPOINT_FILE" 2>/dev/null || echo 0)
    failed=$(wc -l < "$LOG_DIR/failed_jobs.txt" 2>/dev/null || echo 0)
    
    # Count active jobs
    active=0
    if [ -f "$LOG_DIR/active_jobs.txt" ]; then
        while IFS=: read -r gpu ligand pid; do
            if ps -p "${pid##*:}" > /dev/null 2>&1; then
                ((active++))
            fi
        done < "$LOG_DIR/active_jobs.txt"
    fi
    
    pending=$((total - completed - failed - active))
    
    echo "Total ligands:    $total"
    echo -e "${GREEN}Completed:        $completed${NC}"
    echo -e "${YELLOW}Active:           $active${NC}"
    echo -e "${RED}Failed:           $failed${NC}"
    echo "Pending:          $pending"
    echo "========================================================================="
    
    if [ $active -gt 0 ]; then
        echo ""
        echo -e "${YELLOW}Currently running:${NC}"
        while IFS=: read -r gpu ligand pid; do
            if ps -p "${pid##*:}" > /dev/null 2>&1; then
                echo "  $gpu: $ligand (PID: ${pid##*:})"
            fi
        done < "$LOG_DIR/active_jobs.txt"
    fi
}

#=============================================================================
# Function: Reset checkpoint
#=============================================================================
reset_checkpoint() {
    echo -e "${YELLOW}This will reset all progress and restart from scratch.${NC}"
    read -p "Are you sure? (yes/no): " confirm
    
    if [ "$confirm" = "yes" ]; then
        > "$CHECKPOINT_FILE"
        echo -e "${GREEN}Checkpoint reset. All jobs will be rerun.${NC}"
    else
        echo "Cancelled."
    fi
}

#=============================================================================
# Function: Reset failed jobs
#=============================================================================
reset_failed() {
    if [ ! -f "$LOG_DIR/failed_jobs.txt" ] || [ ! -s "$LOG_DIR/failed_jobs.txt" ]; then
        echo "No failed jobs to reset."
        return
    fi
    
    failed_count=$(wc -l < "$LOG_DIR/failed_jobs.txt")
    echo -e "${YELLOW}This will reset $failed_count failed jobs for retry.${NC}"
    read -p "Continue? (yes/no): " confirm
    
    if [ "$confirm" = "yes" ]; then
        # Remove failed jobs from checkpoint
        while IFS=: read -r status ligand rest; do
            if [ "$status" = "FAILED" ]; then
                sed -i "/^COMPLETED:$ligand$/d" "$CHECKPOINT_FILE" 2>/dev/null
            fi
        done < "$LOG_DIR/failed_jobs.txt"
        
        # Archive failed jobs log
        mv "$LOG_DIR/failed_jobs.txt" "$LOG_DIR/failed_jobs_$(date +%Y%m%d_%H%M%S).txt"
        
        echo -e "${GREEN}Failed jobs reset. They will be retried on next run.${NC}"
    else
        echo "Cancelled."
    fi
}

#=============================================================================
# Function: Clean logs
#=============================================================================
clean_logs() {
    echo -e "${YELLOW}This will remove all log files but keep checkpoint data.${NC}"
    read -p "Continue? (yes/no): " confirm
    
    if [ "$confirm" = "yes" ]; then
        rm -f "$LOG_DIR"/*.log "$LOG_DIR"/*.err
        echo -e "${GREEN}Log files cleaned.${NC}"
    else
        echo "Cancelled."
    fi
}

#=============================================================================
# Function: List completed ligands
#=============================================================================
list_completed() {
    echo -e "${GREEN}Completed Ligands:${NC}"
    if [ -f "$CHECKPOINT_FILE" ]; then
        grep "^COMPLETED:" "$CHECKPOINT_FILE" | cut -d: -f2 | sort
        echo ""
        echo "Total: $(grep -c "^COMPLETED:" "$CHECKPOINT_FILE")"
    else
        echo "None"
    fi
}

#=============================================================================
# Function: List failed ligands
#=============================================================================
list_failed() {
    echo -e "${RED}Failed Ligands:${NC}"
    if [ -f "$LOG_DIR/failed_jobs.txt" ] && [ -s "$LOG_DIR/failed_jobs.txt" ]; then
        while IFS=: read -r status ligand gpu error; do
            echo "  $ligand ($gpu) - $error"
        done < "$LOG_DIR/failed_jobs.txt"
        echo ""
        echo "Total: $(wc -l < "$LOG_DIR/failed_jobs.txt")"
    else
        echo "None"
    fi
}

#=============================================================================
# Function: List pending ligands
#=============================================================================
list_pending() {
    echo -e "${BLUE}Pending Ligands:${NC}"
    
    # Get all ligands (case-insensitive)
    shopt -s nullglob nocaseglob
    lig_folders=(./equil/lig-*)
    shopt -u nullglob nocaseglob
    
    all_ligands=()
    for dir in "${lig_folders[@]}"; do
        all_ligands+=($(basename "$dir"))
    done
    
    # Sort
    IFS=$'\n' all_ligands=($(sort <<<"${all_ligands[*]}"))
    unset IFS
    
    # Get completed ligands
    if [ -f "$CHECKPOINT_FILE" ]; then
        mapfile -t completed < <(grep "^COMPLETED:" "$CHECKPOINT_FILE" | cut -d: -f2 | sort)
    else
        completed=()
    fi
    
    # Find pending
    pending=()
    for ligand in "${all_ligands[@]}"; do
        if ! printf '%s\n' "${completed[@]}" | grep -q "^${ligand}$"; then
            pending+=("$ligand")
        fi
    done
    
    if [ ${#pending[@]} -gt 0 ]; then
        printf '%s\n' "${pending[@]}"
        echo ""
        echo "Total: ${#pending[@]}"
    else
        echo "None"
    fi
}

#=============================================================================
# Function: Retry specific ligand
#=============================================================================
retry_ligand() {
    local ligand="$1"
    
    if [ -z "$ligand" ]; then
        echo -e "${RED}Error: Please specify a ligand name${NC}"
        echo "Usage: $0 retry <ligand>"
        return 1
    fi
    
    if [ ! -d "./equil/$ligand" ]; then
        echo -e "${RED}Error: Ligand folder ./equil/$ligand not found${NC}"
        return 1
    fi
    
    # Remove from checkpoint
    sed -i "/^COMPLETED:$ligand$/d" "$CHECKPOINT_FILE" 2>/dev/null
    sed -i "/^FAILED:$ligand:/d" "$LOG_DIR/failed_jobs.txt" 2>/dev/null
    
    echo -e "${GREEN}Ligand $ligand reset for retry.${NC}"
    echo "Run the main script to retry this ligand."
}

#=============================================================================
# Main
#=============================================================================

if [ $# -eq 0 ]; then
    show_usage
    exit 1
fi

command="$1"
shift

case "$command" in
    status)
        show_status
        ;;
    reset)
        reset_checkpoint
        ;;
    reset-failed)
        reset_failed
        ;;
    clean)
        clean_logs
        ;;
    list-completed)
        list_completed
        ;;
    list-failed)
        list_failed
        ;;
    list-pending)
        list_pending
        ;;
    retry)
        retry_ligand "$1"
        ;;
    help)
        show_usage
        ;;
    *)
        echo -e "${RED}Unknown command: $command${NC}"
        echo ""
        show_usage
        exit 1
        ;;
esac

exit 0
