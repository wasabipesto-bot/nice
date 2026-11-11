#!/bin/bash
# pull.sh: copy the box's logs (not the PTX caches) to ../box on ivory.
cd "$(dirname "$0")"
rsync -az -e "ssh -o StrictHostKeyChecking=no -p 12014" root@ssh8.vast.ai:/root/b64/logs/ ../box/ 2>&1 | grep -v -i "welcome\|fun"
