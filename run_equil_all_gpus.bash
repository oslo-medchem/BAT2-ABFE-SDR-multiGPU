#!/bin/bash

###############################################################################
# GPU-Only Equilibration Runner with Memory Checking
# - Checks GPU memory availability before job submission
# - Waits for GPU with sufficient free memory
# - One job per GPU
# - NO CPU fallback
###############################################################################

EQUIL_DIR="./equil"
NUM_GPUS=8
REQUIRED_FREE_MEMORY=8000  # Minimum free memory in MB required to submit job

# Get absolute paths
WORK_DIR=$(pwd)
LOG_DIR="${WORK_DIR}/equil_logs"
mkdir -p "$LOG_DIR"

# Track which GPU is running which job
declare -A GPU_JOBS
declare -A GPU_LIGANDS

###############################################################################
# Function: Get GPU free memory in MB
###############################################################################
get_gpu_free_memory() {
    local gpu_id=$1
    
    if ! command -v nvidia-smi &> /dev/null; then
        echo "ERROR: nvidia-smi not found"
        exit 1
    fi
    
    # Get total and used memory
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
        return 0  # True - enough memory
    else
        return 1  # False - not enough memory
    fi
}

###############################################################################
# Function: Check if GPU is available (not running a job from this script)
###############################################################################
is_gpu_available() {
    local gpu_id=$1
    
    # Check if we have a job assigned to this GPU
    if [ -n "${GPU_JOBS[$gpu_id]}" ]; then
        local pid=${GPU_JOBS[$gpu_id]}
        # Check if process still running
        if kill -0 $pid 2>/dev/null; then
            return 1  # False - job still running
        else
            # Job finished, clean up
            unset GPU_JOBS[$gpu_id]
            unset GPU_LIGANDS[$gpu_id]
            return 0  # True - GPU available
        fi
    fi
    
    return 0  # True - no job assigned
}

###############################################################################
# Function: Find available GPU with enough memory
# Returns GPU ID or -1 if none available
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
        # Clean up finished jobs
        cleanup_finished_jobs
        
        # Try to find available GPU
        local gpu_id=$(find_available_gpu)
        
        if [ $gpu_id -ge 0 ]; then
            echo $gpu_id
            return 0
        fi
        
        # Show status every 10 iterations (30 seconds)
        if [ $((wait_count % 10)) -eq 0 ]; then
            echo "[$(date '+%H:%M:%S')] Waiting for GPU with ${REQUIRED_FREE_MEMORY}MB+ free memory..."
            show_gpu_memory_status
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
            unset GPU_LIGANDS[$gpu_id]
        fi
    done
}

###############################################################################
# Function: Show GPU memory status
###############################################################################
show_gpu_memory_status() {
    echo ""
    echo "GPU Memory Status:"
    for gpu_id in $(seq 0 $((NUM_GPUS - 1))); do
        local free_mem=$(get_gpu_free_memory $gpu_id)
        local status=""
        
        if [ -n "${GPU_JOBS[$gpu_id]}" ]; then
            status="BUSY: ${GPU_LIGANDS[$gpu_id]}"
        elif [ $free_mem -ge $REQUIRED_FREE_MEMORY ]; then
            status="AVAILABLE"
        else
            status="INSUFFICIENT MEMORY"
        fi
        
        printf "  GPU %d: %5d MB free - %s\n" $gpu_id $free_mem "$status"
    done
    echo ""
}

