@echo off
REM ================================
REM PyTorch 2.x Windows Build Script
REM Python 3.10 | CUDA + MKL + oneDNN
REM ================================

REM --- Load MSVC Compiler Environment (x64) ---
CALL "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build\vcvars64.bat"

REM --- Go to PyTorch Source Directory ---
cd /d C:\Users\%USERNAME%\source\pytorch

REM --- Compiler flags (keep compiler-only flags here) ---
set CL=/bigobj %CL% /O2
set "TORCH_CUDA_ARCH_LIST=3.5;3.7;5.0;5.2;6.0;6.1;7.0;7.5"

REM --- Optional feature flags ---
set USE_DISTRIBUTED=OFF
set USE_TENSORPIPE=OFF

REM --- Make MKL visible (adjust path if necessary) ---
set "MKLROOT=C:\Program Files (x86)\Intel\oneAPI\mkl\latest"
set "INTEL_MKL_DIR=%MKLROOT%"

REM Add MKL runtime DLLs to PATH
set "PATH=%MKLROOT%\redist\intel64;%MKLROOT%\bin;%PATH%"

REM Ensure CMake searches MKL root for packages
if defined CMAKE_PREFIX_PATH (
  set "CMAKE_PREFIX_PATH=%MKLROOT%;%MKLROOT%\lib;%CMAKE_PREFIX_PATH%"
) else (
  set "CMAKE_PREFIX_PATH=%MKLROOT%;%MKLROOT%\lib"
)

REM Explicit MKL include/lib hints (help FindMKL.cmake)
set "MKL_INCLUDE_DIR=%MKLROOT%\include"
set "MKL_LIBRARY_DIR=%MKLROOT%\lib"

REM --- Make/build directory and run CMake from there ---
if exist build rmdir /s /q build
mkdir build
cd build

cmake .. -G "Ninja" ^
  -DUSE_CUDA=ON ^
  -DUSE_CUDNN=ON ^
  -DUSE_MKL=ON ^
  -DBLAS=MKL ^
  -DUSE_MKLDNN=ON ^
  -DMKL_ROOT="%MKLROOT%" ^
  -DINTEL_MKL_DIR="%INTEL_MKL_DIR%" ^
  -DCMAKE_PREFIX_PATH="%CMAKE_PREFIX_PATH%" ^
  -DMKL_INCLUDE_DIR="%MKL_INCLUDE_DIR%" ^
  -DMKL_LIBRARY_DIR="%MKL_LIBRARY_DIR%" ^
  -DTORCH_CUDA_ARCH_LIST="3.5;3.7;5.0;5.2;6.0;6.1;7.0;7.5" ^
  -DCMAKE_BUILD_TYPE=Release


REM --- Build the wheel Build ---
ninja -v
ninja install

REM --- Package: build wheel from repository root ---
cd .. 
set DISTUTILS_USE_SDK=1
python setup.py bdist_wheel

REM --- Cleanup ---
REM rmdir /s /q build

pause
