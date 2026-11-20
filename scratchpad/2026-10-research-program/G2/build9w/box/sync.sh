#!/bin/bash
# ivory: make the box's /root/mc equal to the worktree (its commits by bundle, its uncommitted diff by patch)
set -e
S=/tmp/claude-1000/-home-claude/324735b8-5439-5545-8cc9-5971228cc742/scratchpad/9w
H=root@ssh4.vast.ai; P=36712
cd /home/claude/projects/nice/.worktrees/midout-clean
BH=$(ssh -p $P $H 'cd /root/mc && git rev-parse HEAD' 2>/dev/null)
ME=$(git rev-parse HEAD)
if [ "$BH" != "$ME" ]; then
  git bundle create -q $S/inc.bundle $BH..dev/mo-clean
  scp -q -P $P $S/inc.bundle $H:/root/inc.bundle 2>/dev/null
  ssh -p $P $H 'cd /root/mc && git checkout -q . && git clean -fdq && git pull -q --ff-only /root/inc.bundle dev/mo-clean' 2>/dev/null
fi
git diff HEAD > $S/mc.patch
scp -q -P $P $S/mc.patch $H:/root/mc.patch 2>/dev/null
ssh -p $P $H 'cd /root/mc && git checkout -q . && git clean -fdq && (test ! -s /root/mc.patch || git apply /root/mc.patch) && git log --oneline -1 && git status --short | head -20' 2>/dev/null
