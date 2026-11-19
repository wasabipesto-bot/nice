#!/bin/bash
# push the staged diff of the worktree to the box's /root/mc and run a command there
S=/tmp/claude-1000/-home-claude/324735b8-5439-5545-8cc9-5971228cc742/scratchpad
cd /home/claude/projects/nice/.worktrees/midout-client && git add -A && git diff --cached HEAD > $S/p.diff
scp -q -P 38876 $S/p.diff root@ssh2.vast.ai:/root/mo/p.diff 2>/dev/null
ssh -p 38876 root@ssh2.vast.ai "cd /root/mc && git checkout -q . && git clean -fdq && git apply /root/mo/p.diff && source ~/.cargo/env && export CARGO_TARGET_DIR=/root/t/mc && $1" 2>&1 | grep -v -i 'vast.ai\|have fun'
