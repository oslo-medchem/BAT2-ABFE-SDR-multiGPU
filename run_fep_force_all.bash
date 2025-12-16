#!/bin/bash

###############################################################################
# GPU-Only FEP Simulation Runner - RUN ALL VERSION
# - Runs EVERY window that has run-local.bash
# - NO completion checking (runs even if already done)
# - NEVER skips due to GPU availability - waits forever
# - Use this if you want to force re-run everything
###############################################################################

FE_DIR="./fe"
NUM_GPUS=8
REQUIRED_FREE_MEMORY=8000  # Minimum free memory in MB

# Get absolute paths
WORK_DIR=$(pwd)
LOG_DIR="${WORK_DIR}/fe_logs"
mkdir -p "$LOG_DIR"

# Track GPU assignments
declare -A GPU_JOBS
declare -A GPU_WINDOWS

###############################################################################
# Function: Get GPU free memory in MB
###############################################################################
get_gpu_free_memory() {
    local gpu_id=$1
    
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
    
    [ $free_mem -ge $REQUIRED_FREE_MEMORY ]
}

###############################################################################
# Function: Check if GPU is available
###############################################################################
is_gpu_available() {
    local gpu_id=$1
    
    if [ -n "${GPU_JOBS[$gpu_id]}" ]; then
        local pid=${GPU_JOBS[$gpu_id]}
        if kill -0 $pid 2>/dev/null; then
            return 1
        else
            unset GPU_JOBS[$gpu_id]
            unset GPU_WINDOWS[$gpu_id]
            return 0
        fi
    fi
    return 0
}

###############################################################################
# Function: Find available GPU
###############################################################################
find_available_gpu() {
    for gpu_id in $(seq 0 $((NUM_GPUS - 1))); do
        if is_gpu_available $gpu_id && has_enough_memory $gpu_id; then
            echo $gpu_id
            return 0
        fi
    done
    echo -1
    return 1
}

###############################################################################
# Function: Wait for GPU - NEVER give up
###############################################################################
wait_for_gpu_forever() {
    local window_desc="$1"
    local wait_count=0
    
    echo "[$(date '+%H:%M:%S')] Waiting for GPU for: $window_desc"
    
    while true; do
        # Clean up finished jobs
        for gpu_id in "${!GPU_JOBS[@]}"; do
            if ! kill -0 ${GPU_JOBS[$gpu_id]} 2>/dev/null; then
                unset GPU_JOBS[$gpu_id]
                unset GPU_WINDOWS[$gpu_id]
            fi
        done
        
        # Try to find available GPU
        local gpu_id=$(find_available_gpu)
        if [ $gpu_id -ge 0 ]; then
            echo "[$(date '+%H:%M:%S')] GPU $gpu_id available"
            echo $gpu_id
            return 0
        fi
        
        # Status every 30 seconds
        if [ $((wait_count % 10)) -eq 0 ]; then
            local busy=0
            for gpu_id in $(seq 0 $((NUM_GPUS - 1))); do
                [ -n "${GPU_JOBS[$gpu_id]}" ] && ((busy++))
            done
            echo "[$(date '+%H:%M:%S')] Still waiting... ($busy/$NUM_GPUS GPUs busy)"
        fi
        
        ((wait_count++))
        sleep 3
    done
}

###############################################################################
# Function: Run simulation
###############################################################################
run_window() {
    local window_dir="$1"
    local gpu_id="$2"
    local window_path=$(realpath --relative-to="$WORK_DIR" "$window_dir")
    local log_name=$(echo "$window_path" | tr '/' '_')
    local log_file="${LOG_DIR}/${log_name}_gpu${gpu_id}.log"
    
    echo "[$(date '+%H:%M:%S')] START: $window_path on GPU $gpu_id"
    
    (
        cd "$window_dir" || exit 1
        export CUDA_VISIBLE_DEVICES=$gpu_id
        
        echo "=== Started: $(date) ===" > "$log_file"
        echo "Window: $window_path" >> "$log_file"
        echo "GPU: $gpu_id" >> "$log_file"
        echo "" >> "$log_file"
        
        bash run-local.bash >> "$log_file" 2>&1
        exit_code=$?
        
        echo "" >> "$log_file"
        echo "=== Finished: $(date) ===" >> "$log_file"
        echo "Exit Code: $exit_code" >> "$log_file"
        
        if [ $exit_code -eq 0 ]; then
            echo "[$(date '+%H:%M:%S')] ✓ DONE: $window_path"
        else
            echo "[$(date '+%H:%M:%S')] ✗ FAIL: $window_path (exit $exit_code)"
        fi
    ) &
    
    GPU_JOBS[$gpu_id]=$!
    GPU_WINDOWS[$gpu_id]=$window_path
}

###############################################################################
# Main
###############################################################################

echo "========================================================================"
echo "FEP Runner - RUN ALL MODE"
echo "========================================================================"
echo "Will run ALL windows with run-local.bash"
echo "NO completion checking - will re-run everything"
echo "NEVER skips - waits indefinitely for GPU"
echo "========================================================================"
echo ""

if ! command -v nvidia-smi &> /dev/null; then
    echo "ERROR: nvidia-smi not found"
    exit 1
fi

if [ ! -d "$FE_DIR" ]; then
    echo "ERROR: $FE_DIR not found"
    exit 1
fi

# Find all windows
shopt -s nullglob nocaseglob
lig_folders=("$FE_DIR"/lig-*)
shopt -u nullglob nocaseglob

if [ ${#lig_folders[@]} -eq 0 ]; then
    echo "ERROR: No lig-* folders in $FE_DIR"
    exit 1
fi

all_windows=()

for lig_dir in "${lig_folders[@]}"; do
    for subdir_variant in rest REST Rest sdr SDR Sdr; do
        subdir_path="$lig_dir/$subdir_variant"
        [ ! -d "$subdir_path" ] && continue
        
        shopt -s nullglob
        windows=("$subdir_path"/*)
        shopt -u nullglob
        
        for window in "${windows[@]}"; do
            [ ! -d "$window" ] && continue
            [[ "$(basename "$window")" == .* ]] && continue
            
            if [ -f "$window/run-local.bash" ]; then
                all_windows+=("$window")
            fi
        done
    done
done

echo "Found ${#all_windows[@]} windows to run"
echo ""

if [ ${#all_windows[@]} -eq 0 ]; then
    echo "No windows found with run-local.bash"
    exit 0
fi

# Process each window
window_num=0
for window_dir in "${all_windows[@]}"; do
    ((window_num++))
    window_path=$(realpath --relative-to="$WORK_DIR" "$window_dir")
    
    echo "[$window_num/${#all_windows[@]}] $window_path"
    
    # Get GPU - wait if needed
    gpu_id=$(find_available_gpu)
    [ $gpu_id -lt 0 ] && gpu_id=$(wait_for_gpu_forever "$window_path")
    
    # Run it
    run_window "$window_dir" "$gpu_id"
    sleep 1
done

echo ""
echo "All submitted. Waiting for completion..."

# Wait for all to finish
while true; do
    for gpu_id in "${!GPU_JOBS[@]}"; do
        if ! kill -0 ${GPU_JOBS[$gpu_id]} 2>/dev/null; then
            unset GPU_JOBS[$gpu_id]
            unset GPU_WINDOWS[$gpu_id]
        fi
    done
    
    [ ${#GPU_JOBS[@]} -eq 0 ] && break
    sleep 5
done

echo ""
echo "========================================================================"
echo "ALL DONE"
echo "========================================================================"
echo "Attempted: ${#all_windows[@]} windows"
echo "Check logs in: $LOG_DIR"
echo "========================================================================"
