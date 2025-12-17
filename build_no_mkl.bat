@echo off
REM ================================
REM PyTorch 2.x Windows Build Script
REM Python 3.10 | CUDA + OpenBLAS
REM ================================

REM --- Load MSVC Compiler Environment (x64) ---
CALL "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build\vcvars64.bat"

REM --- Go to PyTorch Source Directory ---
cd /d C:\Users\%USERNAME%\source\pytorch

REM ================================
REM CUDA / GPU Flags
REM ================================
set USE_CUDA=1
set USE_CUDNN=1
set TORCH_CUDA_ARCH_LIST=3.5;3.7;5.0;5.2;6.0;6.1;7.0;7.5

REM ================================
REM Build / Optional Features
REM ================================
set CL=/bigobj %CL% /O2
set USE_DISTRIBUTED=OFF
set USE_TENSORPIPE=OFF


REM ================================
REM CMake Arguments (pass as command line)
REM ================================
set CMAKE_ARGS=^
	-DUSE_CUDA=ON ^ 
	-DUSE_CUDNN=ON ^ 
	-DTORCH_CUDA_ARCH_LIST=3.5;3.7;5.0;5.2;6.0;6.1;7.0;7.5 ^ 
	-DCMAKE_BUILD_TYPE=Release ^ 
	-GNinja

REM ================================
REM Build PyTorch Wheel and cleanup (old, try new one)
REM ================================
REM python -m build --wheel --no-isolation --config-setting "CMAKE_ARGS=%CMAKE_ARGS%"
REM rmdir /s /q build



REM ================================
REM Build Wheel with manual control
REM ================================

REM --- Build the wheel Build ---
ninja -v
ninja install

REM --- Package: build wheel from repository root ---
cd .. 
set DISTUTILS_USE_SDK=1
python setup.py bdist_wheel
REM rmdir /s /q build


pause
