# 🏗️ PyTorch on Windows for Older GPUS (Kepler +)
- **Goal:** Run PyTorch on Windows with Kepler GPUs (Tesla K40c, compute capability **3.5**).  
- **Stack:** Pytorch **1.12.1 - 2.0.1**, CUDA **11.4.4**, cuDNN **8.7.0+**, Visual Studio **2019**, **Intel oneAPI**, **Python 3.9+**.  
- **Arch List** CUDA 3.5;3.7;5.0;5.2;6.0;6.1;7.0;7.5

# 0. Pre-Built Wheels: 
Before building from source, check if a *prebuilt wheel is available for your setup*.

---
High Performance Wheels: (MKL + MKLDNN + CUDNN + AVX1)
| PyTorch Version | Python | CUDA | Wheel |
|-----------------|--------|------|-------|
| 2.7.1 (cc35 only, all arches coming soon)         | 3.11    | 11.4.4 + | [Download wheel](https://drive.google.com/file/d/1rbzhEiiY5Xe-2TQ1ejAlmBwRbUx-EMHr/view?usp=sharing)|
| 2.0.1          | 3.11    | 11.4.4 + | [Download wheel](https://drive.google.com/file/d/1L84dnAnMdekX7rJjnxz0vKcmR2LHvfen/view?usp=sharing)|

NOTE TO RUN 2.7.1 YOU MUST INSTALL THE REQUIREMENTS (pip install -r"path-to-requirements')


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
# Notes on building pytorch 2.7.1 on kepler: 
- backend changes were made, requiring using m build instead. 

Steps to build (very ugly, work in progress) 

0: Install all the same tools, except cuda 11.7 (and if you want a newer cudnn). Important, with cuda 11.7/11.8 and cc35: Install toolkit and Plugin, NOT DRIVER!! Once installed, run the patch cmake min ONLY. Next, install dependencies from txt file
```batch
astunparse==1.6.3
build==1.4.0
certifi==2026.1.4
charset-normalizer==3.4.4
cmake==4.2.1
colorama==0.4.6
expecttest==0.3.0
filelock==3.20.3
fsspec==2026.1.0
hypothesis==6.150.2
idna==3.11
intel-cmplr-lib-ur==2025.3.1
intel-openmp==2025.3.1
Jinja2==3.1.6
lintrunner==0.12.11
MarkupSafe==3.0.3
mkl==2025.3.0
mkl-include==2025.3.0
mkl-static==2025.3.0
mpmath==1.3.0
networkx==3.6.1
ninja==1.13.0
numpy==2.4.1
onemkl-license==2025.3.0
optree==0.18.0
packaging==25.0
psutil==7.2.1
pyproject_hooks==1.2.0
PyYAML==6.0.3
requests==2.32.5
six==1.17.0
sortedcontainers==2.4.0
sympy==1.14.0
tbb==2022.3.0
tbb-devel==2022.3.0
tcmlib==1.4.1
types-dataclasses==0.6.6
typing_extensions==4.15.0
umf==1.0.2
urllib3==2.6.3
```


1: Run the builder (note, VERY experimental at the moment)
```batch
@echo off
setlocal EnableDelayedExpansion

REM 0: Clear Anything Stale Intel
REM ===============================
set CC=cl
set CXX=cl
set CMAKE_C_COMPILER=cl
set CMAKE_CXX_COMPILER=cl

set ONEAPI_ROOT=
set ICPP_COMPILER=
set ICX=
set ICC=

REM 1: Initialize Paths
REM ===============================
set "SRC_DIR=C:\Users\%USERNAME%\source\pytorch"

REM A: Call builders
call "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build\vcvars64.bat" x64
REM call "C:\Program Files (x86)\Intel\oneAPI\compiler\latest\env\vars.bat"


REM B: Initialize MKL (properly)
REM set "MKLROOT=C:\Program Files (x86)\Intel\oneAPI\mkl\latest"
REM set "CMAKE_PREFIX_PATH=%MKLROOT%"
REM set "LIB=%LIB%;%MKLROOT%\lib\intel64"
REM set "INCLUDE=%INCLUDE%;%MKLROOT%\include"
REM set "PATH=%PATH%;%MKLROOT%\bin"


REM C: Initialize CUDA 
set "CUDA_PATH=C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v11.7"

set "CUDNN_LIB_DIR=%CUDA_PATH%\lib\x64"
set "CUDNN_INCLUDE_DIR=%CUDA_PATH%\include"
set "CUDA_TOOLKIT_ROOT_DIR=%CUDA_PATH%"
set PATH=%CUDA_PATH%\bin;%CUDA_PATH%\libnvvp;%PATH%



REM 2: Enter Source and Build Wheel
REM ===============================
pushd "%SRC_DIR%" || (
    echo ERROR: Failed to enter %SRC_DIR%
    exit /b 1
)

REM Build Options (mkl buggy, change to your cc desired version) 
REM set USE_MKL=0
REM set USE_MKLDNN=0
set "TORCH_CUDA_ARCH_LIST=3.5"
python -m build --wheel --no-isolation


REM ===== Cleanup =====
popd
endlocal
exit /b 0
```

2: This will produce a wheel, however there is a bug with windows as linking broken. 
- something weird is happening with linking aoti custom ops:
 ```batch
OSError: [WinError 126] The specified module could not be found. Error loading "C:\Users\Admin\miniconda3\envs\py311\Lib\site-packages\torch\lib\aoti_custom_ops.dll" or one of its dependencies.
```

The dependencies it calls are: 

→ mkl_intel_thread.2.dll

→ libiomp5md.dll

→ cupti64_2022.2.1.dll

these can be added either to the install root of the wheel (in this case where aoti lives) OR you can patch them to wheel manually via opening it and packing the 3 DLL's into torch/lib and repackaging wheel. Currently a better fix is being investigated, this is all highly experimental. 

To open wheel, I used 7zip. 

To package wheel I used this: 
```python
# make_wheel.py
import os
import sys
from zipfile import ZipFile

if len(sys.argv) != 3:
    print("Usage: python make_wheel.py <source_folder> <output_wheel>")
    sys.exit(1)

src_folder = sys.argv[1]
wheel_name = sys.argv[2]

# Ensure the source folder exists
if not os.path.isdir(src_folder):
    print(f"Error: source folder '{src_folder}' does not exist")
    sys.exit(1)

# Convert to absolute paths
src_folder = os.path.abspath(src_folder)
wheel_name = os.path.abspath(wheel_name)

# Create the wheel
with ZipFile(wheel_name, 'w') as zf:
    for root, dirs, files in os.walk(src_folder):
        for f in files:
            filepath = os.path.join(root, f)
            # Compute relative path inside the wheel
            arcname = os.path.relpath(filepath, src_folder)
            zf.write(filepath, arcname)

print(f"Wheel created: {wheel_name}")
```

















# How to Make your own wheels? [ <= version 2.0.1]

# 0: Configure System Priors

## 0.1 Miniconda
### A: Configure robust builder with (mini) conda
- Install (newest) miniconda from the repo
- Do NOT register to path or register as default!!! (only shortcuts and cleanup)

### B: create environment for your python version (3.9-3.11) and activate
	conda create -n py311 python=3.11
	conda activate py311

### C: install dependencies 
Preferably install via dependecy folder in pytorch, alternatively as a fallback use: 

```batch
pip install wheel typing-extensions future six numpy==1.26.4 pyyaml build ninja cmake astunparse
```

## 0.2 GIT
- Install git from internet and run: 
```batch
:: 1. Go to your desired source directory
cd C:\Users\<You>\source

:: 2. Clone PyTorch at the specific tag
git config --system core.longpaths true
git clone --recursive https://github.com/pytorch/pytorch.git --branch v2.0.1

```

### 0.3 Patch Windows VC-Vars Overlay (distutils change, only needed in pytorch below about 2.0.1)
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

**NOTE**: For newer cuda toolkits (11.7,11.8) while these support the kepler k40 the driver does not. In order to use them, install a previous cuda toolkit (11.4) with driver and then update to toolkit of choice and select to not install driver!

## D: cuDNN (link)
- Copy cuDNN **directly into the CUDA folder**, **not anywhere else**:

# 2: Run Build script
- open anaconda prompt
```anaconda prompt```

- select and activate your environment (py311)
```conda activate py311```

- initialize (64 bit) builder of your choice via
```batch
call "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build\vcvars64.bat
```
- run build_torch.cmd script.
```batch
build_torch.cmd
```
NOTE: 
1: If you are facing issues with python version, try the fixed version fallback (ie if you have a different name then py311 or similar)

2: If you are planning to build a newer version of pytorch (say 2.7.1) update your cuda toolkit to 11.7.1 / 11.8 as these support kepler 2.0 cc35 and are required for bfloat patch. 
```batch
set "CUDA_ROOT=C:/Program Files/NVIDIA GPU Computing Toolkit/CUDA/v11.4"
=>
set "CUDA_ROOT=C:/Program Files/NVIDIA GPU Computing Toolkit/CUDA/v11.7"
```

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
