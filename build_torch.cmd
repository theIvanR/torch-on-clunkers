@echo off
setlocal

REM --- User configuration (optionally pass pytorch dir as first argument) ---
set "DEFAULT_SRC_DIR=C:\Users\%USERNAME%\source\pytorch"

if "%~1"=="" (
    set "SRC_DIR=%DEFAULT_SRC_DIR%"
) else (
    set "SRC_DIR=%~1"
)

if not exist "%SRC_DIR%" (
    echo [ERROR] Source directory "%SRC_DIR%" does not exist.
    exit /b 1
)

pushd "%SRC_DIR%" >nul 2>&1 || (
    echo [ERROR] Failed to enter "%SRC_DIR%".
    exit /b 1
)


REM -------------------------
REM Build flags / options
REM -------------------------
set "BUILD_DIR=build"
set "KEEP_BUILD=0"

set "CL=/bigobj %CL% /Ot /fp:fast"

REM ======
set "CUDA_ROOT=C:/Program Files/NVIDIA GPU Computing Toolkit/CUDA/v11.4"
set "CUDNN_ROOT=C:/Program Files/NVIDIA GPU Computing Toolkit/CUDNN/cudnn-windows-x86_64-8.7.0.84_cuda11-archive"
set "TORCH_CUDA_ARCH_LIST=3.5;3.7;5.0;5.2;6.0;6.1;7.0;7.5"


REM === Intel MKL Flags ===
set USE_MKL=1
set BLAS=MKL
set MKL_THREADING=SEQUENTIAL

REM --- Make MKL visible ---
set "MKLROOT=C:\Program Files (x86)\Intel\oneAPI\mkl\latest"
set "MKL_INCLUDE_DIR=%MKLROOT%\include"
set "MKL_LIBRARY_DIR=%MKLROOT%\lib\intel64"

REM Add runtime DLLs to PATH (important)
set "PATH=%MKLROOT%\redist\intel64;%PATH%"

REM Ensure CMake can find MKL
if defined CMAKE_PREFIX_PATH (
    set "CMAKE_PREFIX_PATH=%MKLROOT%;%CMAKE_PREFIX_PATH%"
) else (
    set "CMAKE_PREFIX_PATH=%MKLROOT%"
)


REM ======
set USE_DISTRIBUTED=OFF
set USE_TENSORPIPE=OFF


if exist "%BUILD_DIR%" (
    if "%KEEP_BUILD%"=="1" (
        echo [INFO] Keeping existing build directory "%BUILD_DIR%".
    ) else (
        echo [INFO] Removing old build directory "%BUILD_DIR%"...
        rmdir /s /q "%BUILD_DIR%"
        if errorlevel 1 (
            echo [ERROR] Failed to remove "%BUILD_DIR%".
            popd
            pause
            exit /b 1
        )
    )
)

REM ================================
REM 0: CMake Arguments (pass as command line)

set CMAKE_ARGS=^
    -DCMAKE_BUILD_TYPE=Release ^
    -G "Ninja" ^
    -DUSE_CUDA=ON ^
    -DUSE_CUDNN=ON ^
    -DCUDA_TOOLKIT_ROOT_DIR="%CUDA_ROOT%" ^
    -DCUDNN_ROOT="%CUDNN_ROOT%" ^
    -DTORCH_CUDA_ARCH_LIST=%TORCH_CUDA_ARCH_LIST% ^
    -DUSE_MKL=ON ^
    -DUSE_MKLDNN=ON ^
    -DBLAS=MKL ^
    -DMKL_ROOT="%MKLROOT%" ^
    -DMKL_INCLUDE_DIR="%MKL_INCLUDE_DIR%" ^
    -DMKL_LIBRARY_DIR="%MKL_LIBRARY_DIR%" ^
    -DCMAKE_PREFIX_PATH="%CMAKE_PREFIX_PATH%"

REM ================================

REM -------------------------
REM 0.5: Configure CMake into the build dir
echo [INFO] Configuring cmake into "%BUILD_DIR%"...
cmake -S . -B "%BUILD_DIR%" %CMAKE_ARGS%
if errorlevel 1 (
    echo [ERROR] CMake configuration failed.
    popd
    pause
    exit /b 1
)

REM -------------------------
REM 1: Build Torch Binaries
echo [INFO] Building (cmake --build "%BUILD_DIR%")...
cmake --build "%BUILD_DIR%" --parallel %NUMBER_OF_PROCESSORS% --verbose
if errorlevel 1 (
    echo [ERROR] Build failed.
    popd
    pause
    exit /b 1
)

REM 2: Install (built) Torch Binaries (equivalent to ninja install)
echo [INFO] Installing into prefix (cmake --build --target install)...
cmake --build "%BUILD_DIR%" --config Release --target install --parallel %NUMBER_OF_PROCESSORS%
if errorlevel 1 (
    echo [ERROR] Install step failed.
    popd
    pause
    exit /b 1
)

REM 3: Package the built Torch wheel from repository root
REM We are already in the repository root (SRC_DIR), no need to change dirs.
set DISTUTILS_USE_SDK=1
echo [INFO] Building Python wheel...
python setup.py bdist_wheel
if errorlevel 1 (
    echo [ERROR] Wheel build failed.
    popd
    pause
    exit /b 1
)

echo [SUCCESS] Wheel built successfully.

popd  REM back to original directory
exit /b 0
