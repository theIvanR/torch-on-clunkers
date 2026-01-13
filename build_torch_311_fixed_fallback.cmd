REM Minimal Fixed Fallback Version 311 (change to yours in 2.5)
REM No XNNPACK, pure fallback test

@echo off
setlocal EnableExtensions EnableDelayedExpansion

REM ===============================
REM Set Paths
REM ===============================

REM 0: Clear Anything Stale Intel
REM ===============================
set CC=cl
set CXX=cl
set CMAKE_C_COMPILER=cl
set CMAKE_CXX_COMPILER=cl

set ONEAPI_ROOT=
set ICPP_COMPILER=
set ICX=
set ICC=


REM 1: Initialize MKL (properly)
REM ===============================
set "MKLROOT=C:\Program Files (x86)\Intel\oneAPI\mkl\latest"
set "CMAKE_PREFIX_PATH=%MKLROOT%"
set "LIB=%LIB%;%MKLROOT%\lib\intel64"
set "INCLUDE=%INCLUDE%;%MKLROOT%\include"
set "PATH=%PATH%;%MKLROOT%\bin"


REM 2: Initialize Cuda & CUDNN (inside it)
REM ===============================
set "CUDA_ROOT=C:/Program Files/NVIDIA GPU Computing Toolkit/CUDA/v11.4"


REM 3: Set Torch Paths
REM ===============================
set "SRC_DIR=C:/Users/%USERNAME%/source/pytorch"
set "TARGET_LIB=%SRC_DIR%/torch/lib"
set "BUILD_DIR=build"

pushd "%SRC_DIR%" || (
    echo [ERROR] Unable to enter %SRC_DIR%
    exit /b 1
)

REM Optional: RM Build, Dist, Staging Lib/DLL
REM if exist "%BUILD_DIR%" rmdir /s /q "%BUILD_DIR%"
REM if exist "%SRC_DIR%\dist" rmdir /s /q "%SRC_DIR%\dist"
REM if exist "%SRC_DIR%\torch\lib" rmdir /s /q "%SRC_DIR%\torch\lib"

REM ===============================
REM Configure Cmake for Pytorch
REM ===============================

REM set "CL=/bigobj %CL% /Ot /fp:fast"

REM 1: Configure Cmake
cmake -S . -B "%BUILD_DIR%" ^
    -G Ninja ^
    -DCMAKE_BUILD_TYPE=Release ^
    -DCMAKE_RUNTIME_OUTPUT_DIRECTORY="%TARGET_LIB%" ^
    -DCMAKE_LIBRARY_OUTPUT_DIRECTORY="%TARGET_LIB%" ^
    -DCMAKE_ARCHIVE_OUTPUT_DIRECTORY="%TARGET_LIB%" ^
    -DCUDA_TOOLKIT_ROOT_DIR="%CUDA_ROOT%" ^
    -DTORCH_CUDA_ARCH_LIST="3.5" ^
    -DUSE_CUDA=ON ^
    -DUSE_CUDNN=ON ^
    -DUSE_MKL=ON ^
    -DBLAS=MKL ^
    -DUSE_XNNPACK=OFF ^
    -DUSE_DISTRIBUTED=OFF ^
    -DUSE_TENSORPIPE=OFF

REM 2: Launch Builder
cmake --build "%BUILD_DIR%" -- -j %NUMBER_OF_PROCESSORS%


REM 2.5 Patch linker "feature" on windows (\pytorch\build\lib\ -copy-> \pytorch\torch\lib\)
REM ===========================================================================

REM Ensure target lib dir exists
if not exist "%TARGET_LIB%" mkdir "%TARGET_LIB%"

REM Try canonical install first (preferred)
echo [INFO] Running cmake --install to stage artifacts into "%SRC_DIR%\torch"
cmake --install "%BUILD_DIR%" --prefix "%SRC_DIR%\torch" || (
    echo [WARN] cmake --install failed or is incomplete; falling back to explicit copy
    REM copy DLLs and PYDs from the build staging locations into torch\lib
    REM Use robocopy for robustness (handles long paths, many files)
    if exist "%SRC_DIR%\build\lib.win-amd64-cpython-311\torch\lib" (
        robocopy "%SRC_DIR%\build\lib.win-amd64-cpython-311\torch\lib" "%TARGET_LIB%" *.dll *.pyd /MOV /E /NFL /NDL /NJH /NJS
    )
    if exist "%SRC_DIR%\build\bin" (
        robocopy "%SRC_DIR%\build\bin" "%TARGET_LIB%" *.dll /MOV /E /NFL /NDL /NJH /NJS
    )
)

REM Extra safety: also copy any leftover DLLs (non-moving) if robocopy did not run
if exist "%SRC_DIR%\build\lib.win-amd64-cpython-311\torch\lib" (
    xcopy "%SRC_DIR%\build\lib.win-amd64-cpython-311\torch\lib\*.dll" "%TARGET_LIB%\" /Y /I /Q
    xcopy "%SRC_DIR%\build\lib.win-amd64-cpython-311\torch\lib\*.pyd" "%TARGET_LIB%\" /Y /I /Q
)
if exist "%SRC_DIR%\build\bin\*.dll" (
    xcopy "%SRC_DIR%\build\bin\*.dll" "%TARGET_LIB%\" /Y /I /Q
)

REM Verify critical CUDA/artifact presence
if not exist "%TARGET_LIB%\torch_cuda.dll" (
    echo [ERROR] torch_cuda.dll not found in "%TARGET_LIB%". Build may not have produced CUDA artifacts.
    echo [INFO] Listing build lib contents for diagnosis:
    dir "%SRC_DIR%\build\lib.win-amd64-cpython-311\torch\lib\*.dll" /b
    exit /b 1
)

if not exist "%TARGET_LIB%\c10.dll" (
    echo [WARN] c10.dll not found in "%TARGET_LIB%". Continuing but this may cause runtime failures.
)

REM ===========================================================================


REM 3: Make Wheel and Celebrate
set DISTUTILS_USE_SDK=1
python setup.py bdist_wheel

REM Optional: Test Pytorch Import
REM python -c "import torch; print('torch', torch.__version__); print('cuda available:', torch.cuda.is_available())"


popd
echo.
echo ===== BUILD COMPLETE =====

exit /b 0
