#!/bin/bash
# pull.sh: copy the box's /root/l48/logs to raw/box and /root/l48/sass to raw/box/sass (run from L48/raw).
S="ssh -o StrictHostKeyChecking=no -p 18370 root@ssh2.vast.ai"
mkdir -p box/sass
$S 'cd /root/l48/logs && tar -cf - .' 2>/dev/null | tar -xf - -C box
$S 'cd /root/l48/sass 2>/dev/null && tar -cf - --exclude="*.cubin" .' 2>/dev/null | tar -xf - -C box/sass
$S 'cd /root/l48 && tar -cf - *.out' 2>/dev/null | tar -xf - -C box
