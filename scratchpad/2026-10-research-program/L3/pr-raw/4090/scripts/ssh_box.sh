#!/bin/bash
exec ssh -o StrictHostKeyChecking=no -o ConnectTimeout=20 -o ServerAliveInterval=30 -o LogLevel=ERROR -p 33238 root@ssh7.vast.ai "$@"
