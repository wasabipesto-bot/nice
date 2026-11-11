#!/bin/bash
exec ssh -o StrictHostKeyChecking=no -o ServerAliveInterval=30 -p 12014 root@ssh8.vast.ai "$@"
