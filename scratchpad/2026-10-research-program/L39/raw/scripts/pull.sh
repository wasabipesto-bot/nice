#!/bin/bash
# pull.sh: copy the box's /root/l39/logs to raw/box and /root/l39/sass to raw/box/sass (run from L39/raw).
mkdir -p box/sass
ssh -q -o StrictHostKeyChecking=no -o LogLevel=ERROR -p 25754 root@ssh1.vast.ai 'cd /root/l39/logs && tar -cf - .' 2>/dev/null | tar -xf - -C box
ssh -q -o StrictHostKeyChecking=no -o LogLevel=ERROR -p 25754 root@ssh1.vast.ai 'cd /root/l39/sass && tar -cf - .' 2>/dev/null | tar -xf - -C box/sass
