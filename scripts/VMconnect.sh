#!/bin/bash

if [ "$EUID" -ne 0 ]
then 
  echo "Please run as root"
  exit
fi

if [[ $# != 1  &&  $# != 2 && $# != 3 && $# != 4 ]]
then
  echo "Usage:"
  echo "./VMconnect.sh #_of_VMs"
  echo "./VMconnect.sh #_of_VMs -copy <path_to_file>"
  echo "./VMconnect.sh USERNAME_FILE PASSWD_FILE"
  echo "./VMconnect.sh -copy <path_to_file> USERNAME_FILE PASSWD_FILE"
  echo "./VMconnect.sh #_of_VMs -run <path_to_script>"
  echo "./VMconnect.sh -run <path_to_script> USERNAME_FILE PASSWD_FILE"
  exit
fi

if [[ $# == 1 ]]
then
  for (( i=1; i <= $1; i++ ))
  do
    let row=$i+1
    state=$(minimega -e vm info | awk 'NR=='$row'{print $7}')
    if [[ "$state" != "RUNNING" ]] 
    then
      continue
    fi
    ip=$(minimega -e vm info | awk 'NR=='$row'{print $27}')
    HOST=$(echo ${ip:1:-1})
    echo
    echo "Installing the Wrapper in $HOST"
    echo
    USERNAME=$(echo vm$i)
    SCRIPT="chmod +x WrapperInstaller.sh; echo $USERNAME | sudo -S ./WrapperInstaller.sh"
    sshpass -p "$USERNAME" scp -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null  WrapperInstaller.sh $USERNAME@$HOST:
    if [[ $? -eq 0 ]]
      then 
      sshpass -p "$USERNAME" ssh -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -t -l ${USERNAME} ${HOST} "${SCRIPT}"
    else
      echo "Invalid Username/Password for $HOST"
    fi
  done
  exit
fi

if [[ $# == 2 ]]
then
  numU=$(wc -l < $1)
  numP=$(wc -l < $2)
  if [[ $numU != $numP ]]
  then 
    echo 
    echo "The number of Usernames and Passwords are mismatched. Please verify the files."
    echo "Exiting to main menu..."
    exit
  fi
  for (( i=1; i <= $numU; i++ ))
  do
    let row=$i+1
    state=$(minimega -e vm info | awk 'NR=='$row'{print $7}')
    if [[ "$state" != "RUNNING" ]] 
    then
      continue
    fi
    ip=$(minimega -e vm info | awk 'NR=='$row'{print $27}')
    HOST=$(echo ${ip:1:-1})
    echo
    echo "Installing the Wrapper in $HOST"
    echo
    USERNAME=$(cat $1 | awk 'NR=='$i'{print $1}')
    PASSWORD=$(cat $2 | awk 'NR=='$i'{print $1}')
    SCRIPT="chmod +x WrapperInstaller.sh; echo $PASSWORD | sudo -S ./WrapperInstaller.sh"
    sshpass -p "$PASSWORD" scp -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null  WrapperInstaller.sh $USERNAME@$HOST:
    if [[ $? -eq 0 ]]
    then 
      sshpass -p "$PASSWORD" ssh -q -o StrictHostKeyChecking=no -t -l ${USERNAME} ${HOST} "${SCRIPT}"
    else
      echo "Invalid Username/Password. Exiting to main menu..."
      exit
    fi
  done
  exit
fi

if [[ $# == 3 && $2 == "-copy" ]]
then
  for (( i=1; i <= $1; i++ ))
  do
    let row=$i+1
    state=$(minimega -e vm info | awk 'NR=='$row'{print $7}')
    if [[ "$state" != "RUNNING" ]] 
    then
      continue
    fi
    ip=$(minimega -e vm info | awk 'NR=='$row'{print $27}')
    HOST=$(echo ${ip:1:-1})
    echo
    echo
    USERNAME=$(echo vm$i)
    sshpass -p "$USERNAME" scp -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $3 $USERNAME@$HOST:
    if [[ $? -eq 0 ]]
    then
      echo
    else
      echo "Invalid Username/Password for $HOST. Exiting to main menu..."
      exit
    fi
  done
  exit
fi

if [[ $# == 3 && $2 == "-run" ]]
then
  for (( i=1; i <= $1; i++ ))
  do
    let row=$i+1
    state=$(minimega -e vm info | awk 'NR=='$row'{print $7}')
    if [[ "$state" != "RUNNING" ]] 
    then
      continue
    fi
    ip=$(minimega -e vm info | awk 'NR=='$row'{print $27}')
    HOST=$(echo ${ip:1:-1})
    echo
    echo "Running the script in $HOST"
    echo
    scriptname=$(basename $3)
    USERNAME=$(echo vm$i)
    SCRIPT="chmod +x $scriptname; echo $USERNAME | sudo -S ./$scriptname"
    sshpass -p "$USERNAME" scp -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null  $3 $USERNAME@$HOST:
    if [[ $? -eq 0 ]]
    then
      sshpass -p "$USERNAME" ssh -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -t -l ${USERNAME} ${HOST} "${SCRIPT}"
    else
      echo "Invalid Username/Password for $HOST. Exiting to main menu..."
      exit
    fi
  done
  exit
fi

if [[ $# == 4 && $1 == "-copy" ]]
then
  numU=$(wc -l < $3)
  numP=$(wc -l < $4)
  if [[ $numU != $numP ]]
  then 
    echo 
    echo "The number of Usernames and Passwords are mismatched. Please verify the files."
    echo "Exiting..."
    exit
  fi
  for (( i=1; i <= $numU; i++ ))
  do
    let row=$i+1
    state=$(minimega -e vm info | awk 'NR=='$row'{print $7}')
    if [[ "$state" != "RUNNING" ]] 
    then
      continue
    fi
    ip=$(minimega -e vm info | awk 'NR=='$row'{print $27}')
    HOST=$(echo ${ip:1:-1})
    echo
    echo "Copying the file to $HOST"
    echo
    USERNAME=$(cat $3 | awk 'NR=='$i'{print $1}')
    PASSWORD=$(cat $4 | awk 'NR=='$i'{print $1}')
    sshpass -p "$PASSWORD" scp -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $2 $USERNAME@$HOST:
    if [[ $? -eq 0 ]]
    then
      echo
    else
      echo "Invalid Username/Password for $HOST. Exiting to main menu..."
      exit
    fi
  done
  exit
fi


if [[ $# == 4 && $1 == "-run" ]]
then
  numU=$(wc -l < $3)
  numP=$(wc -l < $4)
  if [[ $numU != $numP ]]
  then 
    echo 
    echo "The number of Usernames and Passwords are mismatched. Please verify the files."
    echo "Exiting..."
    exit
  fi
  for (( i=1; i <= $numU; i++ ))
  do
    let row=$i+1
    state=$(minimega -e vm info | awk 'NR=='$row'{print $7}')
    if [[ "$state" != "RUNNING" ]] 
    then
      continue
    fi
    ip=$(minimega -e vm info | awk 'NR=='$row'{print $27}')
    HOST=$(echo ${ip:1:-1})
    echo
    echo "Running the script in $HOST"
    echo
    scriptname=$(basename $2)
    echo $scriptname
    USERNAME=$(cat $3 | awk 'NR=='$i'{print $1}')
    PASSWORD=$(cat $4 | awk 'NR=='$i'{print $1}')
    echo $USERNAME
    echo $PASSWORD
    SCRIPT="chmod +x $scriptname; echo $PASSWORD | sudo -S ./$scriptname"
    sshpass -p "$PASSWORD" scp -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null  $2 $USERNAME@$HOST:
    if [[ $? -eq 0 ]]
    then 
      sshpass -p "$PASSWORD" ssh -q -o StrictHostKeyChecking=no -t -l ${USERNAME} ${HOST} "${SCRIPT}"
    else
      echo "Invalid Username/Password for $HOST. Exiting to main menu..."
      exit
    fi
  done
  exit
fi
