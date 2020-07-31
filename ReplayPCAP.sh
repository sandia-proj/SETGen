#!/bin/bash
        tmux new-session -d -s ReplayPCAP \; send-keys "python3 /home/vm1/NetworkWrapper/wrap.py ens1 --replay SkypeIRC.cap " Enter
        
