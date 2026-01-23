REM Mini Pytorch Builder 2.7.1 
REM thsi will throw aoti error, patch by updating wheel install with 3 files (or use pre built ones)


@echo off
setlocal EnableDelayedExpansion

REM 1: Initialize Paths
REM ===============================
set "SRC_DIR=C:\Users\%USERNAME%\source\271\pytorch"

REM A: Call builders
call "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build\vcvars64.bat" x64

REM B: Initialize CUDA 
set PATH=C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v11.7\bin;%PATH%
set LIB=C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v11.7\lib\x64;%LIB%
set INCLUDE=C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v11.7\include;%INCLUDE%


REM 2: Enter Source and Build Wheel
REM ===============================
pushd "%SRC_DIR%" || (
    echo ERROR: Failed to enter %SRC_DIR%
    exit /b 1
)

REM Build Options (mkl buggy, change to your cc desired version) 
set USE_MKLDNN=1
set USE_CUDNN=1
set "TORCH_CUDA_ARCH_LIST=3.5"
python -m build --wheel --no-isolation


REM ===== Cleanup =====
popd
endlocal
exit /b 0