###############################################################################
# Function: Run equilibration on specific GPU
###############################################################################
run_on_gpu() {
    local lig_dir="$1"
    local gpu_id="$2"
    local ligand=$(basename "$lig_dir")
    local log_file="${LOG_DIR}/${ligand}_gpu${gpu_id}.log"
    
    local free_mem=$(get_gpu_free_memory $gpu_id)
    echo "[$(date '+%H:%M:%S')] Starting $ligand on GPU $gpu_id (${free_mem} MB free)"
    
    (
        cd "$lig_dir" || exit 1
        export CUDA_VISIBLE_DEVICES=$gpu_id
        
        echo "=== Job Started: $(date) ===" > "$log_file"
        echo "Ligand: $ligand" >> "$log_file"
        echo "GPU: $gpu_id" >> "$log_file"
        echo "GPU Free Memory at Start: ${free_mem} MB" >> "$log_file"
        echo "Working Directory: $(pwd)" >> "$log_file"
        echo "" >> "$log_file"
        
        bash run-local.bash >> "$log_file" 2>&1
        exit_code=$?
        
        echo "" >> "$log_file"
        echo "=== Job Finished: $(date) ===" >> "$log_file"
        echo "Exit Code: $exit_code" >> "$log_file"
        
        if [ $exit_code -eq 0 ]; then
            echo "[$(date '+%H:%M:%S')] ✓ Completed: $ligand (GPU $gpu_id)"
        else
            echo "[$(date '+%H:%M:%S')] ✗ FAILED: $ligand (GPU $gpu_id, exit: $exit_code)"
        fi
        
        exit $exit_code
    ) &
    
    local job_pid=$!
    GPU_JOBS[$gpu_id]=$job_pid
    GPU_LIGANDS[$gpu_id]=$ligand
}

###############################################################################
# Main execution
###############################################################################

echo "========================================================================"
echo "GPU-Only Equilibration Runner with Memory Checking"
echo "========================================================================"
echo "Working directory: $WORK_DIR"
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

# Show initial GPU status
echo "Initial GPU Status:"
nvidia-smi --query-gpu=index,name,memory.total,memory.free,memory.used \
           --format=csv,noheader | \
while IFS=, read -r idx name total free used; do
    printf "  GPU %s: %s | Total: %s | Free: %s | Used: %s\n" \
           "$idx" "$name" "$total" "$free" "$used"
done
echo ""

# Find all ligand folders
shopt -s nullglob nocaseglob
lig_folders=("$EQUIL_DIR"/lig-*)
shopt -u nullglob nocaseglob

if [ ${#lig_folders[@]} -eq 0 ]; then
    echo "ERROR: No lig-* folders found in $EQUIL_DIR"
    exit 1
fi

echo "Found ${#lig_folders[@]} ligand folders"
echo ""

# Process each ligand
for lig_dir in "${lig_folders[@]}"; do
    ligand=$(basename "$lig_dir")
    
    # Check if run-local.bash exists
    if [ ! -f "$lig_dir/run-local.bash" ]; then
        echo "SKIP: $ligand (no run-local.bash)"
        continue
    fi
    
    # Wait for available GPU with enough memory
    gpu_id=$(find_available_gpu)
    
    if [ $gpu_id -lt 0 ]; then
        echo "[$(date '+%H:%M:%S')] All GPUs busy or insufficient memory, waiting..."
        gpu_id=$(wait_for_gpu)
    fi
    
    # Run on the available GPU
    run_on_gpu "$lig_dir" "$gpu_id"
    
    # Show current status
    show_gpu_memory_status
    
    # Brief delay before checking next job
    sleep 2
done

echo ""
echo "========================================================================"
echo "All jobs submitted. Waiting for completion..."
echo "========================================================================"
echo ""

# Wait for all jobs to finish
wait

echo ""
echo "========================================================================"
echo "All jobs completed"
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
echo "  Total: $total"
echo "  ✓ Completed: $completed"
echo "  ✗ Failed: $failed"
echo ""

if [ $failed -gt 0 ]; then
    echo "Failed jobs:"
    for log in "$LOG_DIR"/*.log; do
        if ! grep -q "Exit Code: 0" "$log" 2>/dev/null; then
            ligand=$(basename "$log" | sed 's/_gpu[0-9]*\.log//')
            echo "  - $ligand"
        fi
    done
    echo ""
fi

echo "Logs in: $LOG_DIR"
echo "========================================================================"
