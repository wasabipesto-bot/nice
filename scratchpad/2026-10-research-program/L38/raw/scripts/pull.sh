#!/bin/bash
# pull.sh: copy the box's /root/l38/logs to raw/box and /root/l38/sass to raw/box/sass (run from L38/raw).
mkdir -p box/sass
ssh -q -o StrictHostKeyChecking=no -o LogLevel=ERROR -p 34714 root@ssh3.vast.ai 'cd /root/l38/logs && tar -cf - .' 2>/dev/null | tar -xf - -C box
ssh -q -o StrictHostKeyChecking=no -o LogLevel=ERROR -p 34714 root@ssh3.vast.ai 'cd /root/l38/sass && tar -cf - .' 2>/dev/null | tar -xf - -C box/sass
