#!/bin/bash
# pull.sh: copy the box's /root/l51/logs to raw/box, /root/l51/sass to raw/box/sass, chain outputs (run from L51/raw).
S="ssh -o StrictHostKeyChecking=no -p 11252 root@ssh4.vast.ai"
mkdir -p box/sass
$S 'cd /root/l51/logs && tar -cf - .' 2>/dev/null | tar -xf - -C box
$S 'cd /root/l51/sass 2>/dev/null && tar -cf - .' 2>/dev/null | tar -xf - -C box/sass
$S 'cd /root/l51 && tar -cf - *.out' 2>/dev/null | tar -xf - -C box
