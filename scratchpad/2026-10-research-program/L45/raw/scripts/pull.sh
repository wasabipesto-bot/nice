#!/bin/bash
# pull.sh: copy the box's /root/l45/logs to raw/box and /root/l45/sass to raw/box/sass (run from L45/raw).
mkdir -p box/sass
ssh -o StrictHostKeyChecking=no -p 30812 root@ssh7.vast.ai 'cd /root/l45/logs && tar -cf - .' 2>/dev/null | tar -xf - -C box
ssh -o StrictHostKeyChecking=no -p 30812 root@ssh7.vast.ai 'cd /root/l45/sass 2>/dev/null && tar -cf - .' 2>/dev/null | tar -xf - -C box/sass
ssh -o StrictHostKeyChecking=no -p 30812 root@ssh7.vast.ai 'cd /root/l45 && tar -cf - chain_*.out build_*.out' 2>/dev/null | tar -xf - -C box
