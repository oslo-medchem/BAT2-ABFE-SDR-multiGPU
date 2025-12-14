#!/bin/bash

#=============================================================================
# Equilibration Setup Validator
# Checks that everything is ready before running jobs
#=============================================================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

errors=0
warnings=0

echo "========================================================================="
echo "SDR Equilibration Setup Validation"
echo "========================================================================="
echo ""

#=============================================================================
# Check 0: Find equil directory
#=============================================================================
echo -e "${BLUE}[0] Locating equilibration directory...${NC}"
EQUIL_DIR=""

# Check current directory
if [ -d "./equil" ]; then
    EQUIL_DIR="./equil"
    echo -e "  ${GREEN}✓${NC} Found ./equil in current directory"
# Check parent directory
elif [ -d "../equil" ]; then
    EQUIL_DIR="../equil"
    echo -e "  ${YELLOW}⚠${NC}  Found ../equil (you're inside a subdirectory)"
    echo "    Please run scripts from the parent directory"
    cd .. || exit 1
    echo "    Changed to: $(pwd)"
# Check if we're already inside equil
elif [ -d "./lig-afa" ] || [ -d "./lig-gef" ] || ls -d ./lig-* >/dev/null 2>&1; then
    EQUIL_DIR="."
    echo -e "  ${YELLOW}⚠${NC}  You appear to be inside the equil directory"
    echo "    Current directory contains lig-* folders"
    echo "    Please run scripts from the parent directory that contains 'equil/'"
    echo ""
    echo "Current location: $(pwd)"
    echo "You should probably: cd .."
    ((warnings++))
else
    echo -e "  ${RED}✗${NC} Cannot find equil directory"
    echo ""
    echo "Current directory: $(pwd)"
    echo ""
    echo "Please run this script from the directory that contains the 'equil' folder."
    echo "Your directory structure should look like:"
    echo "  your-project/"
    echo "  ├── equil/"
    echo "  │   ├── lig-afa/"
    echo "  │   ├── lig-gef/"
    echo "  │   └── ..."
    echo "  ├── run_equil_all_gpus.bash"
    echo "  └── ..."
    exit 1
fi
echo ""

#=============================================================================
# Check 1: GPU availability
#=============================================================================
echo -e "${BLUE}[1] Checking GPU availability...${NC}"
if command -v nvidia-smi &> /dev/null; then
    gpu_count=$(nvidia-smi --query-gpu=index --format=csv,noheader | wc -l)
    echo -e "  ${GREEN}✓${NC} Found $gpu_count GPU(s)"
    nvidia-smi --query-gpu=index,name,memory.total --format=csv,noheader | \
    while IFS=, read -r idx name mem; do
        echo "    GPU $idx: $name ($mem)"
    done
else
    echo -e "  ${RED}✗${NC} nvidia-smi not found"
    ((errors++))
fi
echo ""

