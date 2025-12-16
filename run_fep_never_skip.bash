#!/bin/bash

###############################################################################
# GPU-Only FEP Simulation Runner - ULTRA ROBUST VERSION
# - NEVER skips windows due to GPU availability
# - WAITS indefinitely for GPUs to become available
# - Only skips windows that are TRULY completed with strict checking
# - All windows with run-local.bash WILL be executed
###############################################################################

FE_DIR="./fe"
NUM_GPUS=8
REQUIRED_FREE_MEMORY=8000  # Minimum free memory in MB

# Get absolute paths
WORK_DIR=$(pwd)
LOG_DIR="${WORK_DIR}/fe_logs"
DISCOVERY_LOG="${LOG_DIR}/window_discovery.log"
mkdir -p "$LOG_DIR"

# Track GPU assignments
declare -A GPU_JOBS
declare -A GPU_WINDOWS

###############################################################################
# Function: STRICT completion check - only mark as complete if truly finished
###############################################################################
is_window_truly_completed() {
    local window_dir="$1"
    
    # Look for the most common FEP completion files
    # Must check STRICTLY - not just that file exists, but that it's actually complete
    
    # Check for md-02.out specifically (common final stage in BAT)
    if [ -f "$window_dir/md-02.out" ]; then
        # Must have BOTH "TIMINGS" section AND proper ending
        if grep -q "TIMINGS" "$window_dir/md-02.out" 2>/dev/null && \
           grep -q "Total wall time:" "$window_dir/md-02.out" 2>/dev/null; then
            return 0  # Truly complete
        fi
    fi
    
    # Check for other common final output files with strict criteria
    for outfile in prod.out production.out final.out; do
        if [ -f "$window_dir/$outfile" ]; then
            if grep -q "TIMINGS" "$window_dir/$outfile" 2>/dev/null && \
               grep -q "Total wall time:" "$window_dir/$outfile" 2>/dev/null; then
                return 0  # Truly complete
            fi
        fi
    done
    
    # NOT complete - need to run
    return 1
}

###############################################################################
# Function: Get GPU free memory in MB
###############################################################################
get_gpu_free_memory() {
    local gpu_id=$1
    
    if ! command -v nvidia-smi &> /dev/null; then
        echo "ERROR: nvidia-smi not found"
        exit 1
    fi
    
    local mem_info=$(nvidia-smi -i $gpu_id --query-gpu=memory.total,memory.used --format=csv,noheader,nounits 2>/dev/null)
    
    if [ $? -ne 0 ]; then
        echo "0"
        return 1
    fi
    
    local mem_total=$(echo $mem_info | awk -F, '{print $1}' | tr -d ' ')
    local mem_used=$(echo $mem_info | awk -F, '{print $2}' | tr -d ' ')
    local mem_free=$((mem_total - mem_used))
    
    echo $mem_free
}

###############################################################################
# Function: Check if GPU has enough free memory
###############################################################################
has_enough_memory() {
    local gpu_id=$1
    local free_mem=$(get_gpu_free_memory $gpu_id)
    
    if [ $free_mem -ge $REQUIRED_FREE_MEMORY ]; then
        return 0
    else
        return 1
    fi
}

###############################################################################
# Function: Check if GPU is available
###############################################################################
is_gpu_available() {
    local gpu_id=$1
    
    if [ -n "${GPU_JOBS[$gpu_id]}" ]; then
        local pid=${GPU_JOBS[$gpu_id]}
        if kill -0 $pid 2>/dev/null; then
            return 1  # Still running
        else
            # Job finished
            unset GPU_JOBS[$gpu_id]
            unset GPU_WINDOWS[$gpu_id]
            return 0
        fi
    fi
    
    return 0
}

###############################################################################
# Function: Find available GPU with enough memory
###############################################################################
find_available_gpu() {
    for gpu_id in $(seq 0 $((NUM_GPUS - 1))); do
        if is_gpu_available $gpu_id; then
            if has_enough_memory $gpu_id; then
                echo $gpu_id
                return 0
            fi
        fi
    done
    echo -1
    return 1
}

