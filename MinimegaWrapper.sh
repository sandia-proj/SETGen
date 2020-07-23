#!/bin/bash

#Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
GREEN=$'\e[0;32m'
NC='\033[0m'


clear
echo
echo "------------------------------------------------------------------"
echo -e "---------------------- ${CYAN}MINIMEGA WRAPPER${NC} --------------------------"
echo "------------------------------------------------------------------"
echo



function case0() {
  echo "Exiting..."
  echo
  echo
  exit

}

function case1() {
  ./VHDCreator.sh
  cd $dir
}
function case2() {
  ./VHDDestroyer.sh
  cd $dir
}
function case3() {
 run=$(ps -aux | grep minimega\ -nostdin | wc -l)
	if [[ $run == 1 ]]
	then
          echo "Please press enter"
          sleep 1
          minimega -nostdin &
          sleep 1
       else
          echo "Minimega is already running!"
       fi
}

function case4() {
 run=$(ps -aux | grep miniweb | wc -l)
	if [[ $run == 1 ]]
        then
	  echo "Starting Miniweb..."
	  cd /opt/minimega
	  bin/miniweb &
        else 
          echo "Miniweb is already running!"
        fi
        cd $dir
}

function case5() {
  ./VMgen.sh
  init_status
  cd $dir
}

function case6() {
  echo 
  echo -e "${GREEN}Options:${NC}"
  echo "--------------------------------------------"
  echo "1- Run with default username/password i.e. vm<no.>/vm<no.>"
  echo "2- Provide username file and password file"
  echo "--------------------------------------------"
  echo "Please enter your choice:"
  echo -n "---> "
  read choice
  count=$(minimega -e vm info | wc -l)
  let count=count-1
  if [[ $choice == 1 ]]
  then
    ./VMconnect.sh $count
  elif [[ $choice == 2 ]]
  then
    echo "Please enter the path to file containing the Username of the VM(s)"
    read Upath 
    echo "Please enter the path to file containing the Password of the VM(s)"
    read Ppath
    ./VMconnect.sh $Upath $Ppath
  else
    echo -e "${RED}Invalid choice entered!${NC} Exiting to Main Menu..."
  fi  
  cd $dir
}

function case7a() {
  echo "Please specify the path to the file you wish to copy:"
  read path 
  echo "Please specify the VM's IP address:"
  read ip
  echo "Please enter the username:"
  read uname
  echo "Please enter the password:"
  read passwd
  state=$(minimega -e vm info | grep $ip | awk '{print $7}')
  if [[ $state != "RUNNING" ]]
  then
    echo "The VM is not Running! Exiting to main menu..."
  elif [[ $state == "" ]]
  then
    echo "Such VM doesn't exist! Exiting to main menu..."
  else
    echo "Copying the file to $ip..."
    sshpass -p "$passwd" scp -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $path $uname@$ip:
    if [[ $? -eq 0 ]]
    then
      echo "Copying finished. Exiting to main menu..."
    else
      echo -e "${RED}Invalid Username/Password.${NC} Exiting to main menu"
    fi
  fi
}

function case7b() {
  echo 
  echo -e "${GREEN}Options:${NC}"
  echo "----------------------------------------------------------"
  echo "1- Run with default username/password i.e. vm<no.>/vm<no.>"
  echo "2- Provide username file and password file"
  echo "----------------------------------------------------------"
  echo "Please enter your choice:"
  echo -n "---> "
  read choice
  echo "Please specify the path to the file you wish to copy:"
  read path 
  count=$(minimega -e vm info | wc -l)
  let count=count-1
  if [[ $choice == 1 ]]
  then
    ./VMconnect.sh $count -copy $path
  elif [[ $choice == 2 ]]
  then
    echo "Please enter the path to file containing the Username of the VM(s)"
    read Upath 
    echo "Please enter the path to file containing the Password of the VM(s)"
    read Ppath
    ./VMconnect.sh -copy $path $Upath $Ppath
  else
    echo -e "${RED}Invalid choice entered!${NC} Exiting to Main Menu..."
  fi  
} 

function case7() {
  echo 
  echo -e "${GREEN}Options:${NC}"
  echo "-------------------------------------"
  echo "1- Copy the file to a specific VM"
  echo "2- Copy the file to all running VM(s)"
  echo "-------------------------------------"
  echo "Please enter your choice:"
  echo -n "---> "
  read choice
  if [[ $choice == 1 ]]
  then
    case7a
  elif [[ $choice == 2 ]]
  then
    case7b
  else
    echo -e "${RED}Invalid choice entered!${NC} Exiting to Main Menu..."
  fi 
  cd $dir
}

