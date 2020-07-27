#!/bin/bash
            cd NetworkWrapper/
            tmux new-session -d -s TrafficGen \; send-keys "python3 /home/vm1/NetworkWrapper/wrap.py ens1" Enter
            
