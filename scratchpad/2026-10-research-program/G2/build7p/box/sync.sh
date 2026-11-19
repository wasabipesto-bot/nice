#!/bin/bash
# ivory: sync.sh WT DIR BRANCH — make the box's /root/DIR equal to ivory's worktree WT
# (its commits by bundle, its uncommitted diff by patch)
set -e
S=/tmp/claude-1000/-home-claude/324735b8-5439-5545-8cc9-5971228cc742/scratchpad
H=root@ssh2.vast.ai
WT=/home/claude/projects/nice/.worktrees/$1; D=/root/$2; BR=$3
cd $WT
git bundle create -q $S/$2.bundle be9cc923..$BR
scp -q -P 35082 $S/$2.bundle $H:/root/$2.bundle
ssh -p 35082 $H "[ -d $D ] || git clone -q /root/mc $D; cd $D && git checkout -q . && git clean -fdq && git fetch -q /root/$2.bundle $BR && git checkout -q --detach FETCH_HEAD"
git add -N . ; git diff HEAD > $S/$2.patch
scp -q -P 35082 $S/$2.patch $H:/root/$2.patch
ssh -p 35082 $H "cd $D && ( [ -s /root/$2.patch ] && git apply /root/$2.patch || true ) && git log --oneline -1 && git status --short | head"
