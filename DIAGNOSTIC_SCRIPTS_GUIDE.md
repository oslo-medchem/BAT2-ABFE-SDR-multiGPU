# Diagnostic Scripts - Fixed Version

## 🔧 **Two New Diagnostic Scripts**

I've created improved versions to help debug the issue:

### **1. `show_fe_structure.bash`** - SIMPLEST (Run this first!)

```bash
cd /path/to/BAT
bash show_fe_structure.bash
```

**What it does:**
- Shows EXACTLY what's in your fe/ directory
- Lists all ligand folders
- Shows all subdirectories (rest/sdr/etc)
- Counts run-local.bash files
- Lists ALL locations with run-local.bash

**Example output:**
```
Ligand: lig-fmm
  Subdirectories:
    fe/lig-fmm/rest/
    fe/lig-fmm/sdr/
  Windows in rest/:
    c00 c01 c02 c03 c04 c05 c06 c07 c08 c09
    m00 m01 m02 m03 m04 m05 m06 m07 m08 m09
  Windows with run-local.bash:
    20
  Windows in sdr/:
    e00 e01 e02 e03 e04 e05 e06 e07 e08 e09 e10 e11
    v00 v01 v02 v03 v04 v05 v06 v07 v08 v09 v10 v11
  Windows with run-local.bash:
    24

Quick Statistics
Total ligand folders: 12
Total run-local.bash files: 528

All run-local.bash locations:
fe/lig-afa/rest/c00/run-local.bash
fe/lig-afa/rest/c01/run-local.bash
...
```

### **2. `diagnose_fep_windows_v2.bash`** - DETAILED

```bash
cd /path/to/BAT
bash diagnose_fep_windows_v2.bash
```

**What it does:**
- More detailed analysis
- Checks for case sensitivity issues
- Shows which windows have/don't have run-local.bash
- Identifies missing subdirectories
- Better error messages

**Improvements over v1:**
- ✅ Shows contents of each ligand directory
- ✅ Better case-insensitive matching
- ✅ More detailed error messages
- ✅ Shows actual file paths
- ✅ Additional diagnostic info

## 🚀 **Quick Debugging Workflow**

```bash
cd /path/to/BAT

# Step 1: Simple check
bash show_fe_structure.bash > structure.txt
cat structure.txt

# Step 2: If issues, run detailed diagnostic
bash diagnose_fep_windows_v2.bash > diagnosis.txt
cat diagnosis.txt

# Step 3: Look for:
# - Wrong counts
# - Missing run-local.bash files
# - Case sensitivity issues (REST vs rest)
# - Empty subdirectories
```

## 🔍 **What to Look For**

### **Check 1: Total Count**
```bash
# Should match your expected windows
bash show_fe_structure.bash | grep "Total run-local.bash files:"
# Output: Total run-local.bash files: 528
```

### **Check 2: Missing Files**
```bash
# Run detailed diagnostic
bash diagnose_fep_windows_v2.bash | grep "MISSING run-local.bash"
# Shows which windows don't have the file
```

### **Check 3: Case Issues**
```bash
# Check for mixed case
bash show_fe_structure.bash | grep -i "rest\|sdr"
# Should show rest/ or REST/ or Rest/ consistently
```

### **Check 4: Empty Directories**
```bash
# Look for subdirectories with no windows
bash diagnose_fep_windows_v2.bash | grep "No subdirectories found"
```

## 📤 **Send Me This Info**

If you still have issues, run this and send me the output:

```bash
cd /path/to/BAT

echo "=== Basic Info ===" > debug_info.txt
pwd >> debug_info.txt
echo "" >> debug_info.txt

echo "=== FE Directory Contents ===" >> debug_info.txt
ls -la fe/ >> debug_info.txt
echo "" >> debug_info.txt

echo "=== First Ligand Structure ===" >> debug_info.txt
ls -R fe/lig-*/ | head -50 >> debug_info.txt
echo "" >> debug_info.txt

echo "=== Run-local.bash Count ===" >> debug_info.txt
find fe/ -name "run-local.bash" | wc -l >> debug_info.txt
echo "" >> debug_info.txt

echo "=== First 10 Run-local.bash Locations ===" >> debug_info.txt
find fe/ -name "run-local.bash" | head -10 >> debug_info.txt

cat debug_info.txt
```

## 🐛 **Common Issues & Fixes**

### Issue: "No lig-* folders found"
```bash
# Check if you're in the right directory
pwd
ls -la | grep fe

# Should see fe/ directory
```

### Issue: "No run-local.bash files found"
```bash
# Check if BAT.py finished running
cd fe/lig-fmm/rest/c00
ls -la

# Should see run-local.bash and other files
```

### Issue: Case sensitivity (REST vs rest)
```bash
# The new scripts handle this automatically
# But check what you actually have:
ls fe/lig-fmm/

# Shows actual case: rest/ or REST/
```

### Issue: Wrong count (expected 528, got 400)
```bash
# Find which windows are missing
bash diagnose_fep_windows_v2.bash | grep "MISSING"
```

## 📋 **Expected Output for Typical Setup**

For 12 ligands with standard BAT setup:
- **REST windows**: 20 per ligand (c00-c09, m00-m09)
- **SDR windows**: 24 per ligand (e00-e11, v00-v11)
- **Total per ligand**: 44 windows
- **Total for 12 ligands**: 528 windows

```bash
Total ligand folders: 12
Total run-local.bash files: 528
```

If you see different numbers, the diagnostic will show why.

## ✅ **Verification Command**

Quick one-liner to verify everything:

```bash
cd /path/to/BAT
echo "Expected: 528 windows (12 ligands × 44 windows)"
echo "Found: $(find fe/ -name 'run-local.bash' | wc -l) windows"
find fe/ -name 'run-local.bash' | wc -l | grep -q "528" && echo "✓ All windows present!" || echo "✗ Some windows missing!"
```

## 🎯 **Next Steps**

1. **Run `show_fe_structure.bash`** first - see what you have
2. **If counts are wrong**, run `diagnose_fep_windows_v2.bash` for details
3. **Send me the output** and I'll help fix the issue

Both scripts are now available for download!
