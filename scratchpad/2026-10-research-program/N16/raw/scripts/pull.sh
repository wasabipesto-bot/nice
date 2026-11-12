#!/bin/sh
# pull.sh (ivory): copy the box's $W/out into N16/raw/box/ (the port of the current box).
cd "$(dirname "$0")/.." && rsync -a -e "ssh -o StrictHostKeyChecking=no -p ${PORT:-21390}" root@ssh7.vast.ai:/root/n16/out/ box/ 2>&1 | grep -v "Welcome\|Have fun"
