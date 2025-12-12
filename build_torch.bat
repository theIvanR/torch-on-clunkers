@echo off
REM Load MSVC compiler environment and go to directory
CALL "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build\vcvars64.bat"
cd /d C:\Users\%USERNAME%\source\pytorch


REM Flags: CUDA
set USE_CUDA=1
set USE_CUDNN=1
REM set TORCH_CUDA_ARCH_LIST=3.5
set TORCH_CUDA_ARCH_LIST=3.5;3.7;5.0;5.2;5.3;6.0;6.1;6.2;7.0;7.2;7.5

REM Flags: Build, Primary (cmake version and performance build, 02 vs 0d and enable big files)
set CL=/bigobj %CL% /O2
set CMAKE_ARGS=-DCMAKE_POLICY_VERSION_MINIMUM=3.5 -DCMAKE_BUILD_TYPE=Release

REM Flags: Build, Secondary
set USE_NINJA=1
set USE_CUPTI=0
set USE_KINETO=0

REM Flags: Internal, windows single device specific 
set USE_DISTRIBUTED=OFF
set USE_TENSORPIPE=OFF

REM Build (PEP517 wheel builder, no isolation)
python -m build --wheel --no-isolation

REM ### (possible)Failure Condition 1 (cmake flags) ###
REM use patch the setuptools thingy for msvc (github)

REM ### (possible)Failure Condition 2 (cmake flags) ###
REM use patch_cmake_minimum.py (first with dry run to fix)


REM Cleanup (wheel is in /dist)
rmdir /s /q build

pause
