#!/bin/bash
# ivory: sync the worktree's diff to the box, run cargo fmt there, bring the formatted diff back into the worktree
set -e
cd /home/claude/projects/nice/.worktrees/midout
/home/claude/projects/nice/scratchpad/2026-10-research-program/G2/build5l/box/syncw.sh > /dev/null
ssh -p 38876 root@ssh2.vast.ai 'source ~/.cargo/env; cd /root/m5w && cargo fmt --all && git diff > /root/m5w.fmt.patch' 2>/dev/null
scp -q -P 38876 root@ssh2.vast.ai:/root/m5w.fmt.patch /tmp/claude-1000/m5.fmt.patch 2>/dev/null
H=$(ssh -p 38876 root@ssh2.vast.ai 'cd /root/m5w && git rev-parse HEAD' 2>/dev/null)
test "$(git rev-parse HEAD)" = "$H" || { echo "HEAD mismatch: ivory $(git rev-parse HEAD) box $H"; exit 1; }
git checkout -q . && git apply /tmp/claude-1000/m5.fmt.patch && git diff --stat | tail -1
