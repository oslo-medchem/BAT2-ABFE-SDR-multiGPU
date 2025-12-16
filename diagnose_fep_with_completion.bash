#!/bin/bash

###############################################################################
# FEP Window Discovery Diagnostic - WITH COMPLETION CHECKING
# Shows which windows exist, have run-local.bash, and are completed
###############################################################################

FE_DIR="./fe"

# Completion check files
COMPLETION_FILES=("md-02.out" "prod.out" "production.out" "final.out")

###############################################################################
# Function: Check if window is completed
###############################################################################
is_window_completed() {
    local window_dir="$1"
    
    # Check for specific completion files
    for completion_file in "${COMPLETION_FILES[@]}"; do
        if [ -f "$window_dir/$completion_file" ]; then
            if grep -q "TIMINGS\|Final\|Normal termination" "$window_dir/$completion_file" 2>/dev/null; then
                echo "$completion_file"
                return 0
            fi
        fi
    done
    
    # Check any .out files
    if ls "$window_dir"/*.out 1> /dev/null 2>&1; then
        for outfile in "$window_dir"/*.out; do
            if grep -q "TIMINGS\|Final\|Normal termination" "$outfile" 2>/dev/null; then
                echo "$(basename $outfile)"
                return 0
            fi
        done
    fi
    
    return 1
}

###############################################################################
# Main
###############################################################################

echo "========================================================================"
echo "FEP Window Discovery Diagnostic - WITH COMPLETION CHECKING"
echo "========================================================================"
echo ""

if [ ! -d "$FE_DIR" ]; then
    echo "ERROR: FE directory not found: $FE_DIR"
    exit 1
fi

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

total_windows_completed=0
total_windows_incomplete=0
total_windows_no_script=0
total_missing_subdirs=0

for lig_dir in "${lig_folders[@]}"; do
    ligand=$(basename "$lig_dir")
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Ligand: $ligand"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Check for rest and sdr subdirectories (case-insensitive)
    for subdir in rest sdr REST SDR Rest Sdr; do
        subdir_path="$lig_dir/$subdir"
        
        if [ -d "$subdir_path" ]; then
            echo ""
            echo "  ✓ Found subdirectory: $subdir/"
            
            # Find ALL subdirectories
            completed_count=0
            incomplete_count=0
            no_script_count=0
            
            shopt -s nullglob
            windows=("$subdir_path"/*)
            shopt -u nullglob
            
            for window in "${windows[@]}"; do
                if [ -d "$window" ]; then
                    window_name=$(basename "$window")
                    
                    # Check for run-local.bash
                    if [ ! -f "$window/run-local.bash" ]; then
                        echo "    ✗ $window_name/ - MISSING run-local.bash"
                        ((total_windows_no_script++))
                        ((no_script_count++))
                        continue
                    fi
                    
                    # Check completion status
                    completion_file=$(is_window_completed "$window")
                    if [ $? -eq 0 ]; then
                        echo "    ○ $window_name/ - COMPLETED ($completion_file)"
                        ((total_windows_completed++))
                        ((completed_count++))
                    else
                        echo "    ✓ $window_name/ - INCOMPLETE (needs to run)"
                        ((total_windows_incomplete++))
                        ((incomplete_count++))
                    fi
                fi
            done
            
            echo "    Subtotal: $completed_count completed, $incomplete_count incomplete, $no_script_count missing script"
        fi
    done
    
    # Check if rest/sdr don't exist
    if [ ! -d "$lig_dir/rest" ] && [ ! -d "$lig_dir/REST" ] && \
       [ ! -d "$lig_dir/Rest" ]; then
        echo "  ✗ rest/ subdirectory NOT FOUND"
        ((total_missing_subdirs++))
    fi
    
    if [ ! -d "$lig_dir/sdr" ] && [ ! -d "$lig_dir/SDR" ] && \
       [ ! -d "$lig_dir/Sdr" ]; then
        echo "  ✗ sdr/ subdirectory NOT FOUND"
        ((total_missing_subdirs++))
    fi
    
    echo ""
done

echo "========================================================================"
echo "SUMMARY"
echo "========================================================================"
echo ""
echo "Total ligands:                        ${#lig_folders[@]}"
echo ""
echo "Windows Status:"
echo "  ○ Already COMPLETED:                $total_windows_completed"
echo "  ✓ INCOMPLETE (need to run):         $total_windows_incomplete"
echo "  ✗ Missing run-local.bash:           $total_windows_no_script"
echo ""
echo "Total windows:                        $((total_windows_completed + total_windows_incomplete + total_windows_no_script))"
echo "Missing rest/sdr subdirectories:      $total_missing_subdirs"
echo ""

if [ $total_windows_incomplete -gt 0 ]; then
    echo "✓ WILL RUN: $total_windows_incomplete windows"
else
    echo "✓ All windows are already completed!"
fi

if [ $total_windows_completed -gt 0 ]; then
    echo "○ WILL SKIP: $total_windows_completed already completed windows"
fi

if [ $total_windows_no_script -gt 0 ]; then
    echo "✗ CANNOT RUN: $total_windows_no_script windows missing run-local.bash"
fi

echo ""
echo "========================================================================"
echo ""
echo "Legend:"
echo "  ○ = Completed (has output file with 'TIMINGS' or 'Final')"
echo "  ✓ = Incomplete (needs to run)"
echo "  ✗ = Missing run-local.bash (cannot run)"
echo ""
echo "Completion files checked: ${COMPLETION_FILES[@]}"
echo "========================================================================"
