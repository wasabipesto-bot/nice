#!/bin/bash
# pull.sh: the box's logs (no binaries, no PTX caches) into L47/raw/box/ on ivory
D=/home/claude/projects/nice/scratchpad/2026-10-research-program/L47/raw/box
mkdir -p $D
ssh -o StrictHostKeyChecking=no -p 25378 root@ssh3.vast.ai 'cd /root/l47/logs && tar czf /tmp/l47_logs.tgz --exclude="*.cubin" .' 2>/dev/null
scp -q -o StrictHostKeyChecking=no -P 25378 root@ssh3.vast.ai:/tmp/l47_logs.tgz /tmp/l47_logs.tgz && tar xzf /tmp/l47_logs.tgz -C $D && rm /tmp/l47_logs.tgz
du -sh $D
