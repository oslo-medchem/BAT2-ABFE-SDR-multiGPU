#!/bin/bash

###############################################################################
# GPU-Only FEP Simulation Runner with Memory Checking
# - Traverses fe/lig-*/rest/ and fe/lig-*/sdr/ subdirectories
# - Finds all window folders (c*, m*, e*, v*, etc.)
# - Runs run-local.bash in each window
# - Robust GPU memory checking
# - One job per GPU at a time
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
# Function: Wait for GPU with sufficient memory
###############################################################################
wait_for_gpu() {
    local wait_count=0
    
    while true; do
        cleanup_finished_jobs
        
        local gpu_id=$(find_available_gpu)
        
        if [ $gpu_id -ge 0 ]; then
            echo $gpu_id
            return 0
        fi
        
        if [ $((wait_count % 10)) -eq 0 ]; then
            echo "[$(date '+%H:%M:%S')] Waiting for GPU with ${REQUIRED_FREE_MEMORY}MB+ free memory..."
            show_gpu_status
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
# Function: Show GPU status
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
echo "GPU-Only FEP Simulation Runner"
echo "========================================================================"
echo "Working directory: $WORK_DIR"
echo "FE directory: $FE_DIR"
echo "Log directory: $LOG_DIR"
echo "Number of GPUs: $NUM_GPUS"
echo "Required free memory: ${REQUIRED_FREE_MEMORY} MB"
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

# Find all ligand folders
shopt -s nullglob nocaseglob
lig_folders=("$FE_DIR"/lig-*)
shopt -u nullglob nocaseglob

if [ ${#lig_folders[@]} -eq 0 ]; then
    echo "ERROR: No lig-* folders found in $FE_DIR"
    exit 1
fi

echo "Found ${#lig_folders[@]} ligand folders"
echo ""

# Collect all windows
all_windows=()

for lig_dir in "${lig_folders[@]}"; do
    ligand=$(basename "$lig_dir")
    echo "Scanning $ligand..."
    
    # Check for rest and sdr subdirectories
    for subdir in rest sdr; do
        subdir_path="$lig_dir/$subdir"
        
        if [ ! -d "$subdir_path" ]; then
            echo "  WARNING: $ligand/$subdir not found, skipping"
            continue
        fi
        
        # Find all window directories (any folder with run-local.bash)
        shopt -s nullglob
        windows=("$subdir_path"/*)
        shopt -u nullglob
        
        for window in "${windows[@]}"; do
            if [ -d "$window" ] && [ -f "$window/run-local.bash" ]; then
                all_windows+=("$window")
                window_name=$(basename "$window")
                echo "  Found: $ligand/$subdir/$window_name"
            fi
        done
    done
done

echo ""
echo "========================================================================"
echo "Total windows found: ${#all_windows[@]}"
echo "========================================================================"
echo ""

if [ ${#all_windows[@]} -eq 0 ]; then
    echo "ERROR: No windows with run-local.bash found"
    exit 1
fi

# Process each window
for window_dir in "${all_windows[@]}"; do
    # Wait for available GPU
    gpu_id=$(find_available_gpu)
    
    if [ $gpu_id -lt 0 ]; then
        gpu_id=$(wait_for_gpu)
    fi
    
    # Run window
    run_window "$window_dir" "$gpu_id"
    
    # Brief delay
    sleep 1
done

echo ""
echo "========================================================================"
echo "All windows submitted. Waiting for completion..."
echo "========================================================================"
echo ""

# Show periodic status while jobs run
while true; do
    cleanup_finished_jobs
    
    if [ ${#GPU_JOBS[@]} -eq 0 ]; then
        break
    fi
    
    show_gpu_status
    sleep 10
done

echo ""
echo "========================================================================"
echo "All FEP simulations completed"
echo "========================================================================"
echo ""

# Summary
total=$(ls -1 "$LOG_DIR"/*.log 2>/dev/null | wc -l)
completed=0
failed=0

for log in "$LOG_DIR"/*.log; do
    if grep -q "Exit Code: 0" "$log" 2>/dev/null; then
        ((completed++))
    else
        ((failed++))
    fi
done

echo "Summary:"
echo "  Total windows: $total"
echo "  ✓ Completed: $completed"
echo "  ✗ Failed: $failed"
echo ""

if [ $failed -gt 0 ]; then
    echo "Failed windows:"
    for log in "$LOG_DIR"/*.log; do
        if ! grep -q "Exit Code: 0" "$log" 2>/dev/null; then
            window=$(basename "$log" | sed 's/_gpu[0-9]*\.log$//')
            echo "  - $(echo $window | tr '_' '/')"
        fi
    done
    echo ""
fi

echo "Logs in: $LOG_DIR"
echo "========================================================================"