function case8a() {
  echo "Please specify the path to the script you wish to run:"
  read path 
  echo "Please specify the VM's IP address:"
  read ip
  echo "Please enter the username:"
  read uname
  echo "Please enter the password:"
  read passwd
  state=$(minimega -e vm info | grep $ip | awk '{print $7}')
  if [[ $state != "RUNNING" ]]
  then
    echo "The VM is not Running! Exiting to main menu..."
  elif [[ $state == "" ]]
  then
    echo "Such VM doesn't exist! Exiting to main menu..."
  else
    echo "Running the script in $ip..."
    sshpass -p "$passwd" scp -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $path $uname@$ip:
    if [[ $? -eq 0 ]]
    then
      echo "Done. Exiting to main menu..."
    else
      echo "${RED}Invalid Username/Password.${NC} Exiting to main menu"
    fi
  fi
}

function case8b() {
  echo 
  echo -e "${GREEN}Options:${NC}"
  echo "----------------------------------------------------------"
  echo "1- Run with default username/password i.e. vm<no.>/vm<no.>"
  echo "2- Provide username file and password file"
  echo "----------------------------------------------------------"
  echo "Please enter your choice:"
  echo -n "---> "
  read choice
  echo "Please specify the path to the script you wish to run:"
  read path 
  count=$(minimega -e vm info | wc -l)
  let count=count-1
  if [[ $choice == 1 ]]
  then 
    ./VMconnect.sh $count -run $path
  elif [[ $choice == 2 ]]
  then
    echo "Please enter the path to file containing the Username of the VM(s)"
    read Upath 
    echo "Please enter the path to file containing the Password of the VM(s)"
    read Ppath
    ./VMconnect.sh -run $path $Upath $Ppath
  else
    echo -e "${RED}Invalid choice entered!${NC} Exiting to Main Menu..."
  fi  
} 


function case8() {
  echo 
  echo -e "${GREEN}Options:${NC}"
  echo "--------------------------------------"
  echo "1- Run the script in a specific VM"
  echo "2- Run the script in all running VM(s)"
  echo "--------------------------------------"
  echo "Please enter your choice:"
  echo -n "---> "
  read choice
  if [[ $choice == 1 ]]
  then
    case8a
  elif [[ $choice == 2 ]]
  then
    case8b
  else
    echo -e "${RED}Invalid choice entered!${NC} Exiting to Main Menu..."
  fi 
  cd $dir
}

function case9ba() {
  echo
  echo "Please enter the VM's ip address you want to start Traffic Generation in:"
  read HOST
  state=$(minimega -e vm info | grep $HOST | awk '{print $7}')
  echo $STATE
  if [[ "$state" != "RUNNING" ]]
  then
    echo "The VM doesn't exist/isn't running. Exiting to main menu..."
  else
    echo "Please enter the VM's username:"
    read USERNAME
    echo "Please enter the VM's password:"
    read PASSWORD
    sshpass -p "$USERNAME" scp -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null  temp $USERNAME@$HOST:
    if [[ $? -eq 0 ]]
    then
      echo "The VM has the following network interfaces:"
      echo
      sshpass -p "$PASSWORD" ssh -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -t -l ${USERNAME} ${HOST} "ifconfig; rm temp"
      echo 
      echo "Please enter the interface: "
      read interface
      
    else
      echo "${RED}Invalid Username/Password for${NC} $HOST. Exiting to main menu..."
    fi
  fi
}

function case9a() {
  echo
  echo -e "------------------------${CYAN} VM STATUS ${NC} -------------------------"
  echo
  cat temp
  echo
}

function case9b() {
  echo 
  echo -e "${GREEN}Options:${NC}"
  echo "-----------------------------------"
  echo "1- Start Traffic Generation in a VM"
  echo "2- Stop Traffic Generation in a VM"
  echo "-----------------------------------"
  echo "Please enter your choice:"
  echo -n "---> "
  read choice
  if [[ $choice == 1 ]]
  then
    case9ba
  elif [[ $choice == 2 ]]
  then
    case9bb
  else
    echo -e "${RED}Invalid choice entered!${NC} Exiting to Main Menu..."
  fi
  #Call D-ITGWrapper
}

