#!/bin/bash

if [ "$EUID" -ne 0 ]
then echo "Please run as root"
	exit
fi
apt update
echo "y" | apt install aria2
echo "y" | apt-get install build-essential
echo "y" | apt-get install python3
echo "y" | apt-get install python3-pip
pip3 install psutil
apt install net-tools
apt-get install tcpreplay
apt install d-itg
#aria2c -x10 http://traffic.comics.unina.it/software/ITG/codice/D-ITG-2.8.1-r1023-src.zip
#unzip D-ITG-2.8.1-r1023-src.zip
#rm D-ITG-2.8.1-r1023-src.zip
#cd D-ITG-2.8.1-r1023/src
#make
#aria2c -x10 https://drive.google.com/file/d/1x-z27BUGEh-0YfTOAlY3UmN3VWVRB5NG/view?usp=sharing