###############################################################################
# Function: Wait INDEFINITELY for GPU - NEVER give up
###############################################################################
wait_for_gpu_forever() {
    local wait_count=0
    local window_desc="$1"
    
    echo "[$(date '+%H:%M:%S')] Waiting for GPU for: $window_desc"
    
    while true; do
        cleanup_finished_jobs
        
        local gpu_id=$(find_available_gpu)
        
        if [ $gpu_id -ge 0 ]; then
            echo "[$(date '+%H:%M:%S')] GPU $gpu_id became available for: $window_desc"
            echo $gpu_id
            return 0
        fi
        
        # Show status every 30 seconds
        if [ $((wait_count % 10)) -eq 0 ]; then
            echo "[$(date '+%H:%M:%S')] Still waiting for GPU (${REQUIRED_FREE_MEMORY}MB+ needed) for: $window_desc"
            show_gpu_status_brief
        fi
        
        ((wait_count++))
        sleep 3
    done
}

###############################################################################
# Function: Clean up finished jobs
###############################################################################
cleanup_finished_jobs() {
    for gpu_id in "${!GPU_JOBS[@]}"; do
        local pid=${GPU_JOBS[$gpu_id]}
        if ! kill -0 $pid 2>/dev/null; then
            unset GPU_JOBS[$gpu_id]
            unset GPU_WINDOWS[$gpu_id]
        fi
    done
}

###############################################################################
# Function: Show brief GPU status
###############################################################################
show_gpu_status_brief() {
    local busy_count=0
    local free_count=0
    local low_mem_count=0
    
    for gpu_id in $(seq 0 $((NUM_GPUS - 1))); do
        if [ -n "${GPU_JOBS[$gpu_id]}" ]; then
            ((busy_count++))
        else
            local free_mem=$(get_gpu_free_memory $gpu_id)
            if [ $free_mem -ge $REQUIRED_FREE_MEMORY ]; then
                ((free_count++))
            else
                ((low_mem_count++))
            fi
        fi
    done
    
    echo "  GPUs: $busy_count busy, $free_count available, $low_mem_count low memory"
}

###############################################################################
# Function: Show detailed GPU status
###############################################################################
show_gpu_status() {
    echo ""
    echo "GPU Status:"
    for gpu_id in $(seq 0 $((NUM_GPUS - 1))); do
        local free_mem=$(get_gpu_free_memory $gpu_id)
        local status=""
        
        if [ -n "${GPU_JOBS[$gpu_id]}" ]; then
            status="BUSY: ${GPU_WINDOWS[$gpu_id]}"
        elif [ $free_mem -ge $REQUIRED_FREE_MEMORY ]; then
            status="AVAILABLE"
        else
            status="LOW MEMORY"
        fi
        
        printf "  GPU %d: %5d MB free - %s\n" $gpu_id $free_mem "$status"
    done
    echo ""
}

###############################################################################
# Function: Run simulation in window
###############################################################################
run_window() {
    local window_dir="$1"
    local gpu_id="$2"
    local window_path=$(realpath --relative-to="$WORK_DIR" "$window_dir")
    local log_name=$(echo "$window_path" | tr '/' '_')
    local log_file="${LOG_DIR}/${log_name}_gpu${gpu_id}.log"
    
    local free_mem=$(get_gpu_free_memory $gpu_id)
    echo "[$(date '+%H:%M:%S')] Starting $window_path on GPU $gpu_id (${free_mem} MB free)"
    
    (
        cd "$window_dir" || exit 1
        export CUDA_VISIBLE_DEVICES=$gpu_id
        
        echo "=== Job Started: $(date) ===" > "$log_file"
        echo "Window: $window_path" >> "$log_file"
        echo "GPU: $gpu_id" >> "$log_file"
        echo "GPU Free Memory: ${free_mem} MB" >> "$log_file"
        echo "Working Directory: $(pwd)" >> "$log_file"
        echo "" >> "$log_file"
        
        bash run-local.bash >> "$log_file" 2>&1
        exit_code=$?
        
        echo "" >> "$log_file"
        echo "=== Job Finished: $(date) ===" >> "$log_file"
        echo "Exit Code: $exit_code" >> "$log_file"
        
        if [ $exit_code -eq 0 ]; then
            echo "[$(date '+%H:%M:%S')] ✓ Completed: $window_path (GPU $gpu_id)"
        else
            echo "[$(date '+%H:%M:%S')] ✗ FAILED: $window_path (GPU $gpu_id, exit: $exit_code)"
        fi
        
        exit $exit_code
    ) &
    
    local job_pid=$!
    GPU_JOBS[$gpu_id]=$job_pid
    GPU_WINDOWS[$gpu_id]=$window_path
}

