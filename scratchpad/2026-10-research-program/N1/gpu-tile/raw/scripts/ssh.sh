#!/bin/bash
# ssh.sh CMD...: run CMD on the N1 box (Vast 60024264).
exec ssh -o StrictHostKeyChecking=no -o ConnectTimeout=20 -o ServerAliveInterval=30 -p 39808 root@ssh7.vast.ai "$@"
