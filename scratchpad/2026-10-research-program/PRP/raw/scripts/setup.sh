#!/bin/bash
# setup.sh (box, root): toolchain 1.99.1, worktrees M (upstream main), S (pr/join-survivor-stage-512),
# F (pr/join-prefilter-shift-pow2) from the bundle; W=/root/prp.
set -e
W=/root/prp; mkdir -p $W/out $W/bin $W/wt
. /root/.cargo/env
rustup toolchain install 1.99.1 --profile minimal -c rustfmt,clippy > $W/out/rustup2.log 2>&1
rustup default 1.99.1 >> $W/out/rustup2.log 2>&1
cd /root/nice
git fetch -q $W/prp.bundle 'refs/heads/*:refs/remotes/b/*' 'refs/remotes/origin/main:refs/remotes/b/upstream-main'
for x in "M b/upstream-main" "S b/pr/join-survivor-stage-512" "F b/pr/join-prefilter-shift-pow2"; do
  set -- $x
  [ -d $W/wt/$1 ] || git worktree add -q --detach $W/wt/$1 $2
  echo "$1 $(git -C $W/wt/$1 log --oneline -1)"
done
echo "SETUP_DONE $(date -u +%T) $(rustc --version) $(nvidia-smi --query-gpu=name,power.limit,driver_version --format=csv,noheader)"
