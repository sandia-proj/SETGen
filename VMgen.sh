#!/bin/bash

# Scipt that Deals with Creating VMs

# Checking if the user is root or not

if [ "$EUID" -ne 0 ]
then 
  echo "Please run as root"
  exit
fi

run=$(ps -aux | grep minimega | wc -l)

# Checking if Minimega is running or not

if [[ $run == 1 ]]
then
  echo "Please run \"minimega\" and try again!"
  exit
fi

# Function that will get the basic parameters

function init () {
	# Prompt for #VMs to generate
	echo "Please specify the number of VMs to create:"
	read numOfVMs

    # Re-prompt
	while ! [[ "$numOfVMs" =~ ^[0-9]+$ ]]; do
      echo "Invalid input. Please try again!"
      echo
      echo "Please specify the number of VMs to create:"
	  read numOfVMs
    done

	if [[ $numOfVMs -lt 1 ]]; then
	  echo "The number of VMs can't be less than 1. Exiting to main menu..."
	  exit
	fi

	echo "Please specify the number of CPUs for each VM:"
	read numCPUs

    # Re-prompt
    while ! [[ "$numCPUs" =~ ^[0-9]+$ ]]; do
      echo "Invalid input. Please try again!"
      echo
      echo "Please specify the number of CPUs for each VM:"
	  read numCPUs
    done

	if [[ $numCPUs -lt 1 ]]; then
	  echo "The number of CPUs can't be less than 1. Exiting to main menu..."
	  exit
	fi

	echo "Please specify the size of memory for each VM:"
	read mem

	# Re-prompt
    while ! [[ "$mem" =~ ^[0-9]+$ ]]; do
      echo "Invalid input. Please try again!"
      echo
      echo "Please specify the size of memory for each VM:"
	  read mem
    done

	if [[ $mem -lt 1024 ]]; then
	  echo "The amount of memory can't be less than 1024. Exiting to main menu..."
	  exit
	fi

	echo "Please specify the prefix name of the VHDs:"
	read name

    # Re-prompt
    while [[ -z $name ]]; do
      echo "The prefix can't be empty. Please try again!"
      echo
      echo "Please specify the prefix name of the VHDs:"
	  read name
	done

    echo "Please specify the path to directory where the VHDs were generated:"
	read path

    # Re-prompt
    while ! [[ -d $path ]]; do
      echo "Invalid directory. Please try again!"
      echo
      echo "Please specify the path to directory where the VHDs were generated:"
      read path
    done
 
    # Get the number of VHDs with the prefix
	count=$(ls $path | grep "$name[0-9]*.img" | wc -l)

    if [[ $count -lt $numOfVMs ]]; then
      echo "There are not many VHD(s) to run $numOfVMs VMs!"
      echo
      sleep 0.5
      echo "Exiting to main menu..."
      exit
    fi

	echo "Please specify the VLAN number:"
	read vlan
    
    # Re-prompt
    while ! [[ "$vlan" =~ ^[0-9]+$ ]]; do
      echo "Invalid input. Please try again!"
      echo
      echo "Please specify the VLAN number:"
	  read vlan
    done

    if [[ $vlan -lt 1 || $vlan -gt 4094 ]]; then
	  echo "The VLAN range is 1-4094. Exiting to main menu..."
	  exit
	fi
	
	echo "Please specify the path to the iso file:"
	read isopath

	while ! [[ -f $isopath ]]; do
	  echo "Invalid input. Please try again!"
      echo
      echo "Please specify the path to the iso file:"
	  read isopath
    done

	cd $path
	path=$(pwd)

    # Prompt for interface

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
          diskpath=$(echo $path/$name$i.img)
	  minimega -e vm config disk $diskpath
	  minimega -e vm launch kvm vm$i
          echo $diskpath
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
