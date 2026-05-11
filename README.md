## 🏗️ Modern Pytorch on Kepler+ GPUS on Windows
- **Goal:** Run PyTorch on Windows with Kepler GPUs (Tesla K40c, compute capability **3.5**).  
- **Stack:** Pytorch **2.7.1**, CUDA **11.8**, cuDNN **8.7.0**, Visual Studio **2022**, **Intel oneAPI**, **Python 3.11**.  
- **Arch List** CUDA 3.5;3.7;5.0;5.2;6.0;6.1;7.0;7.5

## Pre Built Wheels, High Performance
| PyTorch Version | Python | CUDA | Wheel |
|-----------------|--------|------|-------|
| 2.7.1 (cc35 only, AVX2)         | 3.11    | 11.4.4 + | [Download wheel](https://drive.google.com/file/d/1ZEGXHUkDTZFxHzD-zMVJ1l1sJLvShiIe/view?usp=drive_link)|
| 2.0.1 (all arches, AVX)          | 3.11    | 11.4.4 + | [Download wheel](https://drive.google.com/file/d/1QM96tc8GB9YP7rgt7_wzMhN0rl5H0z8F/view?usp=sharing)|

NOTE: I recommend to also use the modded bios for kepler gpus to achieve higher performance. More infos in my other repository here: https://github.com/theIvanR/kepler-on-steroids

## 0: Set up environment
- git
- miniconda
- visual studio (any) supporting v142, recommended 2022 with backwards tool.
- oneAPI (latest)
- nvidia display driver 472.50
- nvidia cuda 11.8
- nvidia cudnn 8.7.0 (drag and drop into nvidia)

**Strongly recommended: run the debug environment script to test if install and toolkits work**
  
## 1: Set up environment
- open anaconda prompt (administrator) and create new environment for building
  ```bash
  conda create -n py311_debug python=3.11
  conda activate py311_debug
  ```
  
## 2: Fetch and Build
- run the pt_fetch.cmd script to fetch pytorch 2.7.1
- run the pt_builder.cmd script to build pytorch. (adjust as needed with your flags. NOTE: in this pytorch version kinetico causes a bug with cupti dll linking so if it is enabled it will need to be dropped in manually later. Play with Dependency Walker for more detail). When it finishes you will be greeted with:
```bash
Successfully built torch-2.7.1a0+gite2d141d-cp311-cp311-win_amd64.whl
```

kineto_note:
  USE_KINETO can introduce the CUDA profiling stack into the build, which may
  pull in CUPTI and related runtime dependencies. On Windows, that extra
  dependency chain can break DLL resolution if the CUDA toolkit, driver, or
  profiler-related libraries are not aligned. In practice, the issue is not
  usually "Kineto itself" but the additional profiling/runtime layers it
  enables.

## 3: Install Wheel and Enjoy!
- install wheel via pip from "pytorch/dist"
- test via: ```python -c "import torch; print('torch',torch.__version__,'cuda',torch.version.cuda,'ok',torch.cuda.is_available(),'devices',torch.cuda.device_count()); [print(i, torch.cuda.get_device_name(i)) for i in range(torch.cuda.device_count())]; print(torch.randn(2,2,device='cuda'))"```

## 4: Rebuilding and troubleshooting
- drop zlibwapi.dll if needed into the envs/your_python_directory if something needs it. 
- when rebuilding, recommended to delete all build artifacts (egg, /dist, and /build)
- troubleshoot one flag at a time and use Dependency Walker liberally, consult chatgpt and similar. 
