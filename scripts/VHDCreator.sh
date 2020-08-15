#!/bin/bash

# Check if Root User or not
if [ "$EUID" -ne 0 ]
then echo "Please run as root"
	exit
fi


echo "Please specify the number of VHDs:"
read numOfVMs

while ! [[ "$numOfVMs" =~ ^[0-9]+$ ]]; do
  echo "Invalid input. Please try again!"
  echo
  echo "Please specify the number of VHDs:"
  read numOfVMs
done

echo "Please specify the Virtual Hard Disk Size in Bytes:"
echo "The minimum recommended size is 30720 bytes i.e. 30gb"

read vhdsize

while ! [[ "$vhdsize" =~ ^[0-9]+$ ]]; do
  echo "Invalid input. Please try again!"
  echo
  echo "Please specify the Virtual Hard Disk Size in Bytes:"
  read vhdsize
done

echo "Please specify the prefix name for the VHDs. Forexample, if you specify \"apple\", the VHDs will be named apple1, apple2 ..."
read name

while [[ -z "$name" ]]; do
  echo "The prefix can't be empty. Please try again!"
  echo
  echo "Please specify the prefix name for the VHDs. Forexample, if you specify \"apple\", the VHDs will be named apple1, apple2 ..."
  read name
done

echo "Please specify the path to directory to store the VHDs"
read path

while ! [[ -d $path ]]; do
  echo "Invalid directory. Please try again!"
  echo
  echo "Please specify the path to directory to store the VHDs"
  read path
done

echo
echo

# Print the configuration
echo "Configuration:"
echo "No. of VMs: $numOfVMs"
echo "Size of each VHD: $vhdsize bytes"
echo "Prefix for VHD: $name" 

cd $path

echo
echo 

# Create the VHDs
for (( i=1; i <= $numOfVMs; i++ ))
do
	str=$(echo $name$i)
	echo "Creating Virtual Hard Disk of Size $vhdsize bytes named $str"
	dd if=/dev/zero of=$str.img bs=1M count=$vhdsize
	mkfs -t ext4 $str.img
	mkdir /mnt/$str/
	mount -t auto -o loop $str.img /mnt/$str
done
echo
echo "The VHDs were created in $path"

