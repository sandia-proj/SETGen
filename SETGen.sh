#!/bin/bash

#Color
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GREEN=$'\e[0;32m'
RED='\033[0;31m'
NC='\033[0m'


echo
echo "----------------------------------------------------------------------------------------------"
echo -e "---------------------- ${CYAN}SETGen - System events and traffic generator${NC} --------------------------"
echo "----------------------------------------------------------------------------------------------"
echo

# Exit the Wrapper

function case0() {
  echo "Exiting..."
  echo
  echo
  exit
}

# Generate VHDs

function case1() {
  cd $dir
  # Calling the script that deals with generating VHDs
  ./scripts/VHDCreator.sh
  # Reverting to the current directory
  
}

# Delete VHDs

function case2() { 
  cd $dir
  # Calling the script that deals with deleting VHDs
  ./scripts/VHDDestroyer.sh

  # Reverting to the current directory
  cd $dir
}

# Start Minimega

function case3() {
  cd $dir
  # Checking if there's any running Minimega Process  
  run=$(ps -aux | grep minimega | wc -l)

  # If process doesn't exist
  if [[ $run == 1 ]]; then
    tmux new-session -d -s Minimega 'minimega'
    echo -e "${GREEN}Minimega Started!${NC}"
  # If process exists
  else
    echo "Minimega is already running!"
  fi
}

# Start Miniweb

function case4() {
  cd $dir
  # Checking if there's any running Miniweb Process  
  run=$(ps -aux | grep miniweb | wc -l)

  # If process doesn't exist
  if [[ $run == 1 ]]; then
    echo "Starting Miniweb..."
    cd /opt/minimega
    bin/miniweb &
    echo -e "${GREEN}Miniweb Started!${NC}"
  # If process exists
  else 
    echo "Miniweb is already running!"
  fi

  # Reverting to the current directory
  cd $dir
}

# Minimega VM Generator

function case5() {
  # Reverting to the current directory
  cd $dir

  # Calling script that deals with the automated generation of VMs
  ./scripts/VMgen.sh
}

# Install the required packages to all "RUNNING" VMs for Traffic Generation

function case6() {
  # Reverting to the current directory
  echo "Have you installed Ubuntu and the required tools in all running VMs? Y/N"
  read ans 

  if ! [[ "$ans" == "Y" || "$ans" == "y" ]]; then
    echo 
    echo "Please follow the steps in the Manual and then continue with option 6."
    echo "Exiting to main menu..."
    
    return
  fi

  # Populate the temporary file with the VM names and IP addresses
  init_status
  
  # Checking the number of VMs
  count=$(minimega -e vm info | grep RUNNING | wc -l)
  let count=count-1
  
  # Checking if there are valid VMs. If not, exit to main menu.
  if [[ $count -lt 1 ]]; then
    echo
    echo -e "${RED}Couldn't find any running VM(s).${NC} Please proceed to step 5 to generate VMs and follow the manual for next steps."
    sleep 0.5
    echo "Exiting to main menu..."
    sleep 0.5
    return
  fi

  # Display Menu
  echo 
  echo -e "${GREEN}OPTIONS:${NC}"
  echo "----------------------------------------------------------"
  echo "1- Run with default username/password i.e. vm<no.>/vm<no.>"
  echo "2- Provide username file and password file"
  echo "3- Exit to main menu"
  echo "----------------------------------------------------------"
  echo "Please enter your choice:"
  echo -n "---> "
  read choice

  # If Default Username-Password, then calling the script directly
  if [[ $choice == 1 ]]
  then
    
    ./scripts/VMconnect.sh $count
  
  # Supplying the Username and Password file
  elif [[ $choice == 2 ]]
  then
    
    # Prompt to input Username File
    echo "Please enter the path to file containing the Username of the VM(s)"
    read Upath

    # Re-prompting until valid path to file is entered
    while ! [[ -f $Upath ]]; do
      echo "This is an invalid file/a directory. Please try again!"
      echo
      echo "Please enter the path to file containing the Username of the VM(s)"
      read Upath
    done
    
    # Prompt to input Password File
    echo "Please enter the path to file containing the Password of the VM(s)"
    read Ppath
    
    # Re-prompting until valid path to file is entered
    while ! [[ -f $Ppath ]]; do
      echo "This is an invalid file/a directory. Please try again!"
      echo
      echo "Please enter the path to file containing the Username of the VM(s)"
      read Ppath
    done

    # Calling the script with the arguments  
    ./scripts/VMconnect.sh $Upath $Ppath
 
  # Exit to main menu
  elif [[ $choice == 3 ]]
  then
    echo "Exiting to Main menu..."
    return

  # Handling invalid choices 
  else
    echo -e "${RED}Invalid choice entered!${NC} Exiting to Main Menu..."
  fi

  # Reverting to the current directory
  cd $dir
}

# Copy file to specific VM

