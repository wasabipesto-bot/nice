#!/bin/bash
# ivory: make the box's /root/mc equal to the worktree (its commits by bundle, its uncommitted diff by patch)
set -e
S=/tmp/claude-1000/-home-claude/324735b8-5439-5545-8cc9-5971228cc742/scratchpad
P="-P 35082"; H=root@ssh2.vast.ai
cd /home/claude/projects/nice/.worktrees/midout-clean
BH=$(ssh -p 35082 $H 'cd /root/mc && git rev-parse HEAD' 2>/dev/null)
ME=$(git rev-parse HEAD)
if [ "$BH" != "$ME" ]; then
  git bundle create -q $S/inc.bundle $BH..dev/mo-clean
  scp -q $P $S/inc.bundle $H:/root/inc.bundle 2>/dev/null
  ssh -p 35082 $H 'cd /root/mc && git checkout -q . && git clean -fdq && git pull -q /root/inc.bundle dev/mo-clean' 2>/dev/null
fi
git add -N . ; git diff HEAD > $S/mc.patch
scp -q $P $S/mc.patch $H:/root/mc.patch 2>/dev/null
ssh -p 35082 $H 'cd /root/mc && git checkout -q . && git clean -fdq && git apply /root/mc.patch && git log --oneline -1 && git status --short | head' 2>/dev/null
