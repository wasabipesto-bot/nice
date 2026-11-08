#!/bin/bash
# pull2.sh: box 59687089's logs (no binaries, no PTX caches) into L47/raw/box2/ on ivory
D=/home/claude/projects/nice/scratchpad/2026-10-research-program/L47/raw/box2
mkdir -p $D
ssh -o StrictHostKeyChecking=no -p 19458 root@ssh5.vast.ai 'cd /root/l47/logs && tar czf /tmp/l47_logs2.tgz .' 2>/dev/null
scp -q -o StrictHostKeyChecking=no -P 19458 root@ssh5.vast.ai:/tmp/l47_logs2.tgz /tmp/l47_logs2.tgz && tar xzf /tmp/l47_logs2.tgz -C $D && rm /tmp/l47_logs2.tgz
du -sh $D
