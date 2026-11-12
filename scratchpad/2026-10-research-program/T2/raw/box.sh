#!/bin/sh
exec ssh -o StrictHostKeyChecking=no -o ConnectTimeout=20 -o ServerAliveInterval=30 -o LogLevel=ERROR -p 26728 root@ssh2.vast.ai "$@"
