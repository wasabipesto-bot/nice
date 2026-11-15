#!/bin/sh
exec ssh -o StrictHostKeyChecking=accept-new -o ConnectTimeout=20 -o ServerAliveInterval=30 -o LogLevel=ERROR -p 29364 root@ssh3.vast.ai "$@"
