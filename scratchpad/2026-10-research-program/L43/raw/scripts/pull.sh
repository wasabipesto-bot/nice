#!/bin/bash
# pull.sh: copy the box's /root/l43/logs to raw/box and /root/l43/sass to raw/box/sass (run from L43/raw).
mkdir -p box/sass
ssh -q -o StrictHostKeyChecking=no -o LogLevel=ERROR -p 19070 root@ssh8.vast.ai 'cd /root/l43/logs && tar -cf - .' 2>/dev/null | tar -xf - -C box
ssh -q -o StrictHostKeyChecking=no -o LogLevel=ERROR -p 19070 root@ssh8.vast.ai 'cd /root/l43/sass && tar -cf - .' 2>/dev/null | tar -xf - -C box/sass
