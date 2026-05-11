REM 0: Inside Source directory? 
REM 1: Inside correct anaconda? 
pause 

@echo off
setlocal EnableExtensions
  
REM 0) Initialize v142 compatible
call "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvarsall.bat" x64 -vcvars_ver=14.29
  
REM 1) Set Tool Paths for nvidia
set "CUDA_PATH=C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v11.8"
set "PATH=%CUDA_PATH%\bin;%PATH%" 

REM 2) Optional: set tool path for oneAPI if needed
  
python -m pip install -U build
  
cd /d C:\Users\%USERNAME%\source\pytorch
  
set "USE_CUDA=1"
set "USE_CUDNN=1"
set "USE_KINETO=0"
set "USE_MKLDNN=1"
  
set "TORCH_CUDA_ARCH_LIST=3.5"
  
python -m build --wheel --no-isolation
endlocal