# 🏗️ Build PyTorch from Source on Windows for Kepler GPUs

**Target hardware:** Tesla K40c / K80 (sm_35)  
**CUDA:** 11.4.4  
**cuDNN:** 8.7.0  
**Visual Studio:** 2019  
**Python:** 3.9  
**PyTorch version:** 1.12.x  

---

## 🔧 1. Tools & Why You Need Them

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

## ⚙️ 2. Install & Verify Prerequisites

1. **Visual Studio 2019**  
   - Install **Desktop development with C++** workload  
   - Confirm VC++ toolset v14.x is present  

2. **CUDA 11.4.4**  
   ```powershell
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


##🔧 3. Configure Environment Variables

Open System Properties → Advanced → Environment Variables and add:

CUDA_PATH=C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v11.4

In your Path (User or System), ensure:

%CUDA_PATH%\bin
%CUDA_PATH%\lib\x64
C:\Path\To\Git\cmd
C:\Path\To\Python39\
C:\Path\To\Python39\Scripts\
C:\Path\To\ninja\

🌱 4. Clone & Prepare PyTorch

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

🐍 5. Install Python Build Dependencies

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
🎛️ 6. Set Build Flags

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

🏗️ 7. Build in “Develop” Mode

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
