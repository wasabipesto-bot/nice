#!/bin/bash
# pull.sh: copy the box's /root/l36/logs (and scripts) to raw/box (run from L36/raw).
mkdir -p box
ssh -o StrictHostKeyChecking=no -p 33696 root@ssh5.vast.ai 'cd /root/l36/logs && tar -cf - --exclude="*.log.gz" --exclude="wgsl.log" .' 2>/dev/null | tar -xf - -C box
