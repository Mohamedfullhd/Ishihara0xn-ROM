sudo apt update
sudo apt install build-essential git cmake
git clone https://android.googlesource.com/platform/system/tools
cd tools/lpmake
g++ -std=c++17 -o lpunpack lpunpack.cpp
sudo mv lpunpack /usr/local/bin/
cd ../..