function case7a() {
  # Prompt for Path
  echo "Please specify the path to the file you wish to copy:"
  read path

  # Re-prompt until valid input
  while ! [[ -f $path ]]; do
    echo "This is an invalid file/a directory. Please try again!"
    echo
    echo "Please specify the path to the file you wish to copy:"
    read path
  done

  # Prompt for IP address
  echo "Please specify the VM's IP address:"
  read ip

  # Re-prompt until valid IP
  while ! [[ $ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; do
    echo "Invaid IP address entered. Please try again!"
    echo
    echo "Please specify the VM's IP address:"
    read ip
  done

  # Prompt for Username
  echo "Please enter the username:"
  read uname

  # If Username empty, re-prompt
  while [[ -z "$uname" ]]; do
    echo "Username can't be empty. Please try again!"
    echo
    echo "Please enter the username:"
    read uname
  done
  
  # Prompt for Password
  echo "Please enter the password:"
  read passwd
  
  # If Password empty, re-prompt
  while [[ -z "$passwd" ]]; do
    echo "Password can't be empty. Please try again!"
    echo
    echo "Please enter the password:"
    read passwd
  done

  # Get the state of the VM
  state=$(minimega -e vm info | grep $ip | awk '{print $7}')

  # Check if VM Exists or not
  if [[ "$state" == "" ]]
  then
    echo -e "${RED}Such VM doesn't exist!${NC} Exiting to main menu..."

  # If not RUNNING, exit to main menu
  elif [[ $state != "RUNNING" ]]
  then
    echo -e "${RED}The VM is not Running!${NC} Exiting to main menu..."
  
  # Copy the files
  else
    echo "Copying the file to $ip..."
    sshpass -p "$passwd" scp -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $path $uname@$ip:

    # Check if SCP failed
    if [[ $? -eq 0 ]]
    then
      echo -e "${GREEN}Copying finished.${NC} Exiting to main menu..."
    else
      echo -e "${RED}Invalid Username/Password.${NC} Exiting to main menu..."
    fi
  fi
}

# Copy file to all RUNNING VMs

function case7b() {

  # Prompt for OPTIONS
  echo 
  echo -e "${GREEN}OPTIONS:${NC}"
  echo "----------------------------------------------------------"
  echo "1- Run with default username/password i.e. vm<no.>/vm<no.>"
  echo "2- Provide username file and password file"
  echo "3- Exit to main menu"
  echo "----------------------------------------------------------"
  echo "Please enter your choice:"
  echo -n "---> "
  read choice

  # Prompt for Path
  echo "Please specify the path to the file you wish to copy:"
  read path

  # Re-prompt until valid path
  while ! [[ -f $path ]]; do
      echo "This is an invalid file/a directory. Please try again!"
      echo
      echo "Please specify the path to the file you wish to copy:"
      read path
  done

  # Get the count of RUNNING VMs
  count=$(minimega -e vm info | wc -l)
  let count=count-1

  # Use Deafault Username|Password
  if [[ $choice == 1 ]]
  then
    ./scripts/VMconnect.sh $count -copy $path

  # Get Username and Password File
  elif [[ $choice == 2 ]]
  then

    # Prompt for Username File
    echo "Please enter the path to file containing the Username of the VM(s)"
    read Upath

    # Re-prompt until valid input
    while ! [[ -f $Upath ]]; do
      echo "This is an invalid file/a directory. Please try again!"
      echo
      echo "Please enter the path to file containing the Username of the VM(s)"
      read Upath
    done

    # Prompt for Password File
    echo "Please enter the path to file containing the Password of the VM(s)"
    read Ppath

    # Re-prompt until valid input
    if ! [[ -f $Ppath ]]; then
      echo "This is an invalid file/a directory. Please try again!"
      echo
      echo "Please enter the path to file containing the Password of the VM(s)"
      read Ppath
      return
    fi

    # Calling the script with the arguments
    ./scripts/VMconnect.sh -copy $path $Upath $Ppath

  # Exit
  elif [[ $choice == 3 ]]
  then
    echo "Exiting to main menu..."
    return
  
  # Handle invalid choices
  else
    echo -e "${RED}Invalid choice entered!${NC} Exiting to Main Menu..."
  fi  
} 


# Function that deals with copying of files to VM

function case7() {
  cd $dir
  # Prompt for OPTIONS
  echo 
  echo -e "${GREEN}OPTIONS:${NC}"
  echo "-------------------------------------"
  echo "1- Copy the file to a specific VM"
  echo "2- Copy the file to all running VM(s)"
  echo "3- Exit to main menu"
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
  elif [[ $choice == 3 ]]
  then
    echo "Exiting to main menu..."
    return
  else
    echo -e "${RED}Invalid choice entered!${NC} Exiting to Main Menu..."
  fi

  # Reverting to the current directory
  cd $dir
}

# Run Scripts in a specific VM

function case8a() {

  echo "Please specify the path to the script you wish to run:"
  read path

  # Re-prompt until correct input
  while ! [[ -f $path ]]; do
    echo "This is a directory/an invalid file. Please try again!"
    echo
    echo "Please specify the path to the script you wish to run:"
    read path
  done

  echo "Please specify the VM's IP address:"
  read ip

  # Re-prompt until correct input
  while ! [[ $ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; do
    echo "Invaid IP address entered. Please try again!"
    echo
    echo "Please specify the VM's IP address:"
    read ip
  done

  echo "Please enter the username:"
  read uname

  # Re-prompt until correct input

  while [[ -z $uname ]]; do
    echo "Username can't be empty. Please try again!"
    echo
    echo "Please enter the username:"
    read uname
  done

  echo "Please enter the password:"
  read passwd

  # Re-prompt until correct input

  while [[ -z $passwd ]]; do
    echo "Password can't be empty. Please try again!"
    echo
    echo "Please enter the password:"
    read passwd
  done

  # Get the state of the VM

  state=$(minimega -e vm info | grep $ip | awk '{print $7}')

  # Check if VM exists

  if [[ "$state" == "" ]]
  then
    echo "Such VM doesn't exist! Exiting to main menu..."

  # Check if VM in RUNNING state

  elif [[ $state != "RUNNING" ]]
  then
    echo "The VM is not Running! Exiting to main menu..."
  
  else

    # Extracing the script name from the path
    scriptname=$(basename $path)

    # Run the script
    echo "Running the script in $ip..."
    sshpass -p "$passwd" scp -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $path $uname@$ip:

    # Check if Authentication success

    if [[ $? -eq 0 ]]
    then
      echo "Starting the script in $ip"
      SCRIPT="chmod +x $scriptname; echo $passwd | sudo -S ./$scriptname"
      sshpass -p "$passwd" ssh -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -t -l ${uname} ${ip} "${SCRIPT}"
      echo "Done. Exiting to main menu..."
    else
      echo -e "${RED}Invalid Username/Password.${NC} Exiting to main menu..."
    fi
  fi
}

# Function that runs scripts in all RUNNING VMs

function case8b() {

  # Prompt 
  echo 
  echo -e "${GREEN}OPTIONS:${NC}"
  echo "----------------------------------------------------------"
  echo "1- Run with default username/password i.e. vm<no.>/vm<no.>"
  echo "2- Provide username file and password file"
  echo "3- Exit to main menu"
  echo "----------------------------------------------------------"
  echo "Please enter your choice:"
  echo -n "---> "
  read choice

  # Prompt for Script
  echo "Please specify the path to the script you wish to run:"
  read path

  # Re-prompt
  while ! [[ -f $path ]]; do
      echo "This is a directory/invalid file. Please try again!"
      echo
      echo "Please specify the path to the script you wish to run:"
      read path 
  done

  # Count the number of VMs 
  count=$(minimega -e vm info | wc -l)
  let count=count-1

  # Call the script with appropriate args
  if [[ $choice == 1 ]]
  then 
    ./scripts/VMconnect.sh $count -run $path
  elif [[ $choice == 2 ]]
  then

    # Prompt for Username file
    echo "Please enter the path to file containing the Username of the VM(s)"
    read Upath 

    
    # Re-prompt
    while ! [[ -f $Upath ]]; do
      echo "This is a directory/invalid file. Please try again!"
      echo
      echo "Please enter the path to file containing the Username of the VM(s)"
      read Upath 
    done

    echo "Please enter the path to file containing the Password of the VM(s)"
    read Ppath

   # Re-prompt
    while ! [[ -f $Ppath ]]; do
      echo "This is a directory/invalid file. Please try again!"
      echo
      echo "Please enter the path to file containing the Password of the VM(s)"
      read Ppath 
    done

    # Call VMconnect Script
    ./scripts/VMconnect.sh -run $path $Upath $Ppath

  elif [[ $choice == 3 ]]
  then
    echo "Exiting to main menu..."
    return
  else
    echo -e "${RED}Invalid choice entered!${NC} Exiting to Main Menu..."
  fi  
} 


# Function that deals with running scripts in VMs

function case8() {
  cd $dir
  # Prompt
  echo 
  echo -e "${GREEN}OPTIONS:${NC}"
  echo "--------------------------------------"
  echo "1- Run the script in a specific VM"
  echo "2- Run the script in all running VM(s)"
  echo "3- Exit to main menu"
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
  elif [[ $choice == 3 ]]
  then
    echo "Exiting to main menu..."
    return
  else
    echo -e "${RED}Invalid choice entered!${NC} Exiting to Main Menu..."
  fi 

  # Reverting to the current directory
  cd $dir
}

# Start Wrapper Traffic Generation inside a VM

function case9ba() {

  # Prompt for IP Address of the VM
  echo
  echo "Please enter the VM's ip address you want to start Traffic Generation in:"
  read HOST

  # Re-prompt
  while ! [[ $HOST =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; do
    echo "Invaid IP address entered. Please try again!"
    echo
    echo "Please enter the VM's ip address you want to start Traffic Generation in:"
    read HOST
  done
  
  
  state=$(minimega -e vm info | grep $HOST | awk '{print $7}')
  
  # Check if VM exists
  if [[ "$state" == ""  ]]
  then
    echo "Such VM doesn't exist! Exiting to main menu..."

  # Check if VM in RUNNING state

  elif [[ "$state" != "RUNNING" ]]
  then
    echo "The VM is not running. Exiting to main menu..."

  else
   
    # Check if VM generating traffic
    val=$(cat tmp/temp | grep $HOST | awk '{print $9}')

    if [[ "$val" == "N/A" ]]
    then

      # Prompt for Username
      echo "Please enter the VM's username:"
      read USERNAME

      # If Username empty, re-prompt
      while [[ -z "$USERNAME" ]]; do
        echo "Username can't be empty! Please try again."
        echo
        echo "Please enter the VM's username:"
        read USERNAME
      done

      # Prompt for Password
      echo "Please enter the VM's password:"
      read PASSWORD

      # If Password empty, re-prompt
      while [[ -z "$PASSWORD" ]]; do
        echo "Password can't be empty! Please try again."
        echo
        echo "Please enter the VM's password:"
        read PASSWORD
      done
    
      # Check SSH connection
      sshpass -p "$PASSWORD" ssh -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -t -l ${USERNAME} ${HOST} "exit"

      # If SSH invalid, exit to main menu
      if [[ $? -eq 0 ]]
      then
       
        # Print the interfaces and prompt
        echo "The VM has the following network interfaces:"
        echo
        sshpass -p "$PASSWORD" ssh -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -t -l ${USERNAME} ${HOST} "ifconfig"
        echo
        echo "Please enter the interface: "
        read interface

        # If Interface empty, re-prompt
        while [[ -z "$interface" ]]; do
          echo "Password can't be empty! Please try again."
          echo
          echo "Please enter the interface: "
          read interface
        done

        # Build the script

        echo "#!/bin/bash
            cd NetworkWrapper/
            tmux new-session -d -s TrafficGen \; send-keys \"python3 /home/$USERNAME/NetworkWrapper/wrap.py $interface\" Enter
            " > tmp/NTGStart.sh

        # Copy the script to the VM

        sshpass -p "$PASSWORD" scp -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null  tmp/NTGStart.sh $USERNAME@$HOST:

        echo "Starting Network Traffic Generation in $HOST"
        SCRIPT="chmod +x NTGStart.sh; echo $PASSWORD | sudo -S ./NTGStart.sh"
        sshpass -p "$PASSWORD" ssh -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -t -l ${USERNAME} ${HOST} "${SCRIPT}"

        # Update the tmp/temp file
        sed -i "/\b${HOST}\b/d" tmp/temp
        str=$HOST
        str+="		|		$HOST		|		$HOST		|		$interface		|   NetworkWrapper (Tools)"
        echo $str >> tmp/temp

        echo "Started"
      else
        echo -e "${RED}Invalid Username/Password for${NC} $HOST. Exiting to main menu..."
        return
      fi
    else
      echo "The VM is already generating traffic"
    fi
  fi
}

# Stop Wrapper Traffic Generation inside a VM

function case9bb() {

  # Prompt for IP Address of the VM
  echo
  echo "Please enter the VM's ip address you want to stop Traffic Generation in:"
  read HOST

  # Re-prompt
  while ! [[ $HOST =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; do
    echo "Invaid IP address entered. Please try again!"
    echo
    echo "Please enter the VM's ip address you want to stop Traffic Generation in:"
    read HOST
  done
  
  state=$(minimega -e vm info | grep $HOST | awk '{print $7}')
  
  # Check if VM exists
  if [[ "$state" == "" ]]
  then
    echo "Such VM doesn't exist! Exiting to main menu..."

  # Check if VM in RUNNING state

  elif [[ "$state" != "RUNNING" ]]
  then
    echo "The VM is not running. Exiting to main menu..."

  else
   
    # Check if VM generating traffic
    val=$(cat tmp/temp | grep $HOST | awk '{print $9}')
    val1=$(cat tmp/temp | grep $HOST | awk '{print $3}')
    val2=$(cat tmp/temp | grep $HOST | awk '{print $5}')

    if [[ "$val" == "NetworkWrapper (Tools)" && "$val1" == "$HOST" && "$val2" == "$HOST" ]]
    then

      # Prompt for Username
      echo "Please enter the VM's username:"
      read USERNAME

      # If Username empty, re-prompt
      while [[ -z "$USERNAME" ]]; do
        echo "Username can't be empty! Please try again."
        echo
        echo "Please enter the VM's username:"
        read USERNAME
      done

      # Prompt for Password
      echo "Please enter the VM's password:"
      read PASSWORD

      # If Password empty, re-prompt
      while [[ -z "$PASSWORD" ]]; do
        echo "Password can't be empty! Please try again."
        echo
        echo "Please enter the VM's password:"
        read PASSWORD
      done
    
      # Check SSH connection
      sshpass -p "$PASSWORD" ssh -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -t -l ${USERNAME} ${HOST} "exit"

      # If SSH invalid, exit to main menu
      if [[ $? -eq 0 ]]
      then
        # Build the script

        echo "#!/bin/bash
            tmux kill-session -t TrafficGen
            " > tmp/NTGStop.sh

        # Copy the script to ehte VM

        sshpass -p "$PASSWORD" scp -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null  tmp/NTGStop.sh $USERNAME@$HOST:

        echo "Stopping Network Traffic Generation in $HOST"
        SCRIPT="chmod +x NTGStop.sh; echo $PASSWORD | sudo -S ./NTGStop.sh"
        sshpass -p "$PASSWORD" ssh -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -t -l ${USERNAME} ${HOST} "${SCRIPT}"

        # Update the tmp/temp file
        sed -i "/\b${HOST}\b/d" tmp/temp
        str=$HOST
        str+="		|		N/A		|		N/A		|		N/A		|   N/A"
        echo $str >> tmp/temp

        echo "Stopped"
      else
        echo -e "${RED}Invalid Username/Password for${NC} $HOST. Exiting to main menu..."
        return
      fi
    else
      echo "The VM is not generating NetworkWrapper traffic within itself. Exiting to main menu..."
      return
    fi
  fi
}


# Function that will validate and Start D-ITG Command 

function case9bca() {

  # Prompt for VM's IP address
  echo "Please enter the VM's IP address where you would like to generate traffic using D-ITG:"
  read ip

  #Re-prompt until valid input
  while ! [[ $ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; do
    echo "Invaid IP address entered! Please try again."
    echo
    echo "Please enter the VM's IP address where you would like to generate traffic using D-ITG:"
    read ip
  done
  
  # Get State of VM
  state=$(minimega -e vm info | grep $ip | awk '{print $7}')

  # Check if VM Exists or not
  if [[ "$state" == "" ]]
  then
    echo -e "${RED}Such VM doesn't exist!${NC} Exiting to main menu..."

  # If not RUNNING, exit to main menu
  elif [[ $state != "RUNNING" ]]
  then
    echo -e "${RED}The VM is not Running!${NC} Exiting to main menu..."

  else
    
    # Check if VM already generating traffic
    val=$(cat tmp/temp | grep $ip | awk '{print $9}')
    if [[ "$val" != "N/A" ]]; then
      echo "The VM is already generating traffic. Exiting to main menu..."
      return
    fi 

    # Prompt for Username
    echo "Please enter the VM's username:"
    read username

    # If Username empty, re-prompt
    while [[ -z "$username" ]]; do
      echo "Username can't be empty! Please try again."
      echo
      echo "Please enter the VM's username:"
      read username
    done

    # Prompt for Password
    echo "Please enter the VM's password:"
    read password

    # If Password empty, re-prompt
    while [[ -z "$password" ]]; do
      echo "Password can't be empty! Please try again."
      echo
      echo "Please enter the VM's password:"
      read password
    done

    # Check SSH connection
    sshpass -p "$password" ssh -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -t -l ${username} ${ip} "exit"

    # If SSH invalid, exit to main menu
    if ! [[ $? -eq 0 ]]; then
      echo -e "${RED}Invalid Username/Password entered for${NC} $ip. Exiting to main menu..."
      return
    fi
   
    # Prompt to enter ITGRecv Command
    echo "Please enter the ITGRecv command"
    read ITGRecvCommand

    # If command empty, re-prompt
    while [[ -z "$ITGRecvCommand" ]]; do
      echo "Command can't be empty! Please try again."
      echo
      echo "Please enter the ITGRecv command"
      read ITGRecvCommand
    done
    
    # Check if command is valid
    tmux new-session -d -s ITGRecv "$ITGRecvCommand > out"
    sleep 0.5
    a=$(tmux ls | grep ITGRecv | wc -l)
    if [[ $a != 0 ]]; then
      tmux kill-session -t ITGRecv
    fi

    a=$(cat out | grep 'for help' out | wc -l)

    if [[ $a -gt 0 ]]; then
      echo -e "${RED}Invalid command entered!${NC} Exiting to main menu..."  
      return
    fi
  
    # Build Script
    echo "#!/bin/bash
            tmux new-session -d -s ITGRecv \; send-keys \"$ITGRecvCommand \" Enter
            " > tmp/ITGRecvStart.sh
    sshpass -p "$password" scp -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null  tmp/ITGRecvStart.sh $username@$ip:

    echo "Starting ITGRecv in $ip"
    SCRIPT="chmod +x ITGRecvStart.sh; echo $password | sudo -S ./ITGRecvStart.sh;  "
    sshpass -p "$password" ssh -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -t -l ${username} ${ip} "${SCRIPT}"
    echo
    echo "Please enter the ITGSend command" 
    read ITGSendCommand

    # If command empty, re-prompt
    while [[ -z "$ITGSendCommand" ]]; do
      echo "Command can't be empty! Please try again."
      echo
      echo "Please enter the ITGSend command"
      read ITGSendCommand
    done

    # Check if command is valid
    tmux new-session -d -s ITGSend "$ITGSendCommand > out"
    sleep 0.5
    a=$(tmux ls | grep ITGSend | wc -l)
    if [[ $a != 0 ]]; then
      tmux kill-session -t ITGSend
    fi

    a=$(cat out | grep 'for help' out | wc -l)

    if [[ $a -gt 0 ]]; then
      echo -e "${RED}Invalid command entered!${NC} Exiting to main menu..."  
      return
    fi

    # Start ITGSend
    echo "Starting ITGSend in $ip"
    echo "#!/bin/bash
            tmux new-session -d -s ITGSend \; send-keys \"$ITGSendCommand \" Enter
            " > tmp/ITGSendStart.sh
    sshpass -p "$password" scp -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null  tmp/ITGSendStart.sh $username@$ip:

    SCRIPT="chmod +x ITGSendStart.sh; echo $password | sudo -S ./ITGSendStart.sh;  "
    sshpass -p "$password" ssh -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -t -l ${username} ${ip} "${SCRIPT}"

    # Update the tmp/temp file
    sed -i "/\b${ip}\b/d" tmp/temp
    str=$ip
    str+="	    	|	    	---	    	|   		---   		|       ---       |       D-ITG       "
    echo $str >> tmp/temp

    echo
    echo "Started!"
    echo
  fi
}

# Function that will validate and Stop D-ITG Command 

function case9bd() {

  # Prompt for VM's IP address
  echo "Please enter the VM's IP address where you would like to stop generating traffic using D-ITG:"
  read ip

  #Re-prompt until valid input
  while ! [[ $ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; do
    echo "Invaid IP address entered! Please try again."
    echo
    echo "Please enter the VM's IP address where you would like to stop generate traffic using D-ITG:"
    read ip
  done
  
  # Get State of VM
  state=$(minimega -e vm info | grep $ip | awk '{print $7}')

  # Check if VM Exists or not
  if [[ "$state" == "" ]]
  then
    echo -e "${RED}Such VM doesn't exist!${NC} Exiting to main menu..."

  # If not RUNNING, exit to main menu
  elif [[ $state != "RUNNING" ]]
  then
    echo -e "${RED}The VM is not Running!${NC} Exiting to main menu..."

  else
    
    # Check if VM not generating traffic
    val=$(cat tmp/temp | grep $ip | awk '{print $9}')
    val1=$(cat tmp/temp | grep $ip | awk '{print $3}')
    val2=$(cat tmp/temp | grep $ip | awk '{print $5}')
    if ! [[ "$val" == "D-ITG" && "$val1" == "---" && "$val2" == "---" ]]; then
      echo "The VM is not generating/generating non-DITG traffic. Exiting to main menu..."
      return
    fi 

    # Prompt for Username
    echo "Please enter the VM's username:"
    read username

    # If Username empty, re-prompt
    while [[ -z "$username" ]]; do
      echo "Username can't be empty! Please try again."
      echo
      echo "Please enter the VM's username:"
      read username
    done

    # Prompt for Password
    echo "Please enter the VM's password:"
    read password

    # If Password empty, re-prompt
    while [[ -z "$password" ]]; do
      echo "Password can't be empty! Please try again."
      echo
      echo "Please enter the VM's password:"
      read password
    done

    # Check SSH connection
    sshpass -p "$password" ssh -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -t -l ${username} ${ip} "exit"

    # If SSH invalid, exit to main menu
    if ! [[ $? -eq 0 ]]; then
      echo -e "${RED}Invalid Username/Password entered for${NC} $ip. Exiting to main menu..."
      return
    fi
   
    # Stop ITGSend
    echo "Stopping ITGSend in $ip"
    echo "#!/bin/bash
            tmux kill-session -t ITGSend
            " > tmp/ITGSendStop.sh
    sshpass -p "$password" scp -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null  tmp/ITGSendStop.sh $username@$ip:


    SCRIPT="chmod +x ITGSendStop.sh; echo $password | sudo -S ./ITGSendStop.sh;  "
    sshpass -p "$password" ssh -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -t -l ${username} ${ip} "${SCRIPT}"

    # Stop ITGRecv
    echo "#!/bin/bash
            tmux kill-session -t ITGRecv 
            " > tmp/ITGRecvStop.sh
    sshpass -p "$password" scp -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null  tmp/ITGRecvStop.sh $username@$ip:

    echo "Stopping ITGRecv in $ip"
    SCRIPT="chmod +x ITGRecvStop.sh; echo $password | sudo -S ./ITGRecvStop.sh  "
    sshpass -p "$password" ssh -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -t -l ${username} ${ip} "${SCRIPT}"

    # Update the tmp/temp file
    sed -i "/\b${ip}\b/d" tmp/temp
    str=$ip
    str+="	    	|	    	N/A	    	|   		N/A   		|       N/A       |       N/A       "
    echo $str >> tmp/temp

    echo
    echo "Stopped!"
    echo
  fi
}

# Function that handles Different OPTIONS for Running D-ITG in a VM

function case9bc() { 
  # Prompt
  echo 
  echo -e "${GREEN}OPTIONS:${NC}"
  echo "------------------------------------"
  echo "1- Run D-ITG"
  echo "2- View D-ITG Recv Help File"
  echo "3- View D-ITG Send Help File"
  echo "4- Exit to main menu"
  echo "------------------------------------"
  echo "Please enter your choice:"
  echo -n "---> "
  read choice
  if [[ $choice == 1 ]]; then
    case9bca
  elif [[ $choice == 2 ]]; then
    cat tmp/ITGRecvHelp
  elif [[ $choice == 3 ]]; then
    cat tmp/ITGSendHelp
  elif [[ $choice == 4 ]]; then
    return
  else
    echo -e "${RED}Invalid choice entered!${NC} Exiting to Main Menu..."
  fi 
}

function case9be() {
  # Prompt for IP Address of the VM
  echo
  echo "Please enter the VM's ip address you want to start Traffic Generation (using PCAPs) in:"
  read HOST

  # Re-prompt
  while ! [[ $HOST =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; do
    echo "Invaid IP address entered. Please try again!"
    echo
    echo "Please enter the VM's ip address you want to start Traffic Generation (using PCAPs) in:"
    read HOST
  done
  
  
  state=$(minimega -e vm info | grep $HOST | awk '{print $7}')
  
  # Check if VM exists
  if [[ "$state" == ""  ]]
  then
    echo "Such VM doesn't exist! Exiting to main menu..."

  # Check if VM in RUNNING state

  elif [[ "$state" != "RUNNING" ]]
  then
    echo "The VM is not running. Exiting to main menu..."

  else
   
    # Check if VM generating traffic
    val=$(cat tmp/temp | grep $HOST | awk '{print $9}')

    if [[ "$val" == "N/A" ]]
    then

      # Prompt for Username
      echo "Please enter the VM's username:"
      read USERNAME

      # If Username empty, re-prompt
      while [[ -z "$USERNAME" ]]; do
        echo "Username can't be empty! Please try again."
        echo
        echo "Please enter the VM's username:"
        read USERNAME
      done

      # Prompt for Password
      echo "Please enter the VM's password:"
      read PASSWORD

      # If Password empty, re-prompt
      while [[ -z "$PASSWORD" ]]; do
        echo "Password can't be empty! Please try again."
        echo
        echo "Please enter the VM's password:"
        read PASSWORD
      done
    
      # Check SSH connection
      sshpass -p "$PASSWORD" ssh -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -t -l ${USERNAME} ${HOST} "exit"

      # If SSH invalid, exit to main menu
      if [[ $? -eq 0 ]]
      then
       
        # Print the interfaces and prompt
        echo "The VM has the following network interfaces:"
        echo
        sshpass -p "$PASSWORD" ssh -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -t -l ${USERNAME} ${HOST} "ifconfig"
        echo
        echo "Please enter the interface: "
        read interface

        # If Interface empty, re-prompt
        while [[ -z "$interface" ]]; do
          echo "Password can't be empty! Please try again."
          echo
          echo "Please enter the interface: "
          read interface
        done

        # Build the script

        echo "#!/bin/bash
            cd NetworkWrapper/
            tmux new-session -d -s TrafficGen \; send-keys \"python3 /home/$USERNAME/NetworkWrapper/wrap.py $interface --realistic\" Enter
            " > tmp/NTGStart.sh

        # Copy the script to the VM

        sshpass -p "$PASSWORD" scp -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null  tmp/NTGStart.sh $USERNAME@$HOST:

        echo "Starting Network Traffic Generation in $HOST"
        SCRIPT="chmod +x NTGStart.sh; echo $PASSWORD | sudo -S ./NTGStart.sh"
        sshpass -p "$PASSWORD" ssh -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -t -l ${USERNAME} ${HOST} "${SCRIPT}"

        # Update the tmp/temp file
        sed -i "/\b${HOST}\b/d" tmp/temp
        str=$HOST
        str+="		|		$HOST		|		$HOST		|		$interface		|   NetworkWrapper (PCAPs)"
        echo $str >> tmp/temp

        echo "Started"
      else
        echo -e "${RED}Invalid Username/Password for${NC} $HOST. Exiting to main menu..."
        return
      fi
    else
      echo "The VM is already generating traffic."
    fi
  fi
}

function case9bf() {
  
  # Prompt for IP Address of the VM
  echo
  echo "Please enter the VM's ip address you want to stop Traffic Generation(using PCAPs) in:"
  read HOST

  # Re-prompt
  while ! [[ $HOST =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; do
    echo "Invaid IP address entered. Please try again!"
    echo
    echo "Please enter the VM's ip address you want to stop Traffic Generation(using PCAPs) in:"
    read HOST
  done
  
  state=$(minimega -e vm info | grep $HOST | awk '{print $7}')
  
  # Check if VM exists
  if [[ "$state" == "" ]]
  then
    echo "Such VM doesn't exist! Exiting to main menu..."

  # Check if VM in RUNNING state

  elif [[ "$state" != "RUNNING" ]]
  then
    echo "The VM is not running. Exiting to main menu..."

  else
   
    # Check if VM generating traffic
    val=$(cat tmp/temp | grep $HOST | awk '{print $9}')
    val1=$(cat tmp/temp | grep $HOST | awk '{print $3}')
    val2=$(cat tmp/temp | grep $HOST | awk '{print $5}')

    if [[ "$val" == "NetworkWrapper (PCAPs)" && "$val1" == "$HOST" && "$val2" == "$HOST" ]]
    then

      # Prompt for Username
      echo "Please enter the VM's username:"
      read USERNAME

      # If Username empty, re-prompt
      while [[ -z "$USERNAME" ]]; do
        echo "Username can't be empty! Please try again."
        echo
        echo "Please enter the VM's username:"
        read USERNAME
      done

      # Prompt for Password
      echo "Please enter the VM's password:"
      read PASSWORD

      # If Password empty, re-prompt
      while [[ -z "$PASSWORD" ]]; do
        echo "Password can't be empty! Please try again."
        echo
        echo "Please enter the VM's password:"
        read PASSWORD
      done
    
      # Check SSH connection
      sshpass -p "$PASSWORD" ssh -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -t -l ${USERNAME} ${HOST} "exit"

      # If SSH invalid, exit to main menu
      if [[ $? -eq 0 ]]
      then
        # Build the script

        echo "#!/bin/bash
            tmux kill-session -t TrafficGen
            " > tmp/NTGStop.sh

        # Copy the script to the VM

        sshpass -p "$PASSWORD" scp -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null  tmp/NTGStop.sh $USERNAME@$HOST:

        echo "Stopping Network Traffic Generation in $HOST"
        SCRIPT="chmod +x NTGStop.sh; echo $PASSWORD | sudo -S ./NTGStop.sh"
        sshpass -p "$PASSWORD" ssh -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -t -l ${USERNAME} ${HOST} "${SCRIPT}"

        # Update the tmp/temp file
        sed -i "/\b${HOST}\b/d" tmp/temp
        str=$HOST
        str+="		|		N/A		|		N/A		|		N/A		|   N/A"
        echo $str >> tmp/temp
        
        echo "Stopped"
      else
        echo -e "${RED}Invalid Username/Password for${NC} $HOST. Exiting to main menu..."
        return
      fi
    else
      echo "The VM is not generating NetworkWrapper traffic (using PCAPs) within itself. Exiting to main menu..."
      return
    fi
  fi
}

# Function that displays the Network Traffic generation status

function case9a() {
  echo -e "${YELLOW}=================================================================================="
  echo -e "==========================${CYAN} VM TRAFFIC GENERATION STATUS ${YELLOW}=========================="
  echo -e "==================================================================================${NC}"
  echo
  column -t -s ' ' tmp/temp
  echo
}

# Function that generates Traffic within a VM

function case9b() {
  echo 
  echo -e "${GREEN}OPTIONS:${NC}"
  echo "-------------------------------------------------"
  echo "1- Start Traffic Generation (using tools) in a VM"
  echo "2- Stop Traffic Generation (using tools) in a VM"
  echo "3- Start D-ITG in a VM"
  echo "4- Stop D-ITG in a VM" 
  echo "5- Start Traffic Generation (using PCAPs) in a VM"
  echo "6- Stop Traffic Generation (using PCAPs) in a VM"
  echo "7- Exit to main menu"
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
  elif [[ $choice == 3 ]]
  then
    case9bc
  elif [[ $choice == 4 ]]
  then
    case9bd
  elif [[ $choice == 5 ]]
  then
    case9be
  elif [[ $choice == 6 ]]
  then
    case9bf
  elif [[ $choice == 7 ]]
  then
    echo "Exiting to main menu..."
    return
  else
    echo -e "${RED}Invalid choice entered!${NC} Exiting to Main Menu..."
  fi
}

# Function that starts Network Traffic Generation between VMs

function case9ca() {
  
  # Prompt for HOST IP
  echo
  echo "Please enter the HOST VM's ip address you want to start Traffic Generation (using Tools) from:"
  read HOST

  # Re-prompt
  while ! [[ $HOST =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; do
    echo "Invaid IP address entered. Please try again!"
    echo
    echo "Please enter the HOST VM's ip address you want to start Traffic Generation (using Tools) from:"
    read HOST
  done

  # Prompt for DEST IP
  echo
  echo "Please enter the DEST VM's ip address you want to start Traffic Generation (using Tools) to:"
  read DEST

  # Re-prompt
  while ! [[ $HOST =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; do
    echo "Invaid IP address entered. Please try again!"
    echo
    echo "Please enter the DEST VM's ip address you want to start Traffic Generation (using Tools) to:"
    read DEST
  done

  # Check if VMs Exist
  state=$(minimega -e vm info | grep $HOST | awk '{print $7}')
  state1=$(minimega -e vm info | grep $DEST | awk '{print $7}')

  if ! [[ "$state" == "RUNNING" && "$state1" == "RUNNING" ]]
  then
    echo "One or more VM(s) don't exist/aren't running. Exiting to main menu..."
  else

    val=$(cat tmp/temp | grep $HOST | awk '{print $9}')
    val1=$(cat tmp/temp | grep $DEST | awk '{print $9}')

    if [[ "$val" == "N/A" && "$val1" == "N/A" ]]
    then

      # Prompt for HOST and DEST VM Username and Password
      echo "Please enter the HOST VM's username:"
      read H_USERNAME

      # Re-prompt
      while [[ -z "$H_USERNAME" ]]; do
        echo "The username can't be empty. Please try again!"
        echo
        echo "Please enter the HOST VM's username:"
        read H_USERNAME
      done

      # Prompt for HOST and DEST VM Username and Password
      echo "Please enter the HOST VM's password:"
      read H_PASSWORD

      # Re-prompt
      while [[ -z "$H_PASSWORD" ]]; do
        echo "The password can't be empty. Please try again!"
        echo
        echo "Please enter the HOST VM's password:"
        read H_PASSWORD
      done

      # Prompt for HOST and DEST VM Username and Password
      echo "Please enter the DEST VM's username:"
      read D_USERNAME

      # Re-prompt
      while [[ -z "$D_USERNAME" ]]; do
        echo "The username can't be empty. Please try again!"
        echo
        echo "Please enter the DEST VM's username:"
        read D_USERNAME
      done

      # Prompt for HOST and DEST VM Username and Password
      echo "Please enter the DEST VM's password:"
      read D_PASSWORD

      # Re-prompt
      while [[ -z "$D_PASSWORD" ]]; do
        echo "The password can't be empty. Please try again!"
        echo
        echo "Please enter the DEST VM's password:"
        read D_PASSWORD
      done

      # Check HOST VM SSH Authentication
      sshpass -p "$H_PASSWORD" ssh -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -t -l ${H_USERNAME} ${HOST} "exit"
      check1=$?

      # Check DEST VM SSH Authentication
      sshpass -p "$D_PASSWORD" ssh -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -t -l ${D_USERNAME} ${DEST} "exit"
      check2=$?

      # If both SSH valid
      if [[ check1 -eq 0 && check2 -eq 0 ]]
      then
        
        # Prompt for Interface
        echo "The DEST VM has the following network interfaces:"
        echo
        sshpass -p "$D_PASSWORD" ssh -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -t -l ${D_USERNAME} ${DEST} "ifconfig"
        echo 
        echo "Please enter the interface: "
        read interface

        # Build the script and copy to VM
        echo "#!/bin/bash
            sudo tmux new-session -d -s TrafficGen \; send-keys \"python3 /home/$H_USERNAME/NetworkWrapper/wrap.py $interface --dest $DEST \" Enter
            " > tmp/NTGStartH.sh
        sshpass -p "$H_PASSWORD" scp -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null  tmp/NTGStartH.sh $H_USERNAME@$HOST:
        
        # Build the script and copy to VM
        echo "#!/bin/bash
            tmux new-session -d -s TrafficGen \; send-keys \"ITGRecv -l Traffic.log \" Enter
            " > tmp/NTGStartD.sh
        sshpass -p "$D_PASSWORD" scp -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null tmp/NTGStartD.sh $D_USERNAME@$DEST:
    
        # Start the Receiver
        echo "Starting the receiver in $DEST"
        SCRIPT="chmod +x NTGStartD.sh; echo $D_PASSWORD | sudo -S ./NTGStartD.sh  "
        sshpass -p "$D_PASSWORD" ssh -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -t -l ${D_USERNAME} ${DEST} "${SCRIPT}"

        # Start the Sender
        echo "Starting Network Traffic Generation from $HOST to $DEST"
        SCRIPT="chmod +x NTGStartH.sh; echo $H_PASSWORD | sudo -S ./NTGStartH.sh  "
        sshpass -p "$H_PASSWORD" ssh -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -t -l ${H_USERNAME} ${HOST} "${SCRIPT}"

        # Update tmp/temp file
        sed -i "/\b${HOST}\b/d" tmp/temp
        sed -i "/\b${DEST}\b/d" tmp/temp
        str=$HOST
        str+="		|		---		|		$DEST		|       ---       |       NetworkWrapper (Tools)      "
        echo $str >> tmp/temp
        str=$DEST
        str+="		|		$HOST		|		---		|		$interface		|       NetworkWrapper (Tools)       "
        echo $str >> tmp/temp
        echo "Started"

      else
        echo -e "${RED}Invalid Username/Password for${NC} one of the VMs. Exiting to main menu..."
      fi
    else
      echo "One or both VM(s) is/are already generating traffic. Exiting to main menu..."
    fi
  fi
}

# Function that Stops Wrapper Traffic Generation b/w VMs

function case9cb() {

  # Prompt for HOST IP
  echo
  echo "Please enter the HOST VM's ip address you want to start Traffic Generation from:"
  read HOST

  # Re-prompt
  while ! [[ $HOST =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; do
    echo "Invaid IP address entered. Please try again!"
    echo
    echo "Please enter the HOST VM's ip address you want to start Traffic Generation from:"
    read HOST
  done

 # Prompt for DEST IP
  echo
  echo "Please enter the DEST VM's ip address you want to start Traffic Generation to:"
  read DeST

  # Re-prompt
  while ! [[ $HOST =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; do
    echo "Invaid IP address entered. Please try again!"
    echo
    echo "Please enter the DEST VM's ip address you want to start Traffic Generation to:"
    read DEST
  done

  # Check if VMs Exist
  state=$(minimega -e vm info | grep $HOST | awk '{print $7}')
  state1=$(minimega -e vm info | grep $DEST | awk '{print $7}')
  if [[ "$state" != "RUNNING" || "$state1" != "RUNNING" ]]
  then
    echo "One or more VM(s) don't exist/aren't running. Exiting to main menu..."
  else
    
    # Check if the VMs are generating inter-VM traffic
    count=$(cat tmp/temp | grep $HOST | wc -l)
    count1=$(cat tmp/temp | grep $DEST | wc -l)
    if [[ $count != 2 || $count1 != 2 ]]
    then
      echo -e "${RED}One of the VMs is not generating or is generating single traffic.${NC} Exiting to main menu..."
      return
    fi

    # Check if the VMs are generating traffic to each other or not
    src="src"
    dest="dest"
    valid=0
    valid1=0
    for (( i=1; i<3; i++ ))
    do
      val=$(cat tmp/temp | grep $HOST | awk 'NR=='$i'{print$3}')
      val1=$(cat tmp/temp | grep $HOST | awk 'NR=='$i'{print$5}')
      if [[ "$val" == "---" && "$val1" == $DEST ]]
      then
        valid=1
      fi
      if [[ "$val1" == "---" && "$val" == $HOST ]]
      then
        valid1=1
      fi
    done
   
    if [[ $valid == 1 && $valid1 == 1 ]]
    then
      
      # Prompt for HOST and DEST VM Username and Password
      echo "Please enter the HOST VM's username:"
      read H_USERNAME

      # Re-prompt
      while [[ -z "$H_USERNAME" ]]; do
        echo "The username can't be empty. Please try again!"
        echo
        echo "Please enter the HOST VM's username:"
        read H_USERNAME
      done

      # Prompt for HOST and DEST VM Username and Password
      echo "Please enter the HOST VM's password:"
      read H_PASSWORD

      # Re-prompt
      while [[ -z "$H_PASSWORD" ]]; do
        echo "The password can't be empty. Please try again!"
        echo
        echo "Please enter the HOST VM's password:"
        read H_PASSWORD
      done

      # Prompt for HOST and DEST VM Username and Password
      echo "Please enter the DEST VM's username:"
      read D_USERNAME

      # Re-prompt
      while [[ -z "$D_USERNAME" ]]; do
        echo "The username can't be empty. Please try again!"
        echo
        echo "Please enter the DEST VM's username:"
        read D_USERNAME
      done

      # Prompt for HOST and DEST VM Username and Password
      echo "Please enter the DEST VM's password:"
      read D_PASSWORD

      # Re-prompt
      while [[ -z "$D_PASSWORD" ]]; do
        echo "The password can't be empty. Please try again!"
        echo
        echo "Please enter the DEST VM's password:"
        read D_PASSWORD
      done

      # Check HOST VM SSH Authentication
      sshpass -p "$H_PASSWORD" ssh -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -t -l ${H_USERNAME} ${HOST} "exit"
      check1=$?

      # Check DEST VM SSH Authentication
      sshpass -p "$D_PASSWORD" ssh -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -t -l ${D_USERNAME} ${DEST} "exit"
      check2=$?

      # If both SSH Valid
      if [[ check1 -eq 0 && check2 -eq 0 ]]
      then
        
        # Build the script and Copy to HOST VM
        echo 
        echo "#!/bin/bash
            sudo tmux kill-session -t TrafficGen
            " > tmp/NTGStopH.sh
        sshpass -p "$H_PASSWORD" scp -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null  tmp/NTGStopH.sh $H_USERNAME@$HOST:
        
        # Build the script and Copy to DEST VM
        echo "#!/bin/bash
            tmux kill-session -t TrafficGen
            " > tmp/NTGStopD.sh
        sshpass -p "$D_PASSWORD" scp -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null  tmp/NTGStopD.sh $D_USERNAME@$DEST:

        echo "Stopping Network Traffic Generation from $HOST to $DEST"
        SCRIPT="chmod +x NTGStopH.sh; echo $H_PASSWORD | sudo -S ./NTGStop.sh  "
        sshpass -p "$H_PASSWORD" ssh -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -t -l ${H_USERNAME} ${HOST} "${SCRIPT}"

        echo "Stopping the receiver in $DEST"
        SCRIPT="chmod +x NTGStopD.sh; echo $D_PASSWORD | sudo -S ./NTGStopD.sh  "
        sshpass -p "$D_PASSWORD" ssh -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -t -l ${D_USERNAME} ${DEST} "${SCRIPT}"

        # Update the temo file
        sed -i "/\b${HOST}\b/d" tmp/temp
        str=$HOST
        str+="		|		N/A		|		N/A		|		N/A		|   N/A"
        echo $str >> tmp/temp
        str=$DEST
        str+="		|		N/A		|		N/A		|		N/A		|   N/A"
        echo $str >> tmp/temp
        echo "Stopped"

      else
        echo -e "${RED}Invalid Username/Password for${NC} one of the VMs. Exiting to main menu..."
      fi
    else
      echo -e "${RED}Doesn't look like $HOST is generating traffic to $DEST.${NC} Exiting to main menu..."
    fi
  fi
}

# Function that starts D-ITG between VMs

function case9cc() {
  # Prompt for HOST VM's IP address
  echo "Please enter the HOST VM's IP address where you would like to run ITGSend:"
  read host

  #Re-prompt until valid input
  while ! [[ $ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; do
    echo "Invaid IP address entered! Please try again."
    echo
    echo "Please enter the HOST VM's IP address where you would like to run ITGSend:"
    read host
  done

  # Prompt for DEST VM's IP address
  echo "Please enter the DEST VM's IP address where you would like to run ITGRecv:"
  read dest

  #Re-prompt until valid input
  while ! [[ $ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; do
    echo "Invaid IP address entered! Please try again."
    echo
    echo "Please enter the DEST VM's IP address where you would like to run ITGRecv:"
    read dest
  done
  
  # Get State of VMs
  state=$(minimega -e vm info | grep $host | awk '{print $7}')
  state1=$(minimega -e vm info | grep $dest | awk '{print $7}')

  # Check if VM Exists or not
  if [[ "$state" == ""  || "$state1" == "" ]]
  then
    echo -e "${RED}One or more VMs don't exist!${NC} Exiting to main menu..."

  # If not RUNNING, exit to main menu
  elif [[ $state != "RUNNING" ||  $state1 != "RUNNING" ]]
  then
    echo -e "${RED}One or more VM(s) is/are not Running!${NC} Exiting to main menu..."

  else
    
    # Check if VM already generating traffic
    val=$(cat tmp/temp | grep $host | awk '{print $9}')
    if [[ "$val" != "N/A" ]]; then
      echo "$host is already generating traffic. Exiting to main menu..."
      return
    fi

    # Check if VM already generating traffic
    val=$(cat tmp/temp | grep $dest | awk '{print $9}')
    if [[ "$val" != "N/A" ]]; then
      echo "$dest is already generating traffic. Exiting to main menu..."
      return
    fi 

    # Prompt for Username
    echo "Please enter the HOST VM's username:"
    read username

    # If Username empty, re-prompt
    while [[ -z "$username" ]]; do
      echo "Username can't be empty! Please try again."
      echo
      echo "Please enter the HOST VM's username:"
      read username
    done

    # Prompt for Password
    echo "Please enter the HOST VM's password:"
    read password

    # If Password empty, re-prompt
    while [[ -z "$password" ]]; do
      echo "Password can't be empty! Please try again."
      echo
      echo "Please enter the HOST VM's password:"
      read password
    done

    # Prompt for Username
    echo "Please enter the DEST VM's username:"
    read usernameD

    # If Username empty, re-prompt
    while [[ -z "$usernameD" ]]; do
      echo "Username can't be empty! Please try again."
      echo
      echo "Please enter the DEST VM's username:"
      read usernameD
    done

    # Prompt for Password
    echo "Please enter the DEST VM's password:"
    read passwordD

    # If Password empty, re-prompt
    while [[ -z "$passwordD" ]]; do
      echo "Password can't be empty! Please try again."
      echo
      echo "Please enter the DEST VM's password:"
      read passwordD
    done

    # Check SSH connection for HOST
    sshpass -p "$password" ssh -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -t -l ${username} ${host} "exit"

    # If SSH invalid, exit to main menu
    if ! [[ $? -eq 0 ]]; then
      echo -e "${RED}Invalid Username/Password for${NC} $host. Exiting to main menu..."
      return
    fi

    # Check SSH connection for DEST
    sshpass -p "$passwordD" ssh -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -t -l ${usernameD} ${dest} "exit"

    # If SSH invalid, exit to main menu
    if ! [[ $? -eq 0 ]]; then
      echo -e "${RED}Invalid Username/Password for${NC} $dest. Exiting to main menu..."
      return
    fi
   
    # Prompt to enter ITGRecv Command
    echo "Please enter the ITGRecv command to run in $dest:"
    read ITGRecvCommand

    # If command empty, re-prompt
    while [[ -z "$ITGRecvCommand" ]]; do
      echo "Command can't be empty! Please try again."
      echo
      echo "Please enter the ITGRecv command"
      read ITGRecvCommand
    done
    
    # Check if command is valid
    tmux new-session -d -s ITGRecv '$ITGRecvCommand > out'
    sleep 0.5
    a=$(tmux ls | grep ITGRecv | wc -l)

    if [[ $a != 0 ]]; then
      tmux kill-session -t ITGRecv
    fi

    a = $(cat out | grep "Try again")

    if [[ -z "$a" ]]; then
      echo -e "${RED}Invalid command entered!${NC} Exiting to main menu..."  
      return
    fi

    # Start ITGRecv in Dest
    echo "#!/bin/bash
            tmux new-session -d -s ITGRecv \; send-keys \"$ITGRecvCommand \" Enter
            " > tmp/ITGRecvStart.sh
    sshpass -p "$passwordD" scp -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null  tmp/ITGRecvStart.sh $usernameD@$dest:

    echo "Starting ITGRecv in $host"
    SCRIPT="chmod +x ITGRecvStart.sh; echo $passwordD | sudo -S ./ITGRecvStart.sh  "
    sshpass -p "$passwordD" ssh -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -t -l ${usernameD} ${dest} "${SCRIPT}"
    echo
    echo "Please enter the ITGSend command to start in $host" 
    read ITGSendCommand

    # If command empty, re-prompt
    while [[ -z "$ITGSendCommand" ]]; do
      echo "Command can't be empty! Please try again."
      echo
      echo "Please enter the ITGSend command to start in $host" 
      read ITGSendCommand
    done


    # Check if command is valid
    tmux new-session -d -s ITGSend "$ITGSendCommand > out"
    sleep 0.5
    a=$(tmux ls | grep ITGSend | wc -l)
    if [[ $a != 0 ]]; then
      tmux kill-session -t ITGSend
    fi

    a=$(cat out | grep 'for help' out | wc -l)

    if [[ $a -gt 0 ]]; then
      echo -e "${RED}Invalid command entered!${NC} Exiting to main menu..."  
      return
    fi

    # Start ITGSend in Host
    echo "Starting ITGSend in $host"
    echo "#!/bin/bash
            tmux new-session -d -s ITGSend \; send-keys \"$ITGSendCommand \" Enter
            " > tmp/ITGSendStart.sh
    sshpass -p "$password" scp -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null  tmp/ITGSendStart.sh $username@$host:

    SCRIPT="chmod +x ITGSendStart.sh; echo $password | sudo -S ./ITGSendStart.sh  "
    sshpass -p "$password" ssh -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -t -l ${username} ${host} "${SCRIPT}"

    # Update the tmp/temp file
    sed -i "/\b${host}\b/d" tmp/temp
    sed -i "/\b${dest}\b/d" tmp/temp
    str=$host
    str+="		|		---		|		$dest		|       ---       |       D-ITG       "
    echo $str >> tmp/temp
    str=$dest
    str+="		|		$host		|		---		|		---		|       D-ITG       "
    echo $str >> tmp/temp
    echo "Started"
  fi
}

# Function that stops D-ITG between VMs

function case9cd() {
  # Prompt for HOST VM's IP address
  echo "Please enter the HOST VM's IP address where you would like to stop ITGSend:"
  read host

  #Re-prompt until valid input
  while ! [[ $ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; do
    echo "Invaid IP address entered! Please try again."
    echo
    echo "Please enter the HOST VM's IP address where you would like to stop ITGSend:"
    read host
  done

  # Prompt for DEST VM's IP address
  echo "Please enter the DEST VM's IP address where you would like to stop ITGRecv:"
  read dest

  #Re-prompt until valid input
  while ! [[ $ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; do
    echo "Invaid IP address entered! Please try again."
    echo
    echo "Please enter the DEST VM's IP address where you would like to stop ITGRecv:"
    read dest
  done
  
  # Get State of VMs
  state=$(minimega -e vm info | grep $host | awk '{print $7}')
  state1=$(minimega -e vm info | grep $dest | awk '{print $7}')

  # Check if VM Exists or not
  if [[ "$state" == "" || "$state1" == "" ]]
  then
    echo -e "${RED}One or more VMs don't exist!${NC} Exiting to main menu..."

  # If not RUNNING, exit to main menu
  elif [[ $state != "RUNNING" ||  $state1 != "RUNNING" ]]
  then
    echo -e "${RED}One or more VM(s) is/are not Running!${NC} Exiting to main menu..."

  else
    # Check if VM  generating traffic
    val=$(cat tmp/temp | grep $host | awk '{print $9}')
    if [[ "$val" != "D-ITG" ]]; then
      echo "$host is not generating D-ITG traffic. Exiting to main menu..."
      return
    fi

    # Check if VM  generating traffic
    val=$(cat tmp/temp | grep $dest | awk '{print $9}')
    if [[ "$val" != "D-ITG" ]]; then
      echo "$dest is not generating D-ITG traffic. Exiting to main menu..."
      return
    fi 

    # Check if the VMs are generating traffic to each other or not
    for (( i=1; i<3; i++ ))
    do
      val=$(cat tmp/temp | grep $host | awk 'NR=='$i'{print$3}')
      val1=$(cat tmp/temp | grep $host | awk 'NR=='$i'{print$5}')
      if [[ "$val" == "---" && "$val1" == $dest ]]
      then
        valid=1
      fi
      if [[ "$val1" == "---" && "$val" == $host ]]
      then
        valid1=1
      fi
    done

    # If not, then exit
    if ! [[ $valid == 1 && $valid1 == 1 ]]; then
      echo "Doesn't look like there is D-ITG Traffic Generation between $host and $dest! Exiting to main menu..."
      return
    fi

    # Prompt for Username
    echo "Please enter the HOST VM's username:"
    read username

    # If Username empty, re-prompt
    while [[ -z "$username" ]]; do
      echo "Username can't be empty! Please try again."
      echo
      echo "Please enter the HOST VM's username:"
      read username
    done

    # Prompt for Password
    echo "Please enter the HOST VM's password:"
    read password

    # If Password empty, re-prompt
    while [[ -z "$password" ]]; do
      echo "Password can't be empty! Please try again."
      echo
      echo "Please enter the HOST VM's password:"
      read password
    done

    # Prompt for Username
    echo "Please enter the DEST VM's username:"
    read usernameD

    # If Username empty, re-prompt
    while [[ -z "$usernameD" ]]; do
      echo "Username can't be empty! Please try again."
      echo
      echo "Please enter the DEST VM's username:"
      read usernameD
    done

    # Prompt for Password
    echo "Please enter the DEST VM's password:"
    read passwordD

    # If Password empty, re-prompt
    while [[ -z "$passwordD" ]]; do
      echo "Password can't be empty! Please try again."
      echo
      echo "Please enter the DEST VM's password:"
      read passwordD
    done

    # Check SSH connection for HOST
    sshpass -p "$password" ssh -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -t -l ${username} ${host} "exit"

    # If SSH invalid, exit to main menu
    if ! [[ $? -eq 0 ]]; then
      echo -e "${RED}Invalid Username/Password for${NC} $host. Exiting to main menu..."
      return
    fi

    # Check SSH connection for DEST
    sshpass -p "$passwordD" ssh -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -t -l ${usernameD} ${dest} "exit"

    # If SSH invalid, exit to main menu
    if ! [[ $? -eq 0 ]]; then
      echo -e "${RED}Invalid Username/Password for${NC} $dest. Exiting to main menu..."
      return
    fi

    # Stop ITGSend in Host
    echo "Stopping ITGSend in $host"
    echo "#!/bin/bash
            tmux kill-session -t ITGSend
            " > tmp/ITGSendStop.sh
    sshpass -p "$password" scp -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null  tmp/ITGSendStop.sh $username@$host:

    SCRIPT="chmod +x ITGSendStop.sh; echo $password | sudo -S ./ITGSendStop.sh  "
    sshpass -p "$password" ssh -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -t -l ${username} ${host} "${SCRIPT}"
   
    # Stop ITGRecv in Dest
    echo "Stopping ITGRecv in $host"

    # Build Script
    echo "#!/bin/bash
            tmux kill-session -t ITGRecv
            " > tmp/ITGRecvStop.sh
    sshpass -p "$passwordD" scp -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null  tmp/ITGRecvStop.sh $usernameD@$dest:

    # Kill the tmux process
    SCRIPT="chmod +x ITGRecvStop.sh; echo $passwordD | sudo -S ./ITGRecvStop.sh  "
    sshpass -p "$passwordD" ssh -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -t -l ${usernameD} ${dest} "${SCRIPT}"

    # Update the tmp/temp file
    sed -i "/\b${host}\b/d" tmp/temp
    sed -i "/\b${dest}\b/d" tmp/temp
    str=$host
    str+="		|	  	N/A	  	|		  N/A	  	|     N/A     |       N/A       "
    echo $str >> tmp/temp
    str=$dest
    str+="		|	  	N/A	  	|	  	N/A 		|	  	N/A		  |       N/A       "
    echo $str >> tmp/temp
    echo "Stopped"
  fi
}



# Function that handles Cross-VM Traffic Generation

function case9c() {

  # Prompt for OPTIONS
  echo 
  echo -e "${GREEN}OPTIONS:${NC}"
  echo "----------------------------------------"
  echo "1- Start Traffic Generation from/to a VM"
  echo "2- Stop Traffic Generation from/to a VM"
  echo "3- Start D-ITG between VMs"
  echo "4- Stop D-ITG between VMs"
  echo "5- Exit to main menu"
  echo "----------------------------------------"
  echo "Please enter your choice:"
  echo -n "---> "
  read choice
  if [[ $choice == 1 ]]
  then
    case9ca
  elif [[ $choice == 2 ]]
  then
    case9cb
  elif [[ $choice == 3 ]]
  then
    case9cc
  elif [[ $choice == 4 ]]
  then
    case9cd
  elif [[ $choice == 5 ]]
  then
    echo "Exiting to main menu..."
    return
  else
    echo -e "${RED}Invalid choice entered!${NC} Exiting to Main Menu..."
  fi
}

# Function that deals with starting Replaying PCAP Files in a VM

function case9d() {

  # Prompt for VM's IP address
  echo "Please enter the VM's IP address where you would like to replay PCAP file:"
  read ip

  #Re-prompt until valid input
  while ! [[ $ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; do
    echo "Invaid IP address entered! Please try again."
    echo
    echo "Please enter the VM's IP address where you would like to generate traffic using D-ITG:"
    read ip
  done
  
  # Get State of VM
  state=$(minimega -e vm info | grep $ip | awk '{print $7}')

  # Check if VM Exists or not
  if [[ "$state" == "" ]]
  then
    echo -e "${RED}Such VM doesn't exist!${NC} Exiting to main menu..."

  # If not RUNNING, exit to main menu
  elif [[ $state != "RUNNING" ]]
  then
    echo -e "${RED}The VM is not Running!${NC} Exiting to main menu..."

  else
    
    # Check if VM already generating traffic or replaying
    val=$(cat tmp/temp | grep $ip | awk '{print $9}')
    if [[ "$val" != "N/A" ]]; then
      echo "The VM is already generating traffic/replaying PCAP file. Exiting to main menu..."
      return
    fi 

    # Prompt for Username
    echo "Please enter the VM's username:"
    read username

    # If Username empty, re-prompt
    while [[ -z "$username" ]]; do
      echo "Username can't be empty! Please try again."
      echo
      echo "Please enter the VM's username:"
      read username
    done

    # Prompt for Password
    echo "Please enter the VM's password:"
    read password

    # If Password empty, re-prompt
    while [[ -z "$password" ]]; do
      echo "Password can't be empty! Please try again."
      echo
      echo "Please enter the VM's password:"
      read password
    done

    # Check SSH connection
    sshpass -p "$password" ssh -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -t -l ${username} ${ip} "exit"

    # If SSH invalid, exit to main menu
    if ! [[ $? -eq 0 ]]; then
      echo -e "${RED}Invalid Username/Password entered for${NC} $ip. Exiting to main menu..."
      return
    fi

    # Prompt for path to PCAP
    echo "Please enter the path to PCAP file:"
    read path

    # Re-prompt
    while ! [[ -f $path ]]; do
      echo "Inavlid File. Please try again!"
      echo
      echo "Please enter the path to PCAP file:"
      read path
    done
      
    echo "Copying the PCAP file to $ip..."
    sshpass -p "$password" scp -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $path $username@$ip:

    # Print the interfaces and prompt
    echo "The VM has the following network interfaces:"
    echo
    sshpass -p "$password" ssh -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -t -l ${username} ${ip} "ifconfig"
    echo
    echo "Please enter the interface: "
    read interface

    # If Interface empty, re-prompt
    while [[ -z "$interface" ]]; do
      echo "Interface can't be empty! Please try again."
      echo
      echo "Please enter the interface: "
      read interface
    done

    # Build the script
    scriptname=$(basename $path)
    echo "#!/bin/bash
        tmux new-session -d -s ReplayPCAP \; send-keys \"python3 /home/$username/NetworkWrapper/wrap.py $interface --replay $scriptname \" Enter
        " > tmp/ReplayPCAP.sh

    # Copy the script to the VM

    sshpass -p "$password" scp -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null  tmp/ReplayPCAP.sh $username@$ip:

    echo "Replaying PCAP file in $ip"
    SCRIPT="chmod +x ReplayPCAP.sh; echo $password | sudo -S ./ReplayPCAP.sh"
    sshpass -p "$password" ssh -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -t -l ${username} ${ip} "${SCRIPT}"

    # Update the tmp/temp file
    sed -i "/\b${ip}\b/d" tmp/temp
    str=$ip
    str+="		|		---		|		---		|		$interface		|   ReplayPCAP"
    echo $str >> tmp/temp

    echo "Started"
  fi

}

# Function that deals with starting Replaying PCAP Files in a VM

function case9e() {

  # Prompt for VM's IP address
  echo "Please enter the VM's IP address where you would like to stop replaying PCAP file:"
  read ip

  #Re-prompt until valid input
  while ! [[ $ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; do
    echo "Invaid IP address entered! Please try again."
    echo
    echo "Please enter the VM's IP address where you would like to generate traffic using D-ITG:"
    read ip
  done
  
  # Get State of VM
  state=$(minimega -e vm info | grep $ip | awk '{print $7}')

  # Check if VM Exists or not
  if [[ "$state" == "" ]]
  then
    echo -e "${RED}Such VM doesn't exist!${NC} Exiting to main menu..."

  # If not RUNNING, exit to main menu
  elif [[ $state != "RUNNING" ]]
  then
    echo -e "${RED}The VM is not Running!${NC} Exiting to main menu..."

  else
    
    # Check if VM already generating traffic or replaying
    val=$(cat tmp/temp | grep $ip | awk '{print $9}')
    if [[ "$val" != "ReplayPCAP" ]]; then
      echo "The VM is not replaying PCAP file. Exiting to main menu..."
      return
    fi 

    # Prompt for Username
    echo "Please enter the VM's username:"
    read username

    # If Username empty, re-prompt
    while [[ -z "$username" ]]; do
      echo "Username can't be empty! Please try again."
      echo
      echo "Please enter the VM's username:"
      read username
    done

    # Prompt for Password
    echo "Please enter the VM's password:"
    read password

    # If Password empty, re-prompt
    while [[ -z "$password" ]]; do
      echo "Password can't be empty! Please try again."
      echo
      echo "Please enter the VM's password:"
      read password
    done

    # Check SSH connection
    sshpass -p "$password" ssh -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -t -l ${username} ${ip} "exit"

    # If SSH invalid, exit to main menu
    if ! [[ $? -eq 0 ]]; then
      echo -e "${RED}Invalid Username/Password entered for${NC} $ip. Exiting to main menu..."
      return
    fi

    # Build the script
    echo "#!/bin/bash
        tmux kill-session -t ReplayPCAP
        " > tmp/ReplayPCAPS.sh

    # Copy the script to the VM

    sshpass -p "$password" scp -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null  tmp/ReplayPCAPS.sh $username@$ip:

    echo "Stopping replay in $ip"
    SCRIPT="chmod +x ReplayPCAPS.sh; echo $password | sudo -S ./ReplayPCAPS.sh"
    sshpass -p "$password" ssh -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -t -l ${username} ${ip} "${SCRIPT}"

    # Update the tmp/temp file
    sed -i "/\b${ip}\b/d" tmp/temp
    str=$ip
    str+="		|	N/A	|		N/A		|		N/A		|   N/A"
    echo $str >> tmp/temp

    echo "Stopped"
  fi

}

# Function that deals with Traffic Generation 

function case9() {
  cd $dir
  # Prompt
  echo 
  echo -e "${GREEN}OPTIONS:${NC}"
  echo "--------------------------------------"
  echo "1- Network Traffic Generation Status"
  echo "2- VM Network Traffic Generation"
  echo "3- Cross-VM Network Traffic Generation"
  echo "4- Start PCAP file replay in a VM"
  echo "5- Stop PCAP file replay in a VM"
  echo "6- Exit to main menu"
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
  elif [[ $choice == 4 ]]
  then
    case9d
  elif [[ $choice == 5 ]]
  then
    case9e
  elif [[ $choice == 6 ]]
  then
    echo "Exiting to main menu..."
    return
  else
    echo -e "${RED}Invalid choice entered!${NC} Exiting to Main Menu..."
  fi

  # Reverting to the current directory
  cd $dir
}

# Function that deals with System Events Generation

function case10(){
  echo
  echo
  echo -e "${YELLOW}########################## WORK IN PROGRESS ##########################${NC}"
  echo
  echo
}

# Function that deals with Killing Minimega Process

function case11() {

  # Check if Minimega Process exists
  run=$(ps -aux | grep minimega| wc -l)
  if [[ $run == 1 ]]
  then
    echo -e "${RED}Minimega is not running.${NC} Exiting to main menu..."
  else 
    
    # Re-prompt for Caution
    echo -e "${RED}WARNING:${NC} Killing Minimega will close all the VMs and you won't be able to work with the same VMs anymore."
    echo  "Do you wish to continue? (Y/N)"
    read choice
    if [[ $choice == "Y" ]]
    then
     
      # Kill the process
      minimega -e vm kill all
      minimega -e vm flush
      for (( i=1 ; i <= $run; i++ ))
      do
       
        # Loop through the processes. If minimega process exists then kill it
        prog=$(ps -aux | grep minimega | awk 'NR=='$i'{print$11}')
        if [[ "$prog" == "minimega" ]]
        then
          pid=$(ps -aux | grep minimega | awk 'NR=='$i'{print $2}')
          kill $pid
          echo
          echo "Minimega Stopped"
        fi
      done

      # Remove all temporary files
      rm -rf tmp/*

    fi
  fi
}

# Function that deals with Killing Miniweb

function case12() {

  # Checking if Miniweb process exists
  run=$(ps -aux | grep miniweb | wc -l)
  if [[ $run == 1 ]]
  then
    echo -e "${RED}Miniweb is not running.${NC} Exiting to main menu..."
  else
    # Loop through the processes. If miniweb process exists then kill it
    for (( i=1 ; i <= $run; i++ ))
    do
      prog=$(ps -aux | grep bin/miniweb | awk 'NR=='$i'{print$11}')
      if [[ "$prog" == "bin/miniweb" ]]
      then
        pid=$(ps -aux | grep bin/miniweb | awk 'NR=='$i'{print $2}')
        kill $pid
        echo
        echo "Stopped Miniweb."
      fi
   done
  fi
}

# Initialize the tmp/temp File that will help in Traffic Generation

function init_status() {


  if [ ! -f tmp/temp ]
  then
    count=$(minimega -e vm info | wc -l)
    bar=$(minimega -e vm info | awk '{print $2}')
    str="   IP    |   SRC   |   DEST    |   INTERFACE   |   METHOD    "
    echo -e "$str" >> tmp/temp
    echo >> tmp/temp
    echo >> tmp/temp
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
      str+="    |   N/A		|		N/A		|		N/A		|   N/A"
      echo $str >> tmp/temp	
    done
  fi
}

function update_temp() {
    
    # Get the count of VMs
    count=$(minimega -e vm info | wc -l)

    let count=count-1
    for (( i=1; i <=$count; i++ ))
    do
      let row=$i+1
      state=$(minimega -e vm info | awk 'NR=='$row'{print $7}')
      if [[ "$state" != "RUNNING" ]] 
      then
        continue
      fi
      ip=$(minimega -e vm info | awk 'NR=='$row'{print $27}')
      HOST=$(echo ${ip:1:-1})
      exist=$(cat tmp/temp | grep $HOST | wc -l)
      if [[ $exist -gt 0 ]]; then
        continue
      fi
      str="	"
      str+=$(minimega -e vm info | awk 'NR=='$row'{print $27}')
      str+="    |   N/A		|		N/A		|		N/A		|   N/A"
      echo $str >> tmp/temp
    done
     
}

# Check if the user is ROOT or not
if [ "$EUID" -ne 0 ]
then 
  echo -e "${RED}You need to be the root user in order to use SETGen. Please try again as root user!${NC}"
  echo "Exiting..."
  exit
fi

# Save the current Directory
dir=$(pwd)

if ! [[ -d tmp ]]; then
    mkdir tmp
fi

# Prompt for OPTIONS
while true
do 
  run=$(ps -aux | grep miniweb | wc -l)
  if [[ $run -gt 1 && -f tmp/temp ]]
  then
    update_temp
  fi
  echo
  echo -e "${GREEN}OPTIONS:${NC}"
  echo "--------------------------------------------"
  echo "01- Create Virtual Hard Disk(s)"
  echo "02- Delete Virtual Hard Disk(s)"
  echo "03- Start Minimega"
  echo "04- Start Miniweb"
  echo "05- Setup and Start VM(s)"
  echo "06- Install SETGen requirements in the VM(s)"
  echo "07- Copy file to VM(s)"
  echo "08- Execute Script in VM(s)"
  echo "09- Network Traffic Generator Control Panel"
  echo "10- System Events Generator Control Panel"
  echo "11- Kill Minimega"
  echo "12- Kill Miniweb"
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
  elif [[ "$input" == "clear" || "$input" == "Clear" ]]; then
    clear
  else
    echo -e "${RED}Invalid Option.${NC} Please try again!"
    echo
  fi
  sleep 0.5
done
