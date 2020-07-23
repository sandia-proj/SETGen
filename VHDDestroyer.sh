#!/bin/bash

if [ "$EUID" -ne 0 ]
then echo "Please run as root"
exit
fi

echo "Current Disk Stats:"
df
echo

echo "Please enter the prefix of VHDs:"
read name
echo "Please enter the number of VHDs:"
read num
echo "Please enter the starting point:"
echo "Forexample, if you specify 2, the script will delete prefix2, prefix3 and so on..."
read st
echo "Please enter the path to directory containing the VHDs:"
read path
cd $path
let en=num+st
echo

for (( i=$st; i<$en; i++ ))
do
	echo "Deleting VHD $name$i"
        str=$(echo $name$i)
        umount /mnt/$str
        rm $str.img
done

echo
echo "Disk Stats:"
df
echo