###############################################################################
# Main execution
###############################################################################

echo "========================================================================"
echo "GPU-Only FEP Simulation Runner - ULTRA ROBUST"
echo "========================================================================"
echo "Working directory: $WORK_DIR"
echo "FE directory: $FE_DIR"
echo "Log directory: $LOG_DIR"
echo "Number of GPUs: $NUM_GPUS"
echo "Required free memory: ${REQUIRED_FREE_MEMORY} MB"
echo ""
echo "GUARANTEE: Every window with run-local.bash WILL be executed"
echo "            Script will WAIT indefinitely for GPU availability"
echo "            NO windows will be skipped due to lack of resources"
echo "========================================================================"
echo ""

# Check nvidia-smi
if ! command -v nvidia-smi &> /dev/null; then
    echo "ERROR: nvidia-smi not found"
    exit 1
fi

# Check if fe directory exists
if [ ! -d "$FE_DIR" ]; then
    echo "ERROR: FE directory not found: $FE_DIR"
    exit 1
fi

# Show initial GPU status
echo "Initial GPU Status:"
nvidia-smi --query-gpu=index,name,memory.total,memory.free \
           --format=csv,noheader | \
while IFS=, read -r idx name total free; do
    printf "  GPU %s: %s | Total: %s | Free: %s\n" "$idx" "$name" "$total" "$free"
done
echo ""

# Find all ligand folders (case-insensitive)
shopt -s nullglob nocaseglob
lig_folders=("$FE_DIR"/lig-*)
shopt -u nullglob nocaseglob

