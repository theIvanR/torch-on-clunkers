🏗️ Build PyTorch from Source on Windows for Kepler GPUs

**Target hardware:** Tesla K40c / K80 (sm_35)  
**CUDA:** 11.4.4  
**cuDNN:** 8.7.0  
**Visual Studio:** 2019  
**Python:** 3.9  
**PyTorch version:** 1.12.x  

---

# 1. Tools & Why You Need Them

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

NOTE: for simplicity, I used miniconda with python 3.9 and added it to path. Of course, different settings and virtual environments can be used. 

---

# 2. Install & Verify Prerequisites

1. **Visual Studio 2019**  
   - Install **Desktop development with C++** workload  
   - Confirm VC++ toolset v14.x is present  

2. **CUDA 11.4.4**  
   ```powershell```
   nvcc --version

3. **cuDNN 8.7.0**

    Download for CUDA 11.x

    Copy bin, include, lib/x64 →
    C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v11.4\

4. **Python 3.9**

    Install from python.org, add to PATH

5. **Git**

    Install from git-scm.com, add to PATH

6. **CMake & Ninja**

    Download ninja.exe → add to PATH

    Install CMake via installer or pip install cmake

# 3. (Optional) Confirm Environment Variables
Ensure all are in environment variables
- Python (test 
- Cuda (test with nvcc --version)
- Ninja (test 
- Cmake (test 


# 4. Clone & Prepare PyTorch (of select version) from Github
- Goal: Get a clean, verified, specific snapshot of the PyTorch source code (and its submodules) on your system ready for a reproducible build.

## 4.0. Launch Compiler
- Launch x64 Native Tools Command Prompt for VS 2019

## 4.1. Go to your source directory
- ```cd C:\Users\<You>\source```
- what? 
- why? Keeps your work organized and avoids cluttering your system drive or Python/conda environments with source code.

## 4.2. Clone Directory from Git and go into it
- ```git clone https://github.com/pytorch/pytorch.git``` then proceed to cd into it with ```cd C:\Users\<You>\source\Pytorch```(or whatever name it makes)
- what? Clones the full PyTorch GitHub repository to your local system.
- why? You need the source code to build it. This includes the main repo plus the metadata for its submodules.


## 4.3. Checkout Release
- ```git fetch --all --tags``` and then run ```git checkout v1.12.1``` (or your select version)
- what? Fetches all remote branches, tags, and refs from the PyTorch GitHub repository without actually changing your working directory.
- why? So you can see and check out a specific stable release (like v1.12.1) instead of using whatever happened to be the latest unstable commit on main.
- NOTE: You’ll enter detached HEAD state since you’re pointing to a specific commit rather than a branch. Totally fine for builds.

## 4.4. 
- ```git config --global --add safe.directory C:/Users/<You>/source/pytorch```
- what? Tells Git to treat the pytorch folder as a safe directory for operations.
- why? Newer versions of Git on Windows can throw “unsafe repository” warnings if you clone repos into certain system/user folders, as a security measure.


## 4.5. 
- ```git submodule sync```
- what? Downloads and initializes all the required submodules for the repo.
- why? Ensures if there were any changes to the submodule URLs or configs upstream, your local setup stays consistent.

## 4.6. 
- ```git submodule update --init --recursive```
- what? Downloads and initializes all the required submodules for the repo. PyTorch relies on several third-party libraries (like ATen, caffe2, third_party/kineto, etc.) which live inside the repo as git submodules.
- why? If you don’t run this, those folders will either be empty or missing — causing your build to fail.


#  5. Install Python Build Dependencies

pip install --upgrade pip
pip install typing-extensions future six numpy pyyaml

🔧 5.1 Patch Windows VC-Vars Overlay

Why?
Newer setuptools moved _get_vc_env, so PyTorch’s original import fails on VS2019.

    Open tools/build_pytorch_libs.py

    Replace at top:

- from distutils import _msvccompiler
+ # modern setuptools relocation of _msvccompiler
+ from setuptools._distutils import _msvccompiler as distutils_msvccompiler

In _overlay_windows_vcvars, update:

    - vc_env: Dict[str, str] = distutils._msvccompiler._get_vc_env(vc_arch)
    + vc_env: Dict[str, str] = distutils_msvccompiler._get_vc_env(vc_arch)

Save—now builds will correctly find your VS2019 cl.exe.

# Set Build Flags

## 6.1 Critical Flags
Essential for building with CUDA support and optimizing build time.

```batch
set TORCH_CUDA_ARCH_LIST=3.5       :: sm_35 (Kepler) — adjust as needed
set USE_CUDA=1                     :: Enable CUDA
set USE_CUDNN=1                    :: Enable cuDNN
set USE_NINJA=1                    :: Use Ninja build backend
set USE_CUPTI=0                    :: Disable CUPTI profiling (leaner build)
set USE_KINETO=0                   :: Disable Kineto tracing (leaner build)
```
If using a different version of cuda then system default, set it with this: 
```batch 
set CUDA_PATH=C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v11.4
```

NOTE: if nothing is set aftet these the defaults will be set for your system. Recommended to leave as is, to check use ```set```

## 6.2 CPU Compile Flags
Enable or disable CPU instruction sets or backend optimizations here.
```batch
set BLAS=OpenBLAS                  :: Use OpenBLAS for linear algebra (can be MKL, Eigen, etc.)
```
NOTE SIMD already handled by this!

## 6.3 CPU Backend Flags (Highly Recommended to Disable)

Disabling these can significantly reduce build time and binary size if not needed.
   ```batch
   set USE_FBGEMM=0                   :: Disable quantized inference backend
   set USE_QNNPACK=0                  :: Disable mobile inference backend
   set USE_NNPACK=0                   :: Disable mobile CPU inference backend
   set USE_MKLDNN=0                   :: Disable MKL-DNN (oneDNN) backend
   ```

## 6.4 Windows-Specific & Optional Flags
-Additional settings to control distributed features, tests, and external libraries.

```batch
:: Distributed backends
set USE_DISTRIBUTED=0
set USE_TENSORPIPE=0
set USE_GLOO=0
set USE_MPI=0

:: Disable test builds
set BUILD_TEST=0

:: Disable Caffe2 framework (unless explicitly needed)
set BUILD_CAFFE2=0

:: Disable optional libraries
set USE_OPENMP=0
set USE_OPENCV=0
set USE_FFMPEG=0
set USE_REDIS=0
set USE_LEVELDB=0
set USE_LMDB=0
set USE_ZSTD=0

:: Disable additional binaries and prefer bundled libs
set BUILD_BINARY=0
set USE_SYSTEM_LIBS=0
```

# 7. Build in “Develop” Mode

- ```batch rmdir /s /q build```
— Recursively deletes the entire build directory, clearing all compiled artifacts from any previous builds.
- ```batch del /q CMakeCache.txt```
— Deletes the CMake cache file which stores previous build settings and paths.
- ```batch python setup.py develop```
— Compiles PyTorch and installs it in editable mode, linking your source tree directly into the Python environment.

```batch
Builds & installs in editable mode—edits reflect immediately.
Time: 30 min–2 hrs (hardware‐dependent)
```

✅ 8. Verify Your Build

Open a fresh PowerShell/CMD (outside the source dir):

python - << 'PYCODE'
import torch
print("Torch version:", torch.__version__)
print("CUDA available:", torch.cuda.is_available())
if torch.cuda.is_available():
    print("Device 0:", torch.cuda.get_device_name(0),
          torch.cuda.get_device_capability(0))
PYCODE

You should see sm_35 and your Tesla K40c listed.
📦 9. Produce a Portable Wheel

    Install PEP 517 builder (one-time):

pip install build

Generate wheel:

python -m build --wheel
# → dist/torch-*.whl

Install & verify:

    pip uninstall torch
    pip install dist\torch-*.whl

    The wheel lives in site-packages/torch; you can safely delete the .whl file afterward.

🔄 10. Rebuild with Different Flags

    No flags: autodetect defaults (all SM archs).

    View all flags:

python setup.py --help

Example: target multiple archs or disable AVX:

    set TORCH_CUDA_ARCH_LIST=3.5;5.0;6.1
    set USE_AVX=0
    set USE_FBGEMM=0
    python setup.py develop

🎉 Congratulations!
You now have a fully native Windows build of PyTorch for Kepler GPUs—and a portable wheel you can install anywhere. Feel free to tweak flags to suit other architectures, CPU features, or profiling needs. Enjoy!