function case9() {
  echo 
  echo -e "${GREEN}Options:${NC}"
  echo "--------------------------------------"
  echo "1- Network Traffic Generation Status"
  echo "2- VM Network Traffic Generation"
  echo "3- Cross-VM Network Traffic Generation"
  echo "--------------------------------------"
  echo "Please enter your choice:"
  echo -n "---> "
  read choice
  if [[ $choice == 1 ]]
  then
    case9a
  elif [[ $choice == 2 ]]
  then
    case9b
  elif [[ $choice == 3 ]]
  then
    case9c
  else
    echo -e "${RED}Invalid choice entered!${NC} Exiting to Main Menu..."
  fi
  cd $dir
}

function case10() {
  run=$(ps -aux | grep minimega\ -nostdin | wc -l)
  if [[ $run == 1 ]]
  then
    echo -e "${RED}Minimega is not running.${NC} Exiting to main menu..."
  else 
    echo -e "${RED}WARNING:${NC} Killing Minimega will close all the VMs and you won't be able to work with the same VMs anymore. Do you wish to continue? (Y/N?"
    read choice
    if [[ $choice == "Y" ]]
    then
      minimega -e vm kill all
      minimega -e vm flush
      pid=$(ps -aux | grep minimega\ -nostdin | awk 'NR==1{print $2}')
      kill $pid 
      rm temp
    fi
  fi
}

function case11() {
  run=$(ps -aux | grep miniweb | wc -l)
  if [[ $run == 1 ]]
  then
    echo -e "${RED}Miniweb is not running.${NC} Exiting to main menu..."
  else
    pid=$(ps -aux | grep miniweb | awk 'NR==1{print $2}')
    kill $pid
  fi
}

function init_status() {
  if [ ! -f temp ]
  then
    count=$(minimega -e vm info | wc -l)
    bar=$(minimega -e vm info | awk '{print $2}')
    str="			IP		|		SRC		|		DEST		|		INTERFACE		"
    echo $str >> temp
    echo >> temp
    echo >> temp
    for (( i=1; i < $count; i++ ))
    do
      let row=$i+1
      state=$(minimega -e vm info | awk 'NR=='$row'{print $7}')
      if [[ "$state" != "RUNNING" ]] 
      then
        continue
      fi 
      str="	"
      str+=$(minimega -e vm info | awk 'NR=='$row'{print $27}')
      str+="		|		N/A		|		N/A		|		N/A		"
      echo $str >> temp	
    done
  fi
}

function add_ip_status() {
      str=$1
      str+="		|		N/A		|		N/A		|		N/A		"
      echo $str >> temp
}

if [ "$EUID" -ne 0 ]
then 
  echo -e "${RED}You need to be the root user in order to use this Wrapper.${NC}"
  echo "Exiting..."
  exit
fi


dir=$(pwd)

init_status
while true
do 
  echo
  echo -e "${GREEN}Options:${NC}"
  echo "--------------------------------------------"
  echo "1- Create Virtual Hard Disk(s)"
  echo "2- Delete Virtual Hard Disk(s)"
  echo "3- Start Minimega"
  echo "4- Start Miniweb"
  echo "5- Setup and Start VM(s)"
  echo "6- Install Wrapper requirements in the VM(s)"
  echo "7- Copy file(s) to VM(s)"
  echo "8- Execute Script in VM(s)"
  echo "9- Traffic Generator Control Panel"
  echo "10- Kill Minimega"
  echo "11- Kill Miniweb"
  echo "0- Exit"
  echo "--------------------------------------------"
  echo
  echo "Please enter your choice:"
  echo -n "---> "
  read input
  if [[ "$input" == 0 ]]; then
    case0
  elif [[ "$input" == 1 ]]; then
    case1
  elif [[ "$input" == 2 ]]; then
    case2
  elif [[ "$input" == 3 ]]; then
    case3
  elif [[ "$input" == 4 ]]; then
    case4
  elif [[ "$input" == 5 ]]; then
    case5
  elif [[ "$input" == 6 ]]; then
    case6
  elif [[ "$input" == 7 ]]; then
    case7
  elif [[ "$input" == 8 ]]; then
    case8
  elif [[ "$input" == 9 ]]; then
    case9
  elif [[ "$input" == 10 ]]; then
    case10
  elif [[ "$input" == 11 ]]; then
    case11
  else
    echo "${RED}Invalid Option.${NC} Please try again!"
    echo
  fi
  sleep 0.5
done