#=============================================================================
# Check 2: Equilibration directory structure
#=============================================================================
echo -e "${BLUE}[2] Checking equilibration directory...${NC}"
if [ -d "$EQUIL_DIR" ]; then
    echo -e "  ${GREEN}✓${NC} $EQUIL_DIR directory exists"
    
    # Use case-insensitive pattern matching
    shopt -s nullglob nocaseglob
    lig_folders=("$EQUIL_DIR"/lig-*)
    shopt -u nullglob nocaseglob
    
    lig_count=${#lig_folders[@]}
    
    if [ $lig_count -gt 0 ]; then
        echo -e "  ${GREEN}✓${NC} Found $lig_count ligand folders"
        
        # Sample first few
        echo "    Sample folders:"
        count=0
        for dir in "${lig_folders[@]}"; do
            if [ $count -lt 5 ]; then
                echo "      - $(basename "$dir")"
                ((count++))
            fi
        done
        if [ $lig_count -gt 5 ]; then
            echo "      ... and $((lig_count - 5)) more"
        fi
    else
        echo -e "  ${RED}✗${NC} No lig-* folders found in $EQUIL_DIR"
        echo ""
        echo "Contents of $EQUIL_DIR:"
        ls -la "$EQUIL_DIR" | head -20
        ((errors++))
    fi
else
    echo -e "  ${RED}✗${NC} $EQUIL_DIR directory not found"
    ((errors++))
fi
echo ""

#=============================================================================
# Check 3: run-local.bash scripts
#=============================================================================
echo -e "${BLUE}[3] Checking run-local.bash scripts...${NC}"
missing=0
found=0

if [ -d "$EQUIL_DIR" ]; then
    shopt -s nullglob nocaseglob
    for lig_dir in "$EQUIL_DIR"/lig-*; do
        ligand=$(basename "$lig_dir")
        if [ -f "$lig_dir/run-local.bash" ]; then
            ((found++))
        else
            if [ $missing -eq 0 ]; then
                echo -e "  ${YELLOW}⚠${NC}  Missing run-local.bash in:"
            fi
            echo "      - $ligand"
            ((missing++))
            ((warnings++))
        fi
    done
    shopt -u nullglob nocaseglob
    
    if [ $found -eq 0 ]; then
        echo -e "  ${RED}✗${NC} No run-local.bash scripts found"
        echo "    Each lig-* folder should contain a run-local.bash script"
        ((errors++))
    elif [ $missing -eq 0 ]; then
        echo -e "  ${GREEN}✓${NC} All $found ligands have run-local.bash"
    else
        echo -e "  ${YELLOW}⚠${NC}  $found ligands OK, $missing missing run-local.bash"
    fi
fi
echo ""

#=============================================================================
# Check 4: Disk space
#=============================================================================
echo -e "${BLUE}[4] Checking disk space...${NC}"
available=$(df -h . | awk 'NR==2 {print $4}')
used_pct=$(df -h . | awk 'NR==2 {print $5}' | tr -d '%')

echo "  Available space: $available"
if [ "$used_pct" -gt 90 ]; then
    echo -e "  ${YELLOW}⚠${NC}  Disk is ${used_pct}% full - may run out of space"
    ((warnings++))
else
    echo -e "  ${GREEN}✓${NC} Sufficient disk space (${used_pct}% used)"
fi
echo ""

#=============================================================================
# Check 5: Previous runs
#=============================================================================
echo -e "${BLUE}[5] Checking for previous runs...${NC}"
if [ -f "./equil_progress.txt" ]; then
    completed=$(grep -c "^COMPLETED:" ./equil_progress.txt 2>/dev/null || echo 0)
    if [ $completed -gt 0 ]; then
        echo -e "  ${YELLOW}⚠${NC}  Found checkpoint with $completed completed jobs"
        echo "    These will be skipped. To restart, run:"
        echo "      bash manage_equil.bash reset"
    else
        echo -e "  ${GREEN}✓${NC} Checkpoint file exists but is empty"
    fi
else
    echo -e "  ${GREEN}✓${NC} No previous runs detected (fresh start)"
fi

if [ -d "./equil_logs" ]; then
    log_count=$(find ./equil_logs -name "*.log" 2>/dev/null | wc -l)
    if [ $log_count -gt 0 ]; then
        echo -e "  ${YELLOW}⚠${NC}  Found $log_count existing log files"
        echo "    To clean: bash manage_equil.bash clean"
    fi
else
    echo -e "  ${GREEN}✓${NC} No existing log directory"
fi
echo ""

#=============================================================================
# Check 6: Required scripts
#=============================================================================
echo -e "${BLUE}[6] Checking required scripts...${NC}"
all_found=true

scripts=(
    "run_equil_all_gpus.bash:Main runner script"
    "monitor_equil.bash:Monitor script"
    "manage_equil.bash:Management utility"
)

for script_info in "${scripts[@]}"; do
    IFS=: read -r script desc <<< "$script_info"
    if [ -f "./$script" ] && [ -x "./$script" ]; then
        echo -e "  ${GREEN}✓${NC} $script ($desc)"
    elif [ -f "./$script" ]; then
        echo -e "  ${YELLOW}⚠${NC}  $script exists but not executable"
        echo "    Run: chmod +x $script"
        ((warnings++))
        all_found=false
    else
        echo -e "  ${RED}✗${NC} $script not found"
        ((errors++))
        all_found=false
    fi
done
echo ""

#=============================================================================
# Summary
#=============================================================================
echo "========================================================================="
echo "Validation Summary"
echo "========================================================================="
echo "Current working directory: $(pwd)"
echo ""

if [ $errors -eq 0 ] && [ $warnings -eq 0 ]; then
    echo -e "${GREEN}✓ All checks passed!${NC}"
    echo ""
    echo "Ready to run:"
    echo "  bash run_equil_all_gpus.bash"
    echo ""
    echo "Monitor progress with:"
    echo "  bash monitor_equil.bash"
    exit 0
elif [ $errors -eq 0 ]; then
    echo -e "${YELLOW}⚠ $warnings warning(s) - review above${NC}"
    echo ""
    echo "You can proceed, but some issues may need attention."
    echo ""
    echo "To run anyway:"
    echo "  bash run_equil_all_gpus.bash"
    exit 0
else
    echo -e "${RED}✗ $errors error(s) found${NC}"
    if [ $warnings -gt 0 ]; then
        echo -e "${YELLOW}⚠ $warnings warning(s) found${NC}"
    fi
    echo ""
    echo "Please fix the errors above before proceeding."
    exit 1
fi
