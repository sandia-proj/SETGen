#!/bin/bash

if [ "$EUID" -ne 0 ]
then echo "Please run as root"
	exit
fi
echo "Please specify the number of VHDs:"
read numOfVMs
echo "Please specify the Virtual Hard Disk Size in Bytes:"
read vhdsize
echo "Please specify the prefix name for the VHDs. Forexample, if you specify \"apple\", the VHDs will be named apple1, apple2 ..."
read name
echo "Please specify the path to directory to store the VHDs"
read path

echo
echo

echo "Configuration:"
echo "No. of VMs: $numOfVMs"
echo "Size of each VHD: $vhdsize bytes"
echo "Prefix for VHD: $name" 

cd $path
for (( i=1; i <= $numOfVMs; i++ ))
do
	str=$(echo $name$i)
	echo "Creating Virtual Hard Disk of Size $vhdsize bytes named $str"
	dd if=/dev/zero of=$str.img bs=1M count=$vhdsize
	mkfs -t ext4 $str.img
	mkdir /mnt/$str/
	mount -t auto -o loop $str.img /mnt/$str
done
echo "DONE"
echo "Thank you"
