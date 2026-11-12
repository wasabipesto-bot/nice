#!/bin/sh
# copy the replacement box's outputs to ivory (T2/raw/box2/)
cd "$(dirname "$0")"; mkdir -p box2
rsync -q -e "ssh -o StrictHostKeyChecking=no -o LogLevel=ERROR -p 31510" 'root@ssh1.vast.ai:/root/t2/*.jsonl' 'root@ssh1.vast.ai:/root/t2/*.log' box2/ 2>&1 | tail -2
