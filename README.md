# 🏗️ PyTorch on Windows for Older GPUS (Kepler +)
- **Goal:** Run PyTorch on Windows with Kepler GPUs (Tesla K40c, compute capability **3.5**).  
- **Stack:** CUDA **11.4.4**, cuDNN **8.7.0**, Visual Studio **2019+**, **Intel oneAPI**, **Python 3.9+**.  

# 0. Pre-Built Wheels: 
Before building from source, check if a *prebuilt wheel is available for your setup*.

> Wheels are built for architectures: `TORCH_CUDA_ARCH_LIST = 3.5;3.7;5.0;5.2;6.0;6.1;7.0;7.5`.
> 
> Wheels are built for all cpu architectures (no AVX used) if you need specific CPU enhancements (eg AVX512) rebuild using instructions
---

High Performance Wheels: Python + MKL + CUDA
| PyTorch Version | Python | CUDA | Wheel |
|-----------------|--------|------|-------|
| 2.0.1          | 3.10    | 11.4.4 + | [Download wheel](https://drive.google.com/file/d/1a4A3hXzg_mEiN-GVh8tYBmak4L7HIIRH/view?usp=drive_link)|

(new wheels coming soon)

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
- Launch Terminal as Administrator

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

## 4.3 Building pytorch above 2.0.1? 
Signifficant changes have been made to architecture and more extensive patching requried. See below, coming soon. 

#  5. Build your Wheel with flags (via build_torch.bat)
Select for which system you want to build pytorch and act accordingly. Launch builder scripts as Admin in Terminal.
- If Intel based: use MKL builder
- Otherwise, stick to openBLAS


🎉 Congratulations! You now have a fully native Windows build of PyTorch for Kepler GPUs—and a portable wheel you can install anywhere. Feel free to tweak flags to suit other architectures, CPU features, or profiling needs. Enjoy!


# Building Newer Versions of Torch (>2.0.1) 
*MASSIVE DUMPSTERFIRE* on windows, coming soon, 
