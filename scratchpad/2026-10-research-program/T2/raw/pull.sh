#!/bin/sh
# copy the box's raw outputs to ivory (T2/raw/box/)
cd "$(dirname "$0")"; mkdir -p box
rsync -q -e "ssh -o StrictHostKeyChecking=no -o LogLevel=ERROR -p 26728" 'root@ssh2.vast.ai:/root/t2/*.jsonl' 'root@ssh2.vast.ai:/root/t2/*.log' box/ 2>&1 | tail -2
