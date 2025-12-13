# 🏗️ PyTorch on Windows for Older GPUS (Kepler +)

## Quick summary (What & For whom)
- **Goal:** Run PyTorch on Windows with Kepler GPUs (Tesla K40c, compute capability **3.5**).  
- **Recommended / tested:** PyTorch **1.12.1**, **1.13**, **2.0.0**, **2.0.1** (newer versions usually need extra CUDA patches).  
- **Stack:** CUDA **11.4.4**, cuDNN **8.7.0**, Visual Studio **2019**, **Python 3.9**.  

If you don't want to build from source, see **Pre-Built Wheels** below.

## 📦 Pre-Built Wheels (Python 3.9, CUDA 11.4 + cuDNN 8.7)
> Wheels are built for Python **3.9** and include the architectures: `TORCH_CUDA_ARCH_LIST = 3.5;3.7;5.0;5.2;6.0;6.1;7.0;7.5`.

| PyTorch Version | Python | CUDA | Wheel |
|-----------------|--------|------|-------|
| 1.12.1          | 3.9    | 11.4.4 + | [Download wheel](https://example.com/torch-1.12.1-cu114-sm35.whl) |
| 1.13.0          | 3.9    | 11.4.4+ | [Download wheel](https://example.com/torch-1.13.0-cu114-sm35.whl) |
| 2.0.0           | 3.9    | 11.4.4+  | [Download wheel](https://example.com/torch-2.0.0-cu114-sm35.whl) |
| 2.0.1           | 3.9    | 11.4.4+  | [Download wheel](https://example.com/torch-2.0.1-cu114-sm35.whl) |

**Install example**
```bash
pip install torch-2.0.1-cu114-sm35.whl
```

---

# 1. What and where do you need to build your own wheels? 

A quick overview of which tools are required for **building PyTorch** and which are needed only for **using the pre-built wheels**.

| Tool / Item                | Needed to Build | Needed to Use Wheel |
|----------------------------|:---------------:|:-------------------:|
| **Visual Studio 2019 (MSVC)** | ✅ | ❌ |
| **CUDA Toolkit 11.4.4**     | ✅ | ❌ *(driver only required)* |
| **cuDNN 8.7.0**             | ✅ | ❌ |
| **Python 3.9 (via miniconda)**              | ✅ | ✅ |
| **Git**                     | ✅ | ❌ *(optional)* |
| **CMake (≥ 3.5 recommended)** | ✅ | ❌ |
| **Ninja**                   | ✅ | ❌ |
| **pip / build (PEP 517)**   | ✅ | ✅ |


# 2. Install & Verify Python / pip prerequisites (on Windows)
Create env (recommended) and install required pip packages:
 
```python
# (recommended) create a conda env and activate it, or use your existing Python 3.9
conda create -n pytorch_k40 python=3.9 -y
conda activate pytorch_k40

# Upgrade pip and install basic build/runtime deps
python -m pip install --upgrade pip
pip install wheel typing-extensions future six numpy pyyaml
# if you need a specific numpy that works with older CUDA builds:
pip install numpy==1.21.6
```

# 3. Clone & Prepare PyTorch (of select version) from Github
- Launch x64 Native Tools Command Prompt for VS 2019

```batch
:: 1. Go to your desired source directory
cd C:\Users\<You>\source

:: 2. Clone PyTorch at the specific tag
git clone --recursive https://github.com/pytorch/pytorch.git --branch v1.12.1
cd pytorch

:: 3. Mark the directory as safe (Windows Git safety check)
git config --global --add safe.directory C:/Users/<You>/source/pytorch
```

#  4. Apply patches
## 4.1 Patch Windows VC-Vars Overlay
If you run the older pytorch versions you will get a bug due to distuitils change (AttributeError: module 'distutils' has no attribute '_msvccompiler')
```batch
C:\Users\Admin\source\pytorch>python setup.py develop
Building wheel torch-1.12.0a0+git664058f
-- Building version 1.12.0a0+git664058f
Traceback (most recent call last):
  File "C:\Users\Admin\source\pytorch\setup.py", line 944, in <module>
    build_deps()
  File "C:\Users\Admin\source\pytorch\setup.py", line 400, in build_deps
    build_caffe2(version=version,
  File "C:\Users\Admin\source\pytorch\tools\build_pytorch_libs.py", line 81, in build_caffe2
    my_env = _create_build_env()
  File "C:\Users\Admin\source\pytorch\tools\build_pytorch_libs.py", line 67, in _create_build_env
    my_env = _overlay_windows_vcvars(my_env)
  File "C:\Users\Admin\source\pytorch\tools\build_pytorch_libs.py", line 36, in _overlay_windows_vcvars
```

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

## 4.2 Fix CMake Version Requirement (PyTorch 1.13+)

Newer PyTorch versions may fail to configure if your environment uses CMake 3.5.  
Update the project’s minimum version requirement:

```cmake
- cmake_minimum_required(VERSION 3.1.3)
+ cmake_minimum_required(VERSION 3.5 FATAL_ERROR)
```

To update all `cmake_minimum_required` directives across the PyTorch source tree, run the CMake patch script from the repo root:
* Recommended to run with dry run first
```batch
python patch_cmake_minimum.py --root C:\Users\Admin\source\pytorch --dry
```

* Then proceed to full run if satisfied
```batch
python patch_cmake_minimum.py --root C:\Users\Admin\source\pytorch
```



#  5. Build your Wheel with flags
```batch
@echo off
REM Load MSVC compiler environment and go to directory
CALL "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build\vcvars64.bat"
cd /d C:\Users\%USERNAME%\source\pytorch


REM Flags: CUDA
set USE_CUDA=1
set USE_CUDNN=1
REM set TORCH_CUDA_ARCH_LIST=3.5
set TORCH_CUDA_ARCH_LIST=3.5;3.7;5.0;5.2;5.3;6.0;6.1;6.2;7.0;7.2;7.5

REM Flags: Build, Primary (cmake version and performance build, 02 vs 0d and enable big files)
set CL=/bigobj %CL% /O2
set CMAKE_ARGS=-DCMAKE_POLICY_VERSION_MINIMUM=3.5 -DCMAKE_BUILD_TYPE=Release

REM Flags: Build, Secondary
set USE_NINJA=1
set USE_CUPTI=0
set USE_KINETO=0

REM Flags: Internal, windows single device specific 
set USE_DISTRIBUTED=OFF
set USE_TENSORPIPE=OFF

REM Build (PEP517 wheel builder, no isolation)
python -m build --wheel --no-isolation

REM ### (possible)Failure Condition 1 (cmake flags) ###
REM use patch the setuptools thingy for msvc (github)

REM ### (possible)Failure Condition 2 (cmake flags) ###
REM use patch_cmake_minimum.py (first with dry run to fix)


REM Cleanup (wheel is in /dist)
rmdir /s /q build

pause


```


# 🎉 Congratulations!
You now have a fully native Windows build of PyTorch for Kepler GPUs—and a portable wheel you can install anywhere. Feel free to tweak flags to suit other architectures, CPU features, or profiling needs. Enjoy!
