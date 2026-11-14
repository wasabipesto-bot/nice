#!/bin/bash
# setup.sh (the box): worktrees main (41b4b405, upstream main), fix and repro (both start at main; patched from ivory)
set -e
W=/root/t26; mkdir -p $W/wt $W/bin $W/logs $W/out $W/patches
. /root/.cargo/env
cd /root/nice
git fetch -q upstream main
git fetch -q origin pr/check-d pr/join-prefilter-shift-pow2 pr/join-survivor-stage-512 pr/join-prefilter-popcount-spirv
for x in "main 41b4b405" "fix 41b4b405" "repro 41b4b405"; do
  set -- $x
  [ -d $W/wt/$1 ] || git worktree add -q --detach $W/wt/$1 $2
done
cd $W/wt/main && rustup show active-toolchain || true
rustup component add clippy rustfmt > $W/out/rustup-comp.log 2>&1 || true
echo SETUP_DONE $(date -u +%T) $(rustc --version)
