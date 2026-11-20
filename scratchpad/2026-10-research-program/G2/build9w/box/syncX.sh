#!/bin/bash
# ivory: syncX.sh DIR — make the box's /root/DIR a clone of /root/mc at its HEAD plus the worktree's uncommitted diff
set -e
S=/tmp/claude-1000/-home-claude/324735b8-5439-5545-8cc9-5971228cc742/scratchpad/9w
H=root@ssh4.vast.ai; P=36712; D=$1
cd /home/claude/projects/nice/.worktrees/midout-clean
git diff HEAD > $S/x_$D.patch
scp -q -P $P $S/x_$D.patch $H:/root/x_$D.patch 2>/dev/null
ssh -p $P $H "cd /root && ( [ -d $D/.git ] || git clone -q /root/mc $D ) && cd $D && git fetch -q /root/mc && git checkout -q . && git clean -fdq && git checkout -q --detach \$(git -C /root/mc rev-parse HEAD) && (test ! -s /root/x_$D.patch || git apply /root/x_$D.patch) && git log --oneline -1 && git status --short" 2>/dev/null < /dev/null
