#!/bin/bash
# setup.sh (the box): worktrees main and fix (both at upstream main 41b4b405; fix patched from ivory)
set -e
W=/root/t26b; mkdir -p $W/wt $W/bin $W/logs $W/out $W/scripts
. /root/.cargo/env
cd /root/nice
git fetch -q upstream main
for x in "main 41b4b405" "fix 41b4b405"; do
  set -- $x
  [ -d $W/wt/$1 ] || git worktree add -q --detach $W/wt/$1 $2
done
cd $W/wt/main && rustup show active-toolchain || true
rustup component add clippy rustfmt > $W/out/rustup-comp.log 2>&1 || true
echo SETUP_DONE $(date -u +%T) $(rustc --version)
