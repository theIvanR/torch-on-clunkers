# PyTorch on Kepler GPUs — Windows Build Guide

Build PyTorch 2.7.1 for legacy NVIDIA GPUs, including Kepler (Tesla K40c, compute capability 3.5), on Windows.

**Status:** Work in progress

## 1. Build configuration

| Component | Version / configuration |
|---|---|
| PyTorch | 2.7.1 |
| Python | 3.11 |
| CUDA Toolkit | 11.8 |
| cuDNN | 8.7.0 |
| Visual Studio | 2019 / MSVC v142 |
| Intel oneAPI | 2024.2.1.101 |
| NVIDIA driver | 472.50 |
| Target architectures | 3.5;3.7;5.2;6.0;6.1;7.0;7.2;7.5 |

The goal is to retain support for legacy GPU architectures while building a modern PyTorch stack on Windows.

## 2. Prebuilt wheels

*Work in progress — these builds do not include the optional libuv and Intel MKL integrations described in the full-build instructions below.*

| PyTorch | Python | CUDA compatibility | Build |
|---|---|---|---|
| 2.7.1 — all listed architectures, AVX2 | 3.11 | CUDA 11.4+ | [Download wheel](https://drive.google.com/file/d/1xQWKs356gO3Ys5SASgXLfhgCgmlro_2g/view?usp=drive_link) |
| 2.0.1 — all listed architectures, AVX | 3.11 | CUDA 11.4+ | [Download wheel](https://drive.google.com/file/d/1QM96tc8GB9YP7rgt7_wzMhN0rl5H0z8F/view?usp=sharing) |

**Note:** AVX and AVX2 are CPU instruction-set requirements, separate from GPU architecture support. Check compatibility with your CPU before installing a wheel.

For additional Kepler GPU performance modifications, see [Kepler on Steroids](https://github.com/theIvanR/kepler-on-steroids).

## 3. Prerequisites

Install the following components:

- Git
- Miniconda
- Visual Studio 2019 with the MSVC v142 C++ toolchain
- Intel oneAPI 2024.2.1.101
- NVIDIA driver 472.50
- CUDA Toolkit 11.8
- cuDNN 8.7.0

**Important:** For legacy NVIDIA driver compatibility, install the CUDA Toolkit without replacing your existing display driver. Verify that the installed CUDA toolkit, driver, and cuDNN combination is compatible before proceeding.

Install cuDNN into the appropriate CUDA directories according to its Windows installation instructions.

Run the environment diagnostic script before building to verify that the compiler, Python environment, CUDA toolkit, and GPU are detected correctly.

## 4. Create the build environment

Open an Anaconda Prompt and create a dedicated environment:

```bat
conda create -n py311_debug python=3.11
conda activate py311_debug
```

Install the Python dependencies:

```bat
pip install -r dependencies.txt
```

For native Windows distributed support, install libuv into the active environment:

```bat
conda install -c conda-forge libuv
```

The full build can then use the Conda environment's libuv headers, library, and DLLs.

## 5. Fetch and build PyTorch

From the repository containing the build scripts:

1. Run `pt_fetch.cmd` to fetch the PyTorch 2.7.1 source.
2. Run `pt_builder.cmd` for the full configuration with distributed support and Intel MKL integration.
3. Adjust the build flags as required.

The CUDA architecture list is controlled by `TORCH_CUDA_ARCH_LIST`. For example:

```bat
set "TORCH_CUDA_ARCH_LIST=3.5;3.7;5.0;5.2;6.0;6.1;7.0;7.5"
```

For a Tesla K40c-only build, use `3.5` to reduce compilation time.

### Notes on Build flags: 

- Kineto / CUPTI (always disabled), Enabling it can introduce additional CUDA profiling dependencies, including CUPTI. If DLL loading fails, inspect the missing dependency and verify that the toolkit, driver, and profiling libraries are compatible before adding DLLs manually.
- USE_OPENMP (disabled in mkl builds), enabling it causes a conflict with dependencies due to open mp being selected.

A successful build should produce a wheel similar to:

```text
Successfully built torch-2.7.1a0+gite2d141c-cp311-cp311-win_amd64.whl
```

The exact version suffix depends on the source revision.

## 6. Install the wheel

Install the generated wheel from the PyTorch `dist` directory:

```bat
pip install dist\torch-*.whl
```

## 7. Bundle Required Runtime Dependencies

After installing the wheel, ensure the following DLL dependencies are available at the specified locations. These are runtime dependencies requested by `aoti_custom_ops.dll`.

| DLL | Build configuration | Destination |
|---|---|---|
| `zlibwapi.dll` | All builds | Conda environment root: `%CONDA_PREFIX%` |
| `libiomp5md.dll` | Full builds | `%CONDA_PREFIX%\Lib\site-packages\torch\lib` |
| `mkl_intel_thread.2.dll` | Full builds | `%CONDA_PREFIX%\Lib\site-packages\torch\lib` |
| `uv.dll` | Full builds | `%CONDA_PREFIX%\Lib\site-packages\torch\lib` |
| `mkl_core.2.dll` | Full builds | `%CONDA_PREFIX%\Lib\site-packages\torch\lib` |
| `mkl_avx2.2.dll` | Full builds | `%CONDA_PREFIX%\Lib\site-packages\torch\lib` |

>note, instead of `mkl_avx2.2.dll` the file `mkl_def.2.dll` or `mkl_avx512.2.dll` can also be used and these are in the mkl bin folder, but as targets are avx 2 systems, these are not included

**Troubleshooting:** If a dependency is missing or fails to load, inspect the affected binary and its dependency tree using [Dependencies](https://github.com/lucasg/Dependencies/releases/tag/v1.11.1).


## 8 Test the built wheel

Verify CUDA availability and enumerate the detected GPUs:

```python
import torch

print("PyTorch:", torch.__version__)
print("CUDA:", torch.version.cuda)
print("CUDA available:", torch.cuda.is_available())
print("GPU count:", torch.cuda.device_count())

for i in range(torch.cuda.device_count()):
    print(i, torch.cuda.get_device_name(i))

print(torch.randn(2, 2, device="cuda"))
```

For builds with Intel CPU optimizations, check the compiled configuration:

```python
import torch

print(torch.__config__.show())
print("MKL:", torch.backends.mkl.is_available())
print("oneDNN:", torch.backends.mkldnn.is_available())
```

For distributed builds, additionally test process-group initialization and an actual collective operation.
