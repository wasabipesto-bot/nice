#!/bin/bash
# Ship the worktree's diff against 215952d to the box's /root/nice and apply it.
set -euo pipefail
cd /home/claude/projects/nice/.worktrees/pr-web-fd
git diff 215952d > /home/claude/l24b-work/cur.patch
SSHO="-o StrictHostKeyChecking=no -o ConnectTimeout=15"
scp -q -P 37602 $SSHO /home/claude/l24b-work/cur.patch root@ssh4.vast.ai:/root/cur.patch
ssh $SSHO -p 37602 root@ssh4.vast.ai 'cd /root/nice && git checkout -q -- . && git apply /root/cur.patch && git status --short && sha256sum /root/cur.patch' 2>&1 | grep -v -i "welcome\|have fun"
