# 🏗️ PyTorch on Windows for Older GPUS (Kepler +)
- **Goal:** Run PyTorch on Windows with Kepler GPUs (Tesla K40c, compute capability **3.5**).  
- **Stack:** Pytorch **1.12.1 - 2.0.1**, CUDA **11.4.4**, cuDNN **8.7.0+**, Visual Studio **2019**, **Intel oneAPI**, **Python 3.9+**.  
- ** Arch List** CUDA 3.5;3.7;5.0;5.2;6.0;6.1;7.0;7.5

# 0. Pre-Built Wheels: 
Before building from source, check if a *prebuilt wheel is available for your setup*.

---
High Performance Wheels: (MKL + MKLDNN + CUDNN + AVX1)
| PyTorch Version | Python | CUDA | Wheel |
|-----------------|--------|------|-------|
| 2.0.1          | 3.11    | 11.4.4 + | [Download wheel](https://drive.google.com/file/d/1L84dnAnMdekX7rJjnxz0vKcmR2LHvfen/view?usp=drive_link)|


Compatibility Wheels (openBLAS, SSE41)
```batch
target with: 
-DCMAKE_C_FLAGS="/arch:SSE4.1 ^
-DCMAKE_CXX_FLAGS="/arch:SSE4.1
 flags in cmake
```
(coming soon)

## Dependencies to run: 
- Cuda driver >470 and CC>= 35
- python

---
# How to Make your own wheels?

# 0: Configure System Priors

## 0.1 Miniconda
### A: Configure robust builder with (mini) conda
- Install (newest) miniconda from the repo
- Do NOT register to path or register as default!!! (only shortcuts and cleanup)

### B: create environment for your python version (3.9-3.11) and activate
	conda create -n py311 python=3.11
	conda activate py311

### C: install dependencies 
```batch
pip install wheel typing-extensions future six numpy==1.26.4 pyyaml build ninja cmake astunparse
```

## 0.2 GIT
- Install git from internet and run: 
```batch
:: 1. Go to your desired source directory
cd C:\Users\<You>\source

:: 2. Clone PyTorch at the specific tag
git clone --recursive https://github.com/pytorch/pytorch.git --branch v2.0.1
cd pytorch

:: 3. Mark the directory as safe (Windows Git safety check)
git config --global --add safe.directory C:/Users/<You>/source/pytorch
```

### 0.3 Patch Windows VC-Vars Overlay (distutils change)
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

### 0.4 Patch CMake Version Requirement (via patch_cmake_minimum.py)
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

# 1: Install Executables to Build

## A: Visual Studio
- Install **Visual Studio 2019** with **Desktop C++ development** options.
- [Visual Studio 2019 Download Link](https://visualstudio.microsoft.com/vs/older-downloads/)

## B: Intel OneAPI (link)
- Install the **latest Intel OneAPI** from the official website.
- Only needed if you want **MKL / BLAS acceleration**.
- Paths must be correctly appended in your build script:
  - `INCLUDE`
  - `LIB`
  - `PATH`

## C: CUDA Driver and Toolkit (link cuda, link toolkit)
- **Use DDU** (Display Driver Uninstaller) to clean any existing NVIDIA drivers first.
- Install the **NVIDIA display driver** of your choice (for example, `463.15` for Kepler K40s).
- Install the **CUDA Toolkit** of your choice (for example, `11.4.4` for Kepler K40s).
- Ensure that `nvcc.exe` exists in the CUDA `bin` directory.

## D: cuDNN (link)
- Copy cuDNN **directly into the CUDA folder**, **not anywhere else**:

# 2: Run Build script
- open anaconda prompt
- select and activate your environment (py311)
- initialize (64 bit) via
```batch
call "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build\vcvars64.bat
```
- run build_torch.cmd script. If you are facing issues with version selection in copy, try the fixed fallback.
- Enjoy (and test)
```batch
python -c "import torch; print('torch', torch.__version__); print('cuda available:', torch.cuda.is_available())"
```

# 2.5: Experiment with other flags and architectures
- no avx for example
- with xxnpack, etc








# 3: Known issues
## OSError: [WinError 126]
```batch
Running: 
python -c "import torch; print('torch', torch.__version__); print('cuda available:', torch.cuda.is_available())"

Produces: 
Traceback (most recent call last):
  File "<string>", line 1, in <module>
  File "C:\Users\Admin\miniconda3\envs\py310\lib\site-packages\torch\__init__.py", line 133, in <module>
    raise err
OSError: [WinError 126] The specified module could not be found. Error loading "C:\Users\Admin\miniconda3\envs\py310\lib\site-packages\torch\lib\backend_with_compiler.dll" or one of its dependencies.
```
Cause: nvcc was in the wrong place. Walk with dependency analyzer to see: 
2: missing files for backend_with_compiler.dll
nvToolsExt64_1.dll -> from internet (optional profiler)
cudnn64_8.dll -> from cudnn very important

Check them -> missing!
```batch
dir "C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v11.4\bin\nvToolsExt64_1.dll"
dir "C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v11.4\bin\cudnn64_8.dll"
```

fix: 
paste cudnn into cuda 114 to fix. Optionally paste profiler as well, however due to varying versions I recommend to avoid it and only paste cudnn64_8.dll from cudnn

## Additional patches

### 1 FlatBuffers stl_emulation.h
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

### 2 JIT static ForkedSubgraphSRLauncher
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

### 3 Functorch arena.h (__builtin_clz fix)
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