if [ ${#lig_folders[@]} -eq 0 ]; then
    echo "ERROR: No lig-* folders found in $FE_DIR"
    exit 1
fi

echo "Found ${#lig_folders[@]} ligand folders"
echo ""

# Initialize discovery log
echo "=== FEP Window Discovery Log ===" > "$DISCOVERY_LOG"
echo "Timestamp: $(date)" >> "$DISCOVERY_LOG"
echo "Mode: ULTRA ROBUST - No windows skipped due to resources" >> "$DISCOVERY_LOG"
echo "" >> "$DISCOVERY_LOG"

# Collect all windows - with STRICT completion checking
all_windows=()
completed_windows=0
incomplete_windows=0

echo "Scanning for windows..."
echo ""

for lig_dir in "${lig_folders[@]}"; do
    ligand=$(basename "$lig_dir")
    echo "Ligand: $ligand" | tee -a "$DISCOVERY_LOG"
    
    # Check for rest and sdr subdirectories (CASE-INSENSITIVE)
    for subdir_variant in rest REST Rest sdr SDR Sdr; do
        subdir_path="$lig_dir/$subdir_variant"
        
        if [ ! -d "$subdir_path" ]; then
            continue
        fi
        
        # Normalize subdir name for output
        subdir=$(echo "$subdir_variant" | tr '[:upper:]' '[:lower:]')
        
        # Find ALL subdirectories
        shopt -s nullglob dotglob
        windows=("$subdir_path"/*)
        shopt -u nullglob dotglob
        
        for window in "${windows[@]}"; do
            # Skip if not a directory
            if [ ! -d "$window" ]; then
                continue
            fi
            
            # Skip hidden directories
            window_name=$(basename "$window")
            if [[ "$window_name" == .* ]]; then
                continue
            fi
            
            # Check for run-local.bash
            if [ ! -f "$window/run-local.bash" ]; then
                echo "  SKIP: $ligand/$subdir/$window_name (no run-local.bash)" | tee -a "$DISCOVERY_LOG"
                continue
            fi
            
            # STRICT completion check
            if is_window_truly_completed "$window"; then
                echo "  SKIP: $ligand/$subdir/$window_name (verified complete)" | tee -a "$DISCOVERY_LOG"
                ((completed_windows++))
            else
                echo "  WILL RUN: $ligand/$subdir/$window_name" | tee -a "$DISCOVERY_LOG"
                all_windows+=("$window")
                ((incomplete_windows++))
            fi
        done
    done
done

echo "" | tee -a "$DISCOVERY_LOG"
echo "========================================================================"
echo "Discovery Complete"
echo "========================================================================"
echo "Windows to SKIP (already complete): $completed_windows"
echo "Windows to RUN: $incomplete_windows"
echo "========================================================================"
echo ""

# Save complete list to log
echo "" >> "$DISCOVERY_LOG"
echo "=== All Windows to Execute ===" >> "$DISCOVERY_LOG"
for window in "${all_windows[@]}"; do
    echo "$window" >> "$DISCOVERY_LOG"
done

if [ ${#all_windows[@]} -eq 0 ]; then
    echo "All windows are already completed!"
    echo "If this is incorrect, check completion criteria in the script."
    echo "Check the discovery log: $DISCOVERY_LOG"
    exit 0
fi

echo "Starting execution - processing ${#all_windows[@]} windows"
echo ""

# Process each window - GUARANTEED execution
window_num=0
for window_dir in "${all_windows[@]}"; do
    ((window_num++))
    window_path=$(realpath --relative-to="$WORK_DIR" "$window_dir")
    
    echo "========================================================================"
    echo "Window $window_num/${#all_windows[@]}: $window_path"
    echo "========================================================================"
    
    # Find available GPU - if none available, WAIT (don't skip!)
    gpu_id=$(find_available_gpu)
    
    if [ $gpu_id -lt 0 ]; then
        # NO GPU available - WAIT for one
        gpu_id=$(wait_for_gpu_forever "$window_path")
    fi
    
    # Run window on the available GPU
    run_window "$window_dir" "$gpu_id"
    
    # Brief delay before checking next window
    sleep 2
done

echo ""
echo "========================================================================"
echo "All windows submitted. Waiting for final jobs to complete..."
echo "========================================================================"
echo ""

# Show periodic status while jobs run
status_count=0
while true; do
    cleanup_finished_jobs
    
    if [ ${#GPU_JOBS[@]} -eq 0 ]; then
        break
    fi
    
    # Show status every 30 seconds
    if [ $((status_count % 10)) -eq 0 ]; then
        echo "[$(date '+%H:%M:%S')] Waiting for ${#GPU_JOBS[@]} jobs to complete..."
        show_gpu_status
    fi
    
    ((status_count++))
    sleep 3
done

echo ""
echo "========================================================================"
echo "ALL FEP SIMULATIONS COMPLETED"
echo "========================================================================"
echo ""

# Summary
total_windows=${#all_windows[@]}
newly_completed=0
failed=0

for log in "$LOG_DIR"/*.log; do
    if [ "$log" == "$LOG_DIR/*.log" ] || [[ "$log" == *window_discovery* ]]; then
        continue
    fi
    
    if grep -q "Exit Code: 0" "$log" 2>/dev/null; then
        ((newly_completed++))
    else
        # Check if this log is for a window we just ran
        for window in "${all_windows[@]}"; do
            window_path=$(realpath --relative-to="$WORK_DIR" "$window")
            log_name=$(echo "$window_path" | tr '/' '_')
            if [[ "$log" == *"$log_name"* ]]; then
                ((failed++))
                break
            fi
        done
    fi
done

echo "Execution Summary:"
echo "  Windows attempted: $total_windows"
echo "  ✓ Successfully completed: $newly_completed"
echo "  ✗ Failed: $failed"
echo "  Previously complete (skipped): $completed_windows"
echo ""

if [ $failed -gt 0 ]; then
    echo "FAILED windows (need investigation):"
    for log in "$LOG_DIR"/*.log; do
        if [[ "$log" == *window_discovery* ]]; then
            continue
        fi
        
        if ! grep -q "Exit Code: 0" "$log" 2>/dev/null; then
            for window in "${all_windows[@]}"; do
                window_path=$(realpath --relative-to="$WORK_DIR" "$window")
                log_name=$(echo "$window_path" | tr '/' '_')
                if [[ "$log" == *"$log_name"* ]]; then
                    echo "  - $window_path"
                    echo "    Log: $log"
                    break
                fi
            done
        fi
    done
    echo ""
fi

echo "Logs in: $LOG_DIR"
echo "Window discovery log: $DISCOVERY_LOG"
echo ""
echo "========================================================================"
echo "GUARANTEE MET: All ${#all_windows[@]} windows were executed"
echo "              (not counting previously completed windows)"
echo "========================================================================"
