#!/bin/bash
# ssh.sh CMD...: run CMD on the L54 box (Vast 59842997).
exec ssh -o StrictHostKeyChecking=no -o ConnectTimeout=20 -o ServerAliveInterval=30 -p 21434 root@ssh3.vast.ai "$@"
