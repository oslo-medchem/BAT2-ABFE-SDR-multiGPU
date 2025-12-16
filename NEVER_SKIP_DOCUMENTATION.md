# FEP Runner - NEVER SKIP VERSIONS

## ✅ **Problem SOLVED: No More Skipped Windows**

Two new versions that **GUARANTEE** execution of all windows:

1. **`run_fep_never_skip.bash`** - With smart completion checking
2. **`run_fep_force_all.bash`** - Runs everything, no checks

Both scripts **WAIT INDEFINITELY** for GPUs. They will **NEVER skip** a window due to lack of resources.

---

## 📋 **Version 1: run_fep_never_skip.bash** (RECOMMENDED)

### **What It Does**

- ✅ Finds ALL windows with run-local.bash
- ✅ **STRICT completion check** - only skips if truly finished
- ✅ **WAITS FOREVER** for GPU availability
- ✅ **NEVER escapes** from running a window
- ✅ One job per GPU

### **Completion Checking**

Only marks window as complete if it finds:
- File `md-02.out` (or similar) that contains **BOTH**:
  - `"TIMINGS"` section
  - `"Total wall time:"` line

**This is STRICT** - won't be fooled by partial runs.

### **When to Use**

- ✅ First run after BAT.py setup
- ✅ Resuming after interruption
- ✅ Want to skip truly completed windows
- ✅ Most common use case

### **Behavior**

```bash
Scanning windows...

WILL RUN: lig-fmm/rest/c00  ← Window needs to run
SKIP: lig-fmm/rest/c01 (verified complete)  ← Has finished output
WILL RUN: lig-fmm/rest/c02

======================================================================
Windows to RUN: 208
======================================================================

[1/208] fe/lig-fmm/rest/c00
[12:00:00] Waiting for GPU for: fe/lig-fmm/rest/c00
[12:00:00] Still waiting... (8/8 GPUs busy)  ← WAITS, doesn't skip!
[12:00:30] Still waiting... (8/8 GPUs busy)
[12:01:00] GPU 3 became available
[12:01:00] Starting fe/lig-fmm/rest/c00 on GPU 3
```

**Key Point:** If all GPUs busy, it **WAITS**. It does NOT skip.

---

## 📋 **Version 2: run_fep_force_all.bash** (SIMPLE)

### **What It Does**

- ✅ Finds ALL windows with run-local.bash
- ✅ Runs **EVERY window** - no exceptions
- ✅ **NO completion checking** - runs even if done
- ✅ **WAITS FOREVER** for GPU availability
- ✅ **NEVER escapes** from running a window

### **When to Use**

- ✅ Want to force re-run everything
- ✅ Don't trust completion checking
- ✅ Testing or debugging
- ✅ Starting completely fresh

### **Behavior**

```bash
======================================================================
FEP Runner - RUN ALL MODE
======================================================================
Will run ALL windows with run-local.bash
NO completion checking - will re-run everything
NEVER skips - waits indefinitely for GPU
======================================================================

Found 528 windows to run  ← ALL windows

[1/528] fe/lig-fmm/rest/c00
[12:00:00] Waiting for GPU for: fe/lig-fmm/rest/c00
[12:00:00] Still waiting... (8/8 GPUs busy)
[12:00:30] Still waiting... (8/8 GPUs busy)
[12:01:00] GPU 3 available
[12:01:00] START: fe/lig-fmm/rest/c00 on GPU 3
```

**Key Point:** Runs EVERYTHING, regardless of status.

---

## 🔥 **Key Difference from Previous Versions**

### **OLD Behavior (WRONG)**

```
GPU not available → Skip window ✗
Low memory → Skip window ✗
All GPUs busy → Skip window ✗
```

### **NEW Behavior (CORRECT)**

```
GPU not available → WAIT for GPU ✓
Low memory → WAIT for memory ✓
All GPUs busy → WAIT for free GPU ✓

RESULT: EVERY window gets executed ✓
```

---

## 🚀 **Usage**

### **Most Common: Smart Version**

```bash
cd /path/to/BAT

# This will run incomplete windows, skip completed ones
bash run_fep_never_skip.bash
```

### **Force Re-run Everything**

```bash
cd /path/to/BAT

# This runs ALL windows, no skipping
bash run_fep_force_all.bash
```

---

## 📊 **What You'll See**

### **When GPU Available Immediately**

```
[1/208] fe/lig-fmm/rest/c00
[12:00:00] START: fe/lig-fmm/rest/c00 on GPU 0
```

### **When Must Wait for GPU**

```
[5/208] fe/lig-fmm/rest/c04
[12:05:00] Waiting for GPU for: fe/lig-fmm/rest/c04
[12:05:00] Still waiting... (8/8 GPUs busy)
[12:05:30] Still waiting... (8/8 GPUs busy)
[12:06:00] Still waiting... (8/8 GPUs busy)
[12:06:30] GPU 2 available
[12:06:30] START: fe/lig-fmm/rest/c04 on GPU 2
```

