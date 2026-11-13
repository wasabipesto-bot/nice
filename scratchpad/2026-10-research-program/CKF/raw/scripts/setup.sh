#!/bin/bash
# setup.sh (the box): worktrees base (bc9d87c7, PR head), main (a7a59c11, upstream main), fix (built from patches)
set -e
W=/root/ckf; mkdir -p $W/wt $W/bin $W/logs $W/out
. /root/.cargo/env
rustup component add clippy rustfmt > $W/out/rustup-comp.log 2>&1 || true
cd /root/nice
git fetch -q origin pr/check-d
for x in "base bc9d87c7" "main a7a59c11" "fix bc9d87c7" "repro bc9d87c7"; do
  set -- $x
  [ -d $W/wt/$1 ] || git worktree add -q --detach $W/wt/$1 $2
done
git -C $W/wt/main log --oneline -1; git -C $W/wt/base log --oneline -1
echo SETUP_DONE $(date -u +%T) $(rustc --version)
