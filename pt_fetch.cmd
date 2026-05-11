REM 0: Installed Environment Dependecies? 
REM 1: Inside Anaconda Test Environment for building (eg py311_dbg)? 
REM 2: Inside Source directory? 

git config --system core.longpaths true
git clone --recursive https://github.com/pytorch/pytorch.git --branch v2.7.1

cd pytorch
pip install -r requirements.txt