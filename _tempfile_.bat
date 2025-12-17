@echo off
REM ================================
REM PyTorch 2.x Windows Build Script
REM Python 3.10 | CUDA + MKL + oneDNN
REM ================================

REM --- Load MSVC Compiler Environment (x64) ---
CALL "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build\vcvars64.bat"

REM --- Go to PyTorch Source Directory ---
cd /d C:\Users\%USERNAME%\source\pytorch

REM ================================
REM CPU Optimization Flags
REM ================================
set USE_MKL=1
set USE_MKLDNN=1
set USE_BLAS=mkl

REM ================================
REM CUDA / GPU Flags
REM ================================
set USE_CUDA=1
set USE_CUDNN=1
set TORCH_CUDA_ARCH_LIST=3.5;3.7;5.0;5.2;6.0;6.1;7.0;7.5

REM ================================
REM Internal / Optional Features
REM ================================
set USE_DISTRIBUTED=OFF
set USE_TENSORPIPE=OFF

REM ================================
REM Build / Compilation Flags
REM ================================
set USE_NINJA=1
set USE_CUPTI=0
set USE_KINETO=0
set CL=/bigobj %CL% /O2

REM ================================
REM CMake Arguments (pass as command line)
REM ================================
set CMAKE_ARGS=-DUSE_CUDA=ON -DUSE_CUDNN=ON -DUSE_MKL=ON -DUSE_MKLDNN=ON -DBLAS=mkl -DTORCH_CUDA_ARCH_LIST="3.5;3.7;5.0;5.2;6.0;6.1;7.0;7.5" -DCMAKE_BUILD_TYPE=Release

REM ================================
REM Build PyTorch Wheel
REM ================================
python -m build --wheel --no-isolation --config-setting "CMAKE_ARGS=%CMAKE_ARGS%"

REM ================================
REM Cleanup
REM ================================
rmdir /s /q build
pause
