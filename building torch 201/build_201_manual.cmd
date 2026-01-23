REM Robust Torch Builder for maximal wheel performance

REM Dont forget 1: 
REM call "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build\vcvars64.bat" x64
REM 2: copy zlibwapi to your python root eg to minconda/env/py311_pt201 or something
  
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
set "CUDA_PATH=C:/Program Files/NVIDIA GPU Computing Toolkit/CUDA/v11.4"
set "CMAKE_CUDA_COMPILER=%CUDA_PATH%/bin/nvcc.exe"
set "PATH=%CUDA_PATH%/bin;%PATH%"
set "INCLUDE=%CUDA_PATH%/include;%INCLUDE%"
set "LIB=%CUDA_PATH%/lib/x64;%LIB%"

REM 3: Set Torch Paths
REM ===============================
set "SRC_DIR=C:/Users/%USERNAME%/source/201/pytorch"
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
    -DCUDA_TOOLKIT_ROOT_DIR="%CUDA_PATH%" ^
	-DCMAKE_CUDA_COMPILER="%CUDA_PATH%/bin/nvcc.exe" ^
    -DCUDA_TOOLKIT_ROOT_DIR="%CUDA_PATH%" ^
    -DCMAKE_PREFIX_PATH="%CUDA_PATH%" ^
    -DTORCH_CUDA_ARCH_LIST="3.5;3.7;5.0;5.2;6.0;6.1;7.0;7.5" ^
    -DUSE_CUDA=ON ^
    -DUSE_CUDNN=ON ^
    -DUSE_MKL=ON ^
    -DBLAS=MKL ^
    -DUSE_XNNPACK=ON ^
    -DUSE_DISTRIBUTED=OFF ^
    -DUSE_TENSORPIPE=OFF

REM 2: Launch Builder
cmake --build "%BUILD_DIR%" -- -j %NUMBER_OF_PROCESSORS%


REM 2.5 Patch linker "feature" on windows (\pytorch\build\lib\ -> \pytorch\torch\lib\)
REM ===========================================================================
REM Ensure target lib dir exists
if not exist "%TARGET_LIB%" mkdir "%TARGET_LIB%"

REM --------------------------
REM Robust Python ABI token detection (produces "amd64-cpython-311")
REM --------------------------
echo [INFO] Detecting python toolchain token...
python -c "import sysconfig,sys; plat=sysconfig.get_platform(); soabi=sysconfig.get_config_var('SOABI') or ('cpython%d%d'%(sys.version_info[0],sys.version_info[1])); plat_suffix=plat.split('-',1)[1] if '-' in plat else plat; print(plat_suffix + '-' + soabi)" > "%TEMP%\py_toolchain.txt" 2>nul

set /p PY_TOOLCHAIN=<"%TEMP%\py_toolchain.txt" 2>nul
if exist "%TEMP%\py_toolchain.txt" del "%TEMP%\py_toolchain.txt" 2>nul

if not defined PY_TOOLCHAIN (
    echo [WARN] Failed to detect python toolchain token; defaulting to amd64-cpython-311
    set "PY_TOOLCHAIN=amd64-cpython-311"
)

echo [INFO] Detected python toolchain token: %PY_TOOLCHAIN%
set "BUILD_PY_LIB=%SRC_DIR%\build\lib.win-%PY_TOOLCHAIN%\torch\lib"
echo [INFO] Will copy from: "%BUILD_PY_LIB%"

REM --------------------------
REM Try canonical install first (preferred)
REM --------------------------
echo [INFO] Running cmake --install to stage artifacts into "%SRC_DIR%\torch"
cmake --install "%BUILD_DIR%" --prefix "%SRC_DIR%\torch"
if errorlevel 1 (
    echo [WARN] cmake --install failed or returned non-zero; falling back to explicit copy
    goto STAGING_FALLBACK
) else (
    echo [INFO] cmake --install succeeded
    goto STAGING_DONE
)

:STAGING_FALLBACK
REM copy DLLs and PYDs from the build staging locations into torch\lib
REM Use robocopy for robustness (handles long paths, many files)
if exist "%BUILD_PY_LIB%" (
    echo [INFO] robocopy "%BUILD_PY_LIB%" -> "%TARGET_LIB%"
    robocopy "%BUILD_PY_LIB%" "%TARGET_LIB%" *.dll *.pyd /MOV /E /NFL /NDL /NJH /NJS
) else (
    echo [WARN] Expected build lib folder "%BUILD_PY_LIB%" not found.
)

if exist "%SRC_DIR%\build\bin" (
    echo [INFO] robocopy "%SRC_DIR%\build\bin" -> "%TARGET_LIB%"
    robocopy "%SRC_DIR%\build\bin" "%TARGET_LIB%" *.dll /MOV /E /NFL /NDL /NJH /NJS
)

REM Extra safety: also copy any leftover DLLs/PYDs (non-moving) if robocopy did not run / missed files
if exist "%BUILD_PY_LIB%" (
    xcopy "%BUILD_PY_LIB%\*.dll" "%TARGET_LIB%\" /Y /I /Q
    xcopy "%BUILD_PY_LIB%\*.pyd" "%TARGET_LIB%\" /Y /I /Q
)
if exist "%SRC_DIR%\build\bin\*.dll" (
    xcopy "%SRC_DIR%\build\bin\*.dll" "%TARGET_LIB%\" /Y /I /Q
)

:STAGING_DONE
REM Verify critical CUDA/artifact presence
if not exist "%TARGET_LIB%\torch_cuda.dll" (
    echo [ERROR] torch_cuda.dll not found in "%TARGET_LIB%". Build may not have produced CUDA artifacts.
    echo [INFO] Listing build lib contents for diagnosis:
    if exist "%BUILD_PY_LIB%" (
        dir "%BUILD_PY_LIB%\*.dll" /b
    ) else (
        echo [INFO] Build lib folder "%BUILD_PY_LIB%" does not exist.
    )
    exit /b 1
)

if not exist "%TARGET_LIB%\c10.dll" (
    echo [WARN] c10.dll not found in "%TARGET_LIB%". Continuing but this may cause runtime failures.
)

echo [INFO] Staging complete.
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
