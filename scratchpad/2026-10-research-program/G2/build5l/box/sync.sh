#!/bin/bash
# ivory: send the worktree's uncommitted diff against the box tree's HEAD and apply it on a clean checkout
set -e
cd /home/claude/projects/nice/.worktrees/midout
H=$(ssh -p 38876 root@ssh2.vast.ai 'cd /root/m5 && git rev-parse HEAD' 2>/dev/null)
git diff $H > /tmp/claude-1000/m5.patch
scp -q -P 38876 /tmp/claude-1000/m5.patch root@ssh2.vast.ai:/root/m5.patch 2>/dev/null
ssh -p 38876 root@ssh2.vast.ai 'cd /root/m5 && git checkout -q . && git apply /root/m5.patch && git status --short && md5sum /root/m5.patch' 2>/dev/null
