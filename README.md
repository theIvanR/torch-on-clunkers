🏗️ Build PyTorch from Source on Windows for Kepler GPUs

**Target hardware:** Tesla K40c / K80 (sm_35)  
**CUDA:** 11.4.4  
**cuDNN:** 8.7.0  
**Visual Studio:** 2019  
**Python:** 3.9  
**PyTorch version:** 1.12.x  

---

# 1. Tools & Why You Need Them
NOTE: for simplicity, I used miniconda with python 3.9 and added it to path. Of course, different settings and virtual environments can be used. 

| Tool                        | Purpose                                                         |
|-----------------------------|-----------------------------------------------------------------|
| Visual Studio 2019         | C/C++ compiler & linker (VC++ v14.x for CUDA 11.4 compatibility) |
| CUDA Toolkit 11.4.4        | `nvcc` compiler & GPU libraries for Kepler targets               |
| cuDNN 8.7.0                | NVIDIA’s optimized DL primitives                                |
| Python 3.9                 | Supported by PyTorch 1.12.x                                     |
| Git                        | Clone repo, manage versions & submodules                        |
| CMake                      | Generate Ninja/MSBuild project files                            |
| Ninja                      | Fast parallel build backend                                     |
| pip, build (PEP 517)       | Install Python deps & produce a wheel                           |

---

# 2. Install & Verify Prerequisites
Ensure all are in environment variables
- Python 
- Cuda (test with nvcc --version) and that Copy bin, include, lib/x64 (from cuDNN is pasted to) → ```C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v11.4\```
- Ninja 
- Cmake
- git

Python: 
```batch
pip install --upgrade pip
pip install wheel typing-extensions future six numpy pyyaml numpy==1.21.6
```

# 3. Launch x64 (or x86) Native Command Tools Prompt from Start
We will be using this command prompt for all further steps!

# 4. Clone & Prepare PyTorch (of select version) from Github
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

#  5. Install Python Build Dependencies

## 5.0 Upgrade Pip to newest version and install extensions

## 5.1 Patch Windows VC-Vars Overlay
If you run the older pytorch versions you will get a bug: 
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

- Why? On recent Windows/python/setuptools combinations, distutils._msvccompiler._get_vc_env has moved (or been hidden), so PyTorch’s original code: 
```batch
from setuptools import distutils
…
vc_env: Dict[str, str] = distutils._msvccompiler._get_vc_env(vc_arch)

raises:

AttributeError: module 'distutils' has no attribute '_msvccompiler'
```
## 5.2 Fix: Open ```tools/build_pytorch_libs.py``` in your cloned PyTorch tree and edit
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
-NOW it is safe to run!

## 5.3 Possible issue with newer versions such as 1.13+ of pytorch
```
These need patching to work with version 3.5 of cmake (like this) 
#cmake_minimum_required(VERSION 3.1.3) #old one
cmake_minimum_required(VERSION 3.5 FATAL_ERROR)

REM --- Patch MSVC relocation issues ---
REM patch from github
REM patch cmake version in third_party/protobuf/CMakeLists.txt
REM patch cmake in cpuinfo/clog/CMakeLists.txt
REM patch thirdparty third_party/FP16/CMakeLists.txt:1
REM patch psimd third_party/psimd/CMakeLisLists.txt:1
REM patch third_party/googletest/CMakeLists.txt:4
REM patch third_party/googletest/googlemock/CMakeLists.txt:45
REM patch third_party/googletest/googletest/CMakeLists.txt:56
REM patch third_party/ittapi/CMakeLists.txt:7
REM patch third_party/onnx/CMakeLists.txt:2
REM patch third_party/foxi/CMakeLists.txt:2
REM patch third_party/ideep/mkl-dnn/third_party/oneDNN/CMakeLists.txt:17
REM patch third_party/fmt/CMakeLists.txt:1
REM patch aten/src/ATen/CMakeLists.txt:1
```

#  6 Build your Wheel with flags
```batch

@echo off
REM --- Load MSVC compiler environment ---
CALL "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build\vcvars64.bat"

REM --- Set PyTorch build environment variables ---
set TORCH_CUDA_ARCH_LIST=3.5
set CMAKE_ARGS=-DCMAKE_POLICY_VERSION_MINIMUM=3.5
set USE_CUDA=1
set USE_CUDNN=1
set USE_NINJA=1
set USE_CUPTI=0
set USE_KINETO=0

REM --- Go to your PyTorch source directory ---
cd /d C:\Users\%USERNAME%\source\pytorch

REM --- Kick off the build (PEP517 wheel builder, no isolation) ---
python -m build --wheel --no-isolation

REM --- Cleanup (wheel is in /dist)---
rmdir /s /q build

pause

```


# 🎉 Congratulations!
You now have a fully native Windows build of PyTorch for Kepler GPUs—and a portable wheel you can install anywhere. Feel free to tweak flags to suit other architectures, CPU features, or profiling needs. Enjoy!


# Bonus: Rebuild with Different Flags
```batch
    No flags: autodetect defaults (all SM archs).

    View all flags:

python setup.py --help

Example: target multiple archs or disable AVX:

    set TORCH_CUDA_ARCH_LIST=3.5;5.0;6.1
    set USE_AVX=0
    set USE_FBGEMM=0
    python setup.py develop
```
