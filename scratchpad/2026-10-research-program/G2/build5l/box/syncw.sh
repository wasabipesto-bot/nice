#!/bin/bash
# ivory: send the worktree's uncommitted diff against the box tree's HEAD and apply it on a clean checkout
set -e
cd /home/claude/projects/nice/.worktrees/midout
H=$(ssh -p 38876 root@ssh2.vast.ai 'cd /root/m5w && git rev-parse HEAD' 2>/dev/null)
git diff $H > /tmp/claude-1000/m5w.patch
scp -q -P 38876 /tmp/claude-1000/m5w.patch root@ssh2.vast.ai:/root/m5w.patch 2>/dev/null
ssh -p 38876 root@ssh2.vast.ai 'cd /root/m5w && git checkout -q . && git apply /root/m5w.patch && git status --short && md5sum /root/m5w.patch' 2>/dev/null
