@echo off
setlocal EnableExtensions

REM ============================================================
REM 0. Verify the correct Conda environment is active
REM ============================================================
if not defined CONDA_PREFIX (
    echo ERROR: No Conda environment is active.
    echo Activate the correct Anaconda environment first.
    exit /b 1
)

echo Conda environment: %CONDA_PREFIX%

REM ============================================================
REM 1. Initialize MSVC v142-compatible toolchain
REM ============================================================
call "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build\vcvarsall.bat" x64
if errorlevel 1 exit /b 1


REM ============================================================
REM 1B. Configure oneMKL paths only — no oneAPI setvars
REM ============================================================
set "ONEAPI_ROOT=C:\Program Files (x86)\Intel\oneAPI"
set "MKLROOT=%ONEAPI_ROOT%\mkl\latest"

if not exist "%MKLROOT%\include\mkl.h" goto :mkl_not_found

set "INCLUDE=%MKLROOT%\include;%INCLUDE%"
set "LIB=%MKLROOT%\lib;%LIB%"
set "PATH=%MKLROOT%\bin;%PATH%"

echo oneMKL configured.
echo MKLROOT=%MKLROOT%
where cl
where python
goto :mkl_done

:mkl_not_found
echo ERROR: oneMKL headers not found.
echo Checked: "%MKLROOT%\include\mkl.h"
exit /b 1

:mkl_done


REM ============================================================
REM 2. Native Windows libuv (Conda) for use distributed flag
REM ============================================================
set "libuv_ROOT=%CONDA_PREFIX%\Library"

if not exist "%libuv_ROOT%\include\uv.h" (
    echo ERROR: libuv header not found: "%libuv_ROOT%\include\uv.h"
    exit /b 1
)

if not exist "%libuv_ROOT%\lib\uv.lib" (
    echo ERROR: libuv library not found: "%libuv_ROOT%\lib\uv.lib"
    exit /b 1
)

set "INCLUDE=%libuv_ROOT%\include;%INCLUDE%"
set "LIB=%libuv_ROOT%\lib;%LIB%"
set "PATH=%libuv_ROOT%\bin;%PATH%"

echo.
echo libuv_ROOT=%libuv_ROOT%
echo libuv headers and library found.
where cl
where python

REM ============================================================
REM 3. Build configuration
REM ============================================================
python -m pip install -U build

cd /d "%USERPROFILE%\source\pytorch"
if errorlevel 1 exit /b 1

REM set "MAX_JOBS=17"
set "USE_CUDA=1"
set "USE_CUDNN=1"
set "USE_DISTRIBUTED=1"
set "USE_KINETO=0"
set "USE_MKLDNN=1"
REM set "USE_MKL=1"
set "BLAS=MKL"
set "TORCH_CUDA_ARCH_LIST=3.5"

REM ============================================================
REM 4. Build PyTorch wheel
REM ============================================================
python -m build --wheel --no-isolation

endlocal
