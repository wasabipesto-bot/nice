#!/bin/sh
exec ssh -o StrictHostKeyChecking=no -o ConnectTimeout=20 -o ServerAliveInterval=30 -o LogLevel=ERROR -p 31510 root@ssh1.vast.ai "$@"
