#!/bin/bash
# pull.sh: copy the box's /root/l41/logs to raw/box and /root/l41/sass to raw/box/sass, and the box's chain outputs
# (run from L41/raw).
mkdir -p box/sass
ssh -q -o StrictHostKeyChecking=no -o LogLevel=ERROR -p 39938 root@ssh4.vast.ai 'cd /root/l41/logs && tar -cf - .' < /dev/null 2>/dev/null | tar -xf - -C box
ssh -q -o StrictHostKeyChecking=no -o LogLevel=ERROR -p 39938 root@ssh4.vast.ai 'cd /root/l41/sass && tar -cf - .' < /dev/null 2>/dev/null | tar -xf - -C box/sass
ssh -q -o StrictHostKeyChecking=no -o LogLevel=ERROR -p 39938 root@ssh4.vast.ai 'cd /root/l41 && tar -cf - *.out' < /dev/null 2>/dev/null | tar -xf - -C box
mkdir -p box/cuexp
ssh -q -o StrictHostKeyChecking=no -o LogLevel=ERROR -p 39938 root@ssh4.vast.ai 'cd /root/l41/cuexp && tar -cf - *.cu *.sass' < /dev/null 2>/dev/null | tar -xf - -C box/cuexp
