REM ================================
REM PyTorch 2.x Windows Build Script
REM Python 3.10 | CUDA + MKL + oneDNN
REM ================================

@echo off
REM --- Load MSVC Compiler Environment (x64) ---
CALL "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build\vcvars64.bat"

REM --- Go to PyTorch Source Directory ---
cd /d C:\Users\%USERNAME%\source\pytorch


REM CPU Optimization Flags
REM ================================
set USE_MKL=1          REM Enable Intel MKL for CPU linear algebra
set USE_MKLDNN=1       REM Enable oneDNN (MKL-DNN) optimized kernels
set USE_BLAS=mkl       REM Explicitly use MKL as BLAS backend


REM CUDA / GPU Flags (select what you want/have)
REM ================================
set USE_CUDA=1          REM Enable CUDA support
set USE_CUDNN=1         REM Enable cuDNN support
set TORCH_CUDA_ARCH_LIST=3.5;3.7;5.0;5.2;6.0;6.1;7.0;7.5
REM set TORCH_CUDA_ARCH_LIST=3.5


REM Internal / Optional Features
REM ================================
set USE_DISTRIBUTED=OFF   REM Disable distributed training
set USE_TENSORPIPE=OFF    REM Disable TensorPipe


REM Build / Compilation Flags
REM ================================
set USE_NINJA=1        REM Use Ninja build system for speed
set USE_CUPTI=0        REM Disable CUPTI (optional, only for profiling)
set USE_KINETO=0       REM Disable Kineto (optional, profiling tool)

REM Compiler optimization flags
set CL=/bigobj %CL% /O2

REM CMake build arguments
set CMAKE_ARGS=-DCMAKE_POLICY_VERSION_MINIMUM=3.5 -DCMAKE_BUILD_TYPE=Release


REM Build PyTorch Wheel and Clean up
REM ================================
python -m build --wheel --no-isolation
rmdir /s /q build

pause
