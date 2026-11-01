#!/bin/bash
# Copy the box's /root/sc logs back (binaries excluded).
D=$(dirname "$0")/raw
rsync -az -e "ssh -o StrictHostKeyChecking=no -o ConnectTimeout=20 -o HostKeyAlias=ssh4.vast.ai -p 28136" \
  --exclude main --exclude both --exclude p235 --exclude p236 --exclude 'client_*' --exclude src \
  root@3.82.44.55:/root/sc/ "$D/" 2>&1 | grep -v "Welcome\|Have fun\|authentication"
