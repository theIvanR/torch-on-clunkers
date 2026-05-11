@echo off
setlocal EnableExtensions

REM Initialize v142 x64 builder (2019)
call "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvarsall.bat" x64 -vcvars_ver=14.29

REM Initialize oneAPI (MUST BE AT TOP, NVIDIA breaks it)
call "C:\Program Files (x86)\Intel\oneAPI\2025.3\oneapi-vars.bat"


REM Test build cuda and cudnn
nvcc test_cuda_sm35.cu ^
  -o test_cuda_sm35.exe ^
  -Wno-deprecated-gpu-targets ^
  -arch=sm_35 ^
  -I "C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v11.8\include" ^
  -L "C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v11.8\lib\x64" ^
  -lcudnn -lcudart
 
 test_cuda_sm35.exe
 
 
 icx test_icx.cpp -o test_icx.exe
 
 test_icx.exe
 
 
del test_cuda_sm35.exe
del test_icx.exe
pause