# SETGen Manual

### Last Updated: 15th August 2020
---

SETGen is an all-in-one script that provides the ability to control Minimega VMs, generate system events in VM(s), generate both intra and inter-VM network traffic, etc.

As of now, Ubuntu is the only supported operating system.

---

***

## Pre-requisites


1) Minimega:

    Please ensure that Minimega is installed.
    
    To install Minimega, follow the instructions [here](https://ku.nz/miniclass/module1.html).


2) Miniweb:

    Please ensure that Miniweb is installed and the binaries are located in the /opt/bin directory.

    To install Miniweb, follow the instructions [here](https://ku.nz/miniclass/module1.html).


3) Tmux:
   
    Tmux is a terminal multiplexer for Unix-like operating systems. It allows multiple terminal sessions to be accessed simultaneously in a single window. It is useful for running more than one command-line program at the same time.

    To install Tmux, run the following command:

        sudo apt install tmux


4) SSHPass:

    SSHPass is a tiny utility, which allows you to provide the ssh password without using the prompt. This is very helpful for scripting.

    To install SSHPass, run the following command:

        sudo apt-get install sshpass


5) D-ITG:

    D-ITG (Distributed Internet Traffic Generator) is a platform capable of producing IPv4 and IPv6 traffic by accurately replicating the workload of current Internet applications.

    To install D-ITG and its dependencies, run the following command:

        sudo apt-get install -y d-itg


6) Root User Permissions

    In-order to use the Wrapper, root permissions are required.

    To login as the root user, run the following command:

	    sudo su

***

## Installation


0) **Make sure that the pre-requisites are installed**
   

1) Unzip the installation file to the desired director
   

2) Change directory to the MinimegaWrapper directory
   

3) To change the permissions of the script, run

        chmod +x MinimegaWrapper.sh


4) To change the permissions of all dependencies, run

        chmod +x scripts/*


5) Kill all instances of Minimega processes


6) With root user permissions, run

        ./MinimegaWrapper.sh

***

## Notes


1) To avoid network traffic conflicts in Cross-VM Traffic Generation, we are allowing only a unique pair of Host/Dest VM to generate traffic. So, if host A is generating traffic to host B, both B and A can’t receive/send traffic from/to a different VM as long as A is generating traffic to B.


2) It is strongly advised NOT to modify any files in tmp/ directory.


3) In the main menu, you can type “clear” as an option to clear the screen.

***
## Tutorial


1) Main menu options

    ![alt text](MMO.png "Main menu options") </br>
                    Fig: SETGen Main menu options

</br>

2) Creating Username and Password File for the VMs:

    To create username and password file for the running VMs, run 
	    
        minimega -e vm info as the root user.


    ![alt text](SMVIO.png "Sample output of Minimega VM info") </br>
                    Fig: Sample output of Minimega VM info


    Then, create a file for username. Use a text editor (e.g. Vim) to edit the file.

    Type the username for each VM in order of Minimega ID (0,1,2, ……). 

    For example, in the sample username file, the username in the first row is for vm1, second row for vm2 and third row for vm3.


    ![alt text](SUF.png "Sample username File") </br>
                    Fig: Sample Username File


    In a similar way, create the password file containing the passwords for the VMs.

**Note:** Make sure that both username and password file **don’t have a new line at the end.**


1) Understanding VM Network Traffic Generation Status
   
   ![alt text](STGS.png "Sample Network Traffic Generation Status") </br>
                    Fig: Sample Network Traffic Generation Status
    </br>

    Here, 
    
    **IP** column refers to the ip address of the VM.

    **SRC** column refers to the ip address of the source VM from which Network Traffic is being received.

    **DEST** column refers to the ip address of the destination VM to which Network Traffic is being sent.

    **INTERFACE** column refers to the network interface where network traffic is being generated.

    **METHOD** column refers to the component being used for Network Traffic generation. </br>
            The possible values are: NetworkWrapper (Tools), NetworkWrapper (PCAPs), D-ITG, ReplayPCAP
    
    The first row means that 1.0.0.22 is not generating any kind of traffic.
    
    The second row means that 1.0.0.30 is generating realistic traffic (using tools) within itself to the ens0 interface using the Network Wrapper.

    The third and fourth rows mean that 1.0.0.92 is generating realistic traffic (using tools) to 1.0.0.184’s ens1 interface using the Network Wrapper.

    The fifth row means that 1.0.0.186 is generating realistic traffic (using PCAPs) within itself to the net0 interface using the Network Wrapper. 

    The sixth row means that 1.0.0.188 is generating traffic within itself using D-ITG.

    The seventh and eighth rows mean that 1.0.0.50 is generating D-ITG traffic to 1.0.0.32.

    The ninth row means that 1.0.0.15 is replaying a PCAP file in eth1 interface.

</br>

4) Installing required tools in the VMs:
   
    After creating the VMs in Minimega using option 5, you are required to manually install some tools in **all running VMs.**

    After logging in to VM as the **root** user, update the system by running

        apt-get update

    Install python3 by running

        apt-get install python3


    Install OpenSSH Server by running    

        apt install openssh-server

    After running the above commands, you should be able to proceed to option 6.
    
***
