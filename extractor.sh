#!/bin/bash

echo "Analyzing and converting data from $1"
echo "The converted data will be stored in $2"
echo
THOU=1000
touch $2
rm $2
touch $2
touch tmp
rm tmp
touch tmp
num_packets=$(cat $1 | wc -l)
echo The total number of packets is $num_packets
for (( i = 1; i <= $num_packets; i++))
do
  time1=$(cat $1 | awk 'NR == '$i' {print $1}')
  time2=$(expr $time1*$THOU | bc)
  time=$(echo "($time2+0.5)/1" | bc)
  size=$(cat $1 | awk 'NR == '$i' {print $3}')
  proto=$(cat $1 | awk 'NR == '$i' {print $2}')
  if [ "$proto" == "TCP" ];
  then
    $(echo -e "#" >> tmp)
  elif [ "$proto" == "ICMP" ];
  then
    $(echo -e "#" >> tmp)
  elif [ "$proto" == "UDP" ];
  then
    $(echo -e "#" >> tmp)
  else
    $(echo -e " " >> tmp)
    proto="UDP"
  fi
  if [ "$time" == 0 ]
  then 
    time=1
  fi
  $(echo "-a 127.0.0.1 -T $proto -c $size -t $time" >> $2)
done
echo The total number of packets is $num_packets
echo "DONE"
