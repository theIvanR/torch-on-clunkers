# 🏗️ PyTorch on Windows for Older GPUS (Kepler +)
- **Goal:** Run PyTorch on Windows with Kepler GPUs (Tesla K40c, compute capability **3.5**).  
- **Stack:** Pytorch **2.0.1**, CUDA **11.4.4**, cuDNN **8.7.0+**, Visual Studio **2019+**, **Intel oneAPI**, **Python 3.9+**.  

# 0. Pre-Built Wheels: 
Before building from source, check if a *prebuilt wheel is available for your setup*.

---
High Performance Wheels: (MKL + MKLDNN + CUDNN + AVX1)
| PyTorch Version | Python | CUDA | Wheel |
|-----------------|--------|------|-------|
| 2.0.1          | 3.10    | 11.4.4 + | [Download wheel](https://drive.google.com/file/d/1iiFDPHr5cioNi4LxNWycgExIxmYloZ0I/view?usp=drive_link)|
| 2.0.1          | 3.11    | 11.4.4 + | [Download wheel]()|

(more wheels coming soon)


Compatibility Wheels (openBLAS, SSE41)
```batch
target with: 
-DCMAKE_C_FLAGS="/arch:SSE4.1 ^
-DCMAKE_CXX_FLAGS="/arch:SSE4.1
 flags in cmake
```



---
# 1. Installing Dependencies

Depending on whether you are using a **prebuilt wheel** or **building from source**, the required dependencies differ.

## External / System Dependencies

| Tool / Item                  | Needed to Build | Needed to Use Wheel |
|-------------------------------|:---------------:|:-----------------:|
| **Visual Studio 2019 (MSVC)** | ✅ | ❌ |
| **CUDA Toolkit 11.4.4**       | ✅ | ❌ *(driver only required)* |
| **cuDNN 8.7.0**               | ✅ | ❌ |
| **oneAPI (Intel)**              | ✅ | ❌ *(poorly documented, use oneapi for mkl as the pip is unreliable `pip install mkl mkl-static mkl-include` )*
| **Git**                        | ✅ | ❌ *(optional)* |
| **CMake (≥ 3.5)**             | ✅ | ❌ |
| **Ninja**                      | ✅ | ❌ |

## Python / Pip Dependencies

| Package / Tool                | Needed to Build | Needed to Use Wheel |
|-------------------------------|:---------------:|:-----------------:|
| **Python 3.9 (via Miniconda)** | ✅ | ✅ |
| **pip / build (PEP 517)**     | ✅ | ✅ |
| **wheel**                     | ✅ | ✅ |
| **typing-extensions**         | ✅ | ✅ |
| **future**                     | ✅ | ✅ |
| **six**                        | ✅ | ✅ |
| **numpy==1.26.4**             | ✅ | ✅ |
| **pyyaml**                     | ✅ | ✅ |
| **astunparse**                 | ✅ | ✅ |
| **mkl-static**                 | ✅ | ✅ |
| **mkl-include**                | ✅ | ✅ |

Optional for distributed builds:

```bash
conda install -c conda-forge libuv=1.39
```

# 2. Create Python Environment & Install Dependencies (Windows)
Create env (recommended) and install required pip packages:
 
```python
# (recommended) create a conda env and activate it, or use your existing Python 3.9+ 
conda create -n pytorch_k40 python=3.9 -y
conda activate pytorch_k40

# Upgrade pip and install basic build/runtime deps
python -m pip install --upgrade pip
pip install wheel typing-extensions future six numpy==1.26.4 pyyaml build ninja cmake astunparse

# If using distributed:
conda install -c conda-forge libuv=1.39
```

# 3. Clone & Prepare PyTorch (of select version) from Github
- Launch x64 native development tools command prompt as Administrator (important, NOT the intel one due to conflicts)

```batch
:: 1. Go to your desired source directory
cd C:\Users\<You>\source

:: 2. Clone PyTorch at the specific tag
git clone --recursive https://github.com/pytorch/pytorch.git --branch v1.12.1
cd pytorch

:: 3. Mark the directory as safe (Windows Git safety check)
git config --global --add safe.directory C:/Users/<You>/source/pytorch
```

#  4. Apply Primary patches (mandatory)
## 4.1 Patch Windows VC-Vars Overlay (distutils change)
Fix: Open ```tools/build_pytorch_libs.py``` in your cloned PyTorch tree and edit
-At the top, replace the import of distutils with the modern setuptools path:
```batch
- from setuptools import distutils  # type: ignore[import]
+ from setuptools._distutils import _msvccompiler as distutils_msvccompiler # modern setuptools relocation of _msvccompiler
```
-In the _overlay_windows_vcvars function, update the call to use our new alias:
```batch
-    vc_env: Dict[str, str] = distutils._msvccompiler._get_vc_env(vc_arch)
+    vc_env: Dict[str, str] = distutils_msvccompiler._get_vc_env(vc_arch)
```

## 4.2 Patch CMake Version Requirement (via patch_cmake_minimum.py)
Newer PyTorch versions may fail to configure if your environment uses CMake 3.5.  
```cmake
- cmake_minimum_required(VERSION 3.1.3)
+ cmake_minimum_required(VERSION 3.5 FATAL_ERROR)
```

Fix: Update all via `cmake_minimum_required` directives across the PyTorch source tree, run the CMake patch script from the repo root:
* Recommended to run with dry run first
```batch
python patch_cmake_minimum.py --root C:\Users\Admin\source\pytorch --dry
```

* Then proceed to full run if satisfied
```batch
python patch_cmake_minimum.py --root C:\Users\Admin\source\pytorch
```

# 5 Apply secondary patches (if needed)

## 5.1 FlatBuffers stl_emulation.h
```batch

File:
third_party/flatbuffers/include/flatbuffers/stl_emulation.h

Patch:

--- n third_party/flatbuffers/include/flatbuffers/stl_emulation.h
@@
-const size_type count_;
+size_type count_;

Reason:
Intel compiler complains about 'const' here; removing it allows build.
```

---

## 5.2 JIT static ForkedSubgraphSRLauncher
```batch
File:
torch/csrc/jit/runtime/static/... (full path to class file)

Patch:

-namespace {
-class TORCH_API ForkedSubgraphSRLauncher {
+namespace {
+class ForkedSubgraphSRLauncher {
    // ... class definition ...
};
} // namespace

Reason:
TORCH_API requests external linkage, but anonymous namespace is internal linkage.
Removing TORCH_API resolves IntelLLVM conflicts.
```
---

## 5.3 Functorch arena.h (__builtin_clz fix)
```batch

File:
functorch/csrc/dim/arena.h

Patch:

*** Begin Patch
*** Update File: functorch/csrc/dim/arena.h
@@
 #ifdef _WIN32
 #include <intrin.h>
-// https://stackoverflow.com/questions/355967/how-to-use-msvc-intrinsics-to-get-the-equivalent-of-this-gcc-code
-inline unsigned int __builtin_clz(unsigned int x) {
-    unsigned long r = 0;
-    _BitScanReverse(&r, x);
-    return (31 - r);
-}
+#ifndef FUNCTORCH_CLZ_DEFINED
+#define FUNCTORCH_CLZ_DEFINED
+// Provide a project-local count-leading-zeros implementation for Windows.
+// Do NOT use the name __builtin_clz (reserved / collides with compiler builtins).
+inline unsigned int functorch_clz(unsigned int x) {
+    if (x == 0u) {
+        return 32u;
+    }
+    unsigned long r = 0;
+    _BitScanReverse(&r, x);
+    return (31u - r);
+}
+#endif
 #endif
@@
 inline int round2min8(int num) {
-   int nzeros = __builtin_clz((num - 1)|4);
+   int nzeros = functorch_clz((num - 1) | 4u);
    return 1 << (32 - nzeros);
 }
*** End Patch
```
Reason:
IntelLLVM complains because __builtin_clz collides with compiler built-ins.
Renamed to functorch_clz, added guard, and handled x == 0 safely.


#  6. Build your Wheel with flags (via build_torch.bat)
Select for which system you want to build PyTorch and act accordingly.

Launch builder scripts as **Administrator** in the terminal.

### Backend Selection

- **Intel CPU** → use the **MKL** builder  
- **Non-Intel CPU** → use **OpenBLAS**

### Optimization Flags

Tune build flags based on your hardware:

- **Intel CPU**
  - Enable MKL
  - Prefer AVX / AVX2 / AVX-512 when available
- **Non-Intel CPU**
  - Use OpenBLAS
- **AVX-512 capable CPUs**
  - Enable `XNNPACK`
  - Enable advanced vector kernels
- **Older CPUs**
  - Disable `XNNPACK`
  - Avoid AVX-512 specific kernels

### Final Step

Once the wheel is built, test the installation using the provided **sanity checker** script and enjoy 🚀

# Building Newer Versions of Torch (>2.0.1) 
*MASSIVE DUMPSTERFIRE* on windows, coming soon, 