**The script is PATIENT. It will wait as long as needed.**

---

## ✅ **Guarantees**

Both scripts guarantee:

1. ✅ **Every window with run-local.bash WILL be executed**
2. ✅ **No windows skipped due to GPU unavailability**
3. ✅ **Script waits indefinitely for resources**
4. ✅ **One job per GPU (no overloading)**
5. ✅ **Clear logging of what's happening**

---

## 🔍 **Comparison Table**

| Feature | run_fep_never_skip.bash | run_fep_force_all.bash |
|---------|------------------------|------------------------|
| Completion checking | ✅ STRICT | ❌ None |
| Skips completed windows | ✅ Yes (verified) | ❌ No |
| Waits for GPU | ✅ Forever | ✅ Forever |
| Runs incomplete windows | ✅ Yes | ✅ Yes |
| Re-runs completed windows | ❌ No | ✅ Yes |
| Speed | ⚡ Faster (skips done) | 🐢 Slower (runs all) |
| Use case | Normal operation | Force re-run all |

---

## 📝 **Detailed Execution Flow**

### **run_fep_never_skip.bash**

```
1. Scan all windows
   ├─ Check for run-local.bash
   ├─ Check if truly completed (STRICT)
   └─ Build list of windows to run

2. For each window in list:
   ├─ Check if GPU available
   ├─ If yes: Assign and run immediately
   └─ If no: WAIT (loop every 3 sec until GPU free)

3. Never give up - keep waiting until done
```

### **run_fep_force_all.bash**

```
1. Scan all windows
   ├─ Check for run-local.bash
   └─ Add ALL windows to list (no completion check)

2. For each window in list:
   ├─ Check if GPU available
   ├─ If yes: Assign and run immediately
   └─ If no: WAIT (loop every 3 sec until GPU free)

3. Never give up - keep waiting until done
```

---

## 🎯 **Which One to Use?**

### **Use `run_fep_never_skip.bash` if:**
- ✅ You want smart behavior
- ✅ Some windows are already done
- ✅ You want to save time
- ✅ **This is the DEFAULT recommendation**

### **Use `run_fep_force_all.bash` if:**
- ✅ You want to re-run everything
- ✅ You don't trust the completion check
- ✅ You're testing or debugging
- ✅ Starting completely fresh

---

## 💡 **Examples**

### **Example 1: First Run**

```bash
cd /path/to/BAT

# After BAT.py setup, nothing is complete
bash run_fep_never_skip.bash

# Output:
# Windows to RUN: 528
# (Runs all 528 windows)
```

### **Example 2: Resume After Crash**

```bash
# Script crashed after 6 hours
# 320 windows completed, 208 incomplete

bash run_fep_never_skip.bash

# Output:
# Windows to SKIP: 320 (verified complete)
# Windows to RUN: 208
# (Only runs the 208 incomplete ones)
```

### **Example 3: Force Re-run**

```bash
# Want to re-run everything

bash run_fep_force_all.bash

# Output:
# Found 528 windows to run
# (Runs all 528, even if previously completed)
```

---

## 🔧 **Configuration**

Both scripts have these settings at the top:

```bash
FE_DIR="./fe"                # FE directory location
NUM_GPUS=8                   # Number of GPUs to use
REQUIRED_FREE_MEMORY=8000    # Minimum free memory (MB)
```

**To change memory requirement:**

```bash
# Edit the script
REQUIRED_FREE_MEMORY=10000   # Require 10GB instead of 8GB
```

---

## 🎉 **Final Summary**

### **OLD PROBLEM:**
Windows were being skipped when GPUs were busy ❌

### **NEW SOLUTION:**
Scripts WAIT for GPUs, never skip ✅

### **GUARANTEE:**
Every window with run-local.bash WILL be executed ✅

### **RECOMMENDATION:**
Use `run_fep_never_skip.bash` for normal operation ✅

---

## 📁 **Files to Download**

**Essential:**
1. ✅ **`run_fep_never_skip.bash`** - Smart version (RECOMMENDED)
2. ✅ **`run_fep_force_all.bash`** - Simple version (runs everything)

**Also useful:**
3. `run_equil_all_gpus.bash` - For equilibration
4. `comprehensive_monitor.bash` - For monitoring
5. `diagnose_fep_with_completion.bash` - Check window status

---

## ⚡ **Quick Command Reference**

```bash
# Most common usage (smart version)
bash run_fep_never_skip.bash

# Force re-run everything
bash run_fep_force_all.bash

# Check what needs to run
bash diagnose_fep_with_completion.bash

# Monitor progress
bash comprehensive_monitor.bash
```

**NO MORE SKIPPED WINDOWS!** ✅
