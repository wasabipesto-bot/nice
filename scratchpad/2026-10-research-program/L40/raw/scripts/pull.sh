#!/bin/bash
# pull.sh: copy the box's /root/l40/logs to raw/box and /root/l40/sass to raw/box/sass (run from L38/raw).
mkdir -p box/sass
ssh -q -o StrictHostKeyChecking=no -o LogLevel=ERROR -p 16194 root@ssh7.vast.ai 'cd /root/l40/logs && tar -cf - .' 2>/dev/null | tar -xf - -C box
ssh -q -o StrictHostKeyChecking=no -o LogLevel=ERROR -p 16194 root@ssh7.vast.ai 'cd /root/l40/sass && tar -cf - .' 2>/dev/null | tar -xf - -C box/sass
