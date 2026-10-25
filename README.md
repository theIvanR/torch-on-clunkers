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
| Target architectures | 35, 37, 50, 52, 53, 60, 61, 62, 70, 72, 75, 80, 86, 87, 89, 90 |

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
2. Run `pt_builder.cmd` for the minimal configuration, or the full build script for distributed support and Intel MKL integration.
3. Adjust the build flags as required.

The CUDA architecture list is controlled by `TORCH_CUDA_ARCH_LIST`. For example:

```bat
set "TORCH_CUDA_ARCH_LIST=3.5;3.7;5.0;5.2;6.0;6.1;7.0;7.5"
```

For a Tesla K40c-only build, use `3.5` to reduce compilation time.

The full build enables distributed support and Intel CPU libraries. Actual backend availability depends on successful configuration, compilation, and runtime testing.

### Kineto / CUPTI

Kineto is disabled in the recommended build configuration:

```bat
set "USE_KINETO=0"
```

Enabling it can introduce additional CUDA profiling dependencies, including CUPTI. If DLL loading fails, inspect the missing dependency and verify that the toolkit, driver, and profiling libraries are compatible before adding DLLs manually.

A successful build should produce a wheel similar to:

```text
Successfully built torch-2.7.1a0+gite2d141c-cp311-cp311-win_amd64.whl
```

The exact version suffix depends on the source revision.

## 6. Install and test

Install the generated wheel from the PyTorch `dist` directory:

```bat
pip install dist\torch-*.whl
```

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

## 7. Rebuilding and troubleshooting

- **Preserve build artifacts** when resuming an interrupted build. Delete build directories only when a clean rebuild is necessary.
- **Change one flag at a time** when troubleshooting configuration or linking failures.
- Inspect CMake output to confirm that CUDA, MKL, oneDNN, and distributed backends were actually detected.
- Use a DLL dependency inspection tool to investigate missing runtime dependencies.
- If an error mentions `zlibwapi.dll`, identify which component requires it and make the DLL available through an appropriate application or environment directory.
- Verify the final wheel in the intended Conda environment rather than relying on a successful compilation alone.

The build is successful only when the wheel installs and the required GPU, CPU, and distributed functionality works at runtime.
