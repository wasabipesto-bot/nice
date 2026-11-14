#!/bin/bash
# box.sh CMD...: run a command on the T26B box (instance 60665092)
exec ssh -o StrictHostKeyChecking=accept-new -o ConnectTimeout=20 -o ServerAliveInterval=30 -p 20752 root@ssh1.vast.ai "$@" </dev/null
