#!/bin/bash

if [ "$EUID" -ne 0 ]
then echo "Please run as root"
	exit
fi

echo
echo "UPDATING"
echo

apt update

echo
echo "INSTALLING ARIA2C"
echo
echo "y" | apt install aria2

echo
echo "INSTALLING GCC"
echo
echo "y" | apt-get install build-essential


echo
echo "INSTALLING PYTHON-PIP"
echo
echo "y" | apt-get install python3-pip

echo
echo "INSTALLING PSUTIL"
echo
echo "y" | pip3 install psutil

echo
echo "INSTALLING NET-TOOLS"
echo
echo "y" | apt install net-tools

echo
echo "INSTALLING TCPREPLAY"
echo
echo "y" | apt-get install tcpreplay

echo
echo "INSTALLING D-ITG"
echo
echo "y" | apt install d-itg

echo
echo "INSTALLING GIT"
echo
echo "y" | apt install git

echo
echo "INSTALLING TMUX"
echo
echo "y" | apt-get install tmux

echo
echo "INSTALLING MEGA CLI"
echo
echo "y" | apt-get install megatools

rm -rf NetworkWrapper
git clone https://sandia-proj:SandiaProj12345!@github.com/sandia-proj/NetworkWrapper.git

rm -rf ~/.megarc
touch ~/.megarc
echo "[Login]
      Username = sandiaprojpcaps@gmail.com
      Password = SandiaProj12345!" > ~/.megarc

megacopy --download --local NetworkWrapper/src/src_pcaps --remote /PCAPs/


#aria2c -x10 http://traffic.comics.unina.it/software/ITG/codice/D-ITG-2.8.1-r1023-src.zip
#unzip D-ITG-2.8.1-r1023-src.zip
#rm D-ITG-2.8.1-r1023-src.zip
#cd D-ITG-2.8.1-r1023/src
#make
#aria2c -x10 https://drive.google.com/file/d/1x-z27BUGEh-0YfTOAlY3UmN3VWVRB5NG/view?usp=sharing
