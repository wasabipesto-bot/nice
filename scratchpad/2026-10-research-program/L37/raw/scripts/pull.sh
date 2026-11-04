#!/bin/bash
# pull.sh: copy the box's /root/l37/logs to raw/box and /root/l37/sass to raw/box/sass (run from L37/raw).
mkdir -p box/sass
ssh -o StrictHostKeyChecking=no -p 23112 root@ssh6.vast.ai 'cd /root/l37/logs && tar -cf - .' 2>/dev/null | tar -xf - -C box
ssh -o StrictHostKeyChecking=no -p 23112 root@ssh6.vast.ai 'cd /root/l37/sass && tar -cf - .' 2>/dev/null | tar -xf - -C box/sass
