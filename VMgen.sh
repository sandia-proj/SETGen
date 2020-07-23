#!/bin/bash

if [ "$EUID" -ne 0 ]
then echo "Please run as root"
exit
fi

run=$(ps -aux | grep minimega\ -nostdin | wc -l)
	if [[ $run == 1 ]]
	then
	echo "Please run \"minimega -nostdin &\" and try again!"
	exit
	fi

	echo "Minimega controller"
	echo

	init () {
		echo "Please specify the number of VMs to create:"
			read numOfVMs
			echo "Please specify the number of CPUs for each VM:"
			read numCPUs
			echo "Please specify the size of memory for each VM:"
			read mem
			echo "Please specify the prefix name of the VHDs:"
			read name
			echo "Please specify the VLAN number:"
			read vlan     
			echo "Please specify the path to directory where the VHDs were generated, with '/' in the end"
			read path
			echo "Please specify the path to the iso:"
			read isopath
			cd $path
			int=$(ip route | grep default | sed -e "s/^.*dev.//" -e "s/.proto.*//")
			echo "The detected interface is $int. Is this correct? Y/N"
			read ans
			if [[ $ans == "N" ]]
				then
					echo "Please specify the interface:"
					read int
					fi
	}
init
print_config() {
	echo
		echo "Configuration:"
		echo "No. of VMs: $numOfVMs"
		echo "No. of CPUs: $numCPUs"
		echo "Memory: $mem"
		echo "Prefix of VHDs: $name"
		echo "VLAN: $vlan"
		echo "Interface: $int"
		echo "OS: $isopath"
}
print_config

echo
echo "Does this look correct? Y/N"
read ans
if [[ $ans == "N" ]]
then
echo 
init
print_config
fi
echo

pwd=$(pwd)

	echo
	echo "Creating VMs"

	for (( i=1; i <= $numOfVMs; i++ ))
	do
	  minimega -e clear vm config
	  minimega -e vm config memory $mem
	  minimega -e vm config cdrom $isopath
	  minimega -e vm config net $vlan
	  minimega -e vm config vcpus $numCPUs
          diskpath=$(echo $path$name$i.img)
	  minimega -e vm config disk $diskpath
	  minimega -e vm launch kvm vm$i
	done

echo
echo "Creating host tap  connecting the server to mega_bridge on vlan $vlan and starting a dnsmasq service..."
minimega -e tap create $vlan ip 1.0.0.1/24
minimega -e dnsmasq start 1.0.0.1 1.0.0.2 1.0.0.254

echo 
echo "Clearing existing iptable rules if any exists..."
iptables -P INPUT ACCEPT
iptables -P OUTPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -F
iptables -F -t mangle
iptables -F -t nat

echo 
echo "Setting up iptable rules..."

WAN=$int
sysctl -w net.ipv4.ip_forward=1
iptables -t nat -A POSTROUTING -o $WAN -j MASQUERADE
iptables -A FORWARD -i $WAN -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -o $WAN -j ACCEPT

echo
echo "Starting the VMs..."
	for (( i=1; i <= $numOfVMs; i++ ))
	do
          minimega -e vm start vm$i
        done
echo "The VMs have started. Please install the ISOs and proceed to the next step!"
