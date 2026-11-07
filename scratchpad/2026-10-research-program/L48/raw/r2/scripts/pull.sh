#!/bin/bash
# pull.sh (round 2): copy the box's /root/l48/logs to r2/box and /root/l48/sass to r2/box/sass (run from L48/raw/r2).
S="ssh -o StrictHostKeyChecking=no -p 13936 root@ssh2.vast.ai"
mkdir -p box/sass
$S 'cd /root/l48/logs && tar -cf - .' 2>/dev/null | tar -xf - -C box
$S 'cd /root/l48/sass 2>/dev/null && tar -cf - --exclude="*.cubin" .' 2>/dev/null | tar -xf - -C box/sass
$S 'cd /root/l48 && tar -cf - *.out' 2>/dev/null | tar -xf - -C box
