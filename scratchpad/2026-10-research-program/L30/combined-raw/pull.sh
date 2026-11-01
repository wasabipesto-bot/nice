#!/bin/bash
# Copy the box's /root/cmb logs back (binaries excluded).
D=$(dirname "$0")/box
rsync -az -e "ssh -o StrictHostKeyChecking=no -p 13530" --exclude main --exclude both --exclude both_wgpu --exclude p235 --exclude p236 --exclude prof --exclude 'client_*' --exclude wgsl.log root@ssh3.vast.ai:/root/cmb/ "$D/" 2>&1 | grep -v "Welcome\|Have fun\|authentication"
