#!/bin/bash
# pull.sh: copy the box's /root/l54/logs to raw/box/logs and chain outputs to raw/box (run from L54/raw).
S="ssh -o StrictHostKeyChecking=no -p 21434 root@ssh3.vast.ai"
mkdir -p box/logs
$S 'cd /root/l54/logs && tar -cf - .' 2>/dev/null | tar -xf - -C box/logs
$S 'cd /root/l54 && tar -cf - *.out' 2>/dev/null | tar -xf - -C box
