#!/bin/bash
# pull.sh: copy the box's logs, outputs and scripts to ivory (T26B/raw/box)
R=/home/claude/projects/nice/scratchpad/2026-10-research-program/T26B/raw
rsync -a -e "ssh -o ConnectTimeout=20 -p 30024" --exclude '*.smi.tmp' root@ssh1.vast.ai:/root/t26b/logs root@ssh1.vast.ai:/root/t26b/out $R/box/ 2>&1 | grep -v "^Welcome\|^Have" | tail -2
