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

# 3. Configure environment variables

Open System Properties → Advanced → Environment Variables and add:

CUDA_PATH=C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v11.4

In your Path (User or System), ensure:

%CUDA_PATH%\bin
%CUDA_PATH%\lib\x64
C:\Path\To\Git\cmd
C:\Path\To\Python39\
C:\Path\To\Python39\Scripts\
C:\Path\To\ninja\

# 🌱 4. Clone & Prepare PyTorch
Goal: Get a clean, verified, specific snapshot of the PyTorch source code (and its submodules) on your system ready for a reproducible build.

## 0. Launch Compiler
- Launch x64 Native Tools Command Prompt for VS 2019

## 1. Go to your source directory
- '''cd C:\Users\<You>\source'''
- why: Keeps your work organized and avoids cluttering your system drive or Python/conda environments with source code.

## 2. Clone Directory from Git
-

    Launch x64 Native Tools Command Prompt for VS 2019

    Run:

    cd C:\Users\<You>\source
    git clone https://github.com/pytorch/pytorch.git
    cd pytorch

    # (Optional) Checkout a specific release:
    git fetch --all --tags
    git checkout v1.12.1

    # Avoid “unsafe repository” warnings:
    git config --global --add safe.directory C:/Users/<You>/source/pytorch

    # Init submodules:
    git submodule sync
    git submodule update --init --recursive

    Goal:

    
✅ git clone https://github.com/pytorch/pytorch.git

What:
Clones the full PyTorch GitHub repository to your local system.

Why:
You need the source code to build it. This includes the main repo plus the metadata for its submodules.

Result:
A pytorch directory appears inside your source folder containing the entire codebase.
✅ cd pytorch

What:
Move into the pytorch directory you just cloned.

Why:
All build commands and git operations happen from inside this directory.
✅ git fetch --all --tags

What:
Fetches all remote branches, tags, and refs from the PyTorch GitHub repository without actually changing your working directory.

Why:
So you can see and check out a specific stable release (like v1.12.1) instead of using whatever happened to be the latest unstable commit on main.
Tags mark official release versions.
✅ git checkout v1.12.1

What:
Switches your working directory to the exact commit that marks version 1.12.1 of PyTorch.

Why:
Ensures you’re building a known, tested, stable release, and not the moving target of the latest commits.
This is important for repeatable builds and compatibility with specific CUDA versions and hardware.

Heads-up:
You’ll enter detached HEAD state since you’re pointing to a specific commit rather than a branch. Totally fine for builds.
✅ git config --global --add safe.directory C:/Users/<You>/source/pytorch

What:
Tells Git to treat the pytorch folder as a safe directory for operations.

Why:
Newer versions of Git on Windows can throw “unsafe repository” warnings if you clone repos into certain system/user folders, as a security measure.
This command silences that by marking it explicitly as safe globally on your system.
✅ git submodule sync

What:
Resyncs your submodule config in .gitmodules with the URLs listed in your local git config.

Why:
Ensures if there were any changes to the submodule URLs or configs upstream, your local setup stays consistent.
✅ git submodule update --init --recursive

What:
Downloads and initializes all the required submodules for the repo.
PyTorch relies on several third-party libraries (like ATen, caffe2, third_party/kineto, etc.) which live inside the repo as git submodules.

Why:
If you don’t run this, those folders will either be empty or missing — causing your build to fail.

Options explained:

    --init → initializes any uninitialized submodules

    --recursive → goes into nested submodules inside submodules and updates those too (PyTorch has a few)

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
#  6. Set Build Flags

In the same VS prompt, before building:

set CUDA_PATH=C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v11.4
set TORCH_CUDA_ARCH_LIST=3.5       # sm_35 (Kepler)
set USE_CUDA=1                     # Enable CUDA
set USE_CUDNN=1                    # Enable cuDNN
set USE_NINJA=1                    # Use Ninja backend
set USE_CUPTI=0                    # Disable CUPTI profiling
set USE_KINETO=0                   # Disable Kineto tracing

    TORCH_CUDA_ARCH_LIST: which GPU archs to compile (e.g. 3.5;5.2;6.1)

    USE_NINJA: significant speed‐up vs. MSBuild

    USE_CUPTI/KINETO: disable for leaner build

# 7. Build in “Develop” Mode

rmdir /s /q build
del /q CMakeCache.txt
python setup.py develop

    Builds & installs in editable mode—edits reflect immediately.
    Time: 30 min–2 hrs (hardware‐dependent)

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
