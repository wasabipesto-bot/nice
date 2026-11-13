#!/bin/sh
# pull.sh (ivory): copy the box's logs, outputs and ACO dumps (text only) into N21/raw/box/.
cd "$(dirname "$0")/.." || exit 1
SSH="ssh -o StrictHostKeyChecking=no -p 18148"
rsync -a -e "$SSH" root@ssh5.vast.ai:/root/n21/logs/ box/logs/ 2>&1 | grep -v "^Welcome\|^Have"
rsync -a -e "$SSH" root@ssh5.vast.ai:/root/n21/out/ box/out/ 2>&1 | grep -v "^Welcome\|^Have"
rsync -a -e "$SSH" --include='*/' --include='*.aco.txt' --include='run.log' --exclude='*' root@ssh5.vast.ai:/root/n21/spv/ box/spv/ 2>&1 | grep -v "^Welcome\|^Have"
du -sh box
