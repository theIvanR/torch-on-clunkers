# 🏗️ PyTorch on Windows for Older GPUS (Kepler +)
- **Goal:** Run PyTorch on Windows with Kepler GPUs (Tesla K40c, compute capability **3.5**).  
- **Stack:** Pytorch **2.0.1, 2.7.1**, CUDA **11.4.4**, cuDNN **8.7.0**, Visual Studio **2019**, **Intel oneAPI**, **Python 3.9+**.  
- **Arch List** CUDA 3.5;3.7;5.0;5.2;6.0;6.1;7.0;7.5

# 0. Pre-Built Wheels: 
Before building from source, check if a *prebuilt wheel is available for your setup*. I recommend using 2.0.1 as this is the stable and well tested wheel for all arches. 2.7.1 wheel is currently a WIP and I am in active contact with pytorch developers in order to improve the wheel. 

Requirements for Wheels: 
- Cuda driver >470 and CC>= 35
- python

---


High Performance Wheels: (MKL + MKLDNN + CUDNN + AVX1)
| PyTorch Version | Python | CUDA | Wheel |
|-----------------|--------|------|-------|
| 2.7.1 (cc35 only, all arches coming soon)         | 3.11    | 11.4.4 + | [Download wheel](https://drive.google.com/file/d/1YBPlySOl2JjvLDBF1kGnbk9K6R7jXqJi/view?usp=sharing)|
| 2.0.1 (all arches)          | 3.11    | 11.4.4 + | [Download wheel](https://drive.google.com/file/d/1QM96tc8GB9YP7rgt7_wzMhN0rl5H0z8F/view?usp=sharing)|

NOTE: to run 2.0.1 wheel, copy zlibwapi into your environment

NOTE: to run the 2.7.1 wheel, in addition to zlibwapi copy cupti64_2022 dll into the torch\lib folder as: 
```
loading "C:\Users\Admin\miniconda3\envs\py311_pt271\Lib\site-packages\torch\lib\aoti_custom_ops.dll"
```

To Build wheels consult specific files

---
# Notes on building pytorch 2.7.1 on kepler: 
- Use cuda 11.7 toolkit (NOTE, DO NOT install driver, only toolkit as driver no longer supports k40 gpu)
- install dependencies.txt as well as build with pip from pytorch folder. 
- run builder inside of folder 271 



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

##CUDNN IS BROKEN
