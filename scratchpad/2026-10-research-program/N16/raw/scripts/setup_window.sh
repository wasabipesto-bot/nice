#!/bin/sh
# setup_window.sh (demoux, inside the workspace the window's brief prepares: $W/src/nice = a clone of the fork with
# remote upstream, $W/run.sh, $W/cargo-home): worktrees $W/wt/N16 = fork exp/n16-join-base, $W/wt/M = upstream main
# 5b1d627, $W/wt/D = fork exp/n14-wgpu-dense-plan. Run as: $W/run.sh sh $W/scripts/setup_window.sh
W=${W:?set W}
cd "$W/src/nice" || exit 1
git fetch -q origin exp/n16-join-base exp/n14-wgpu-dense-plan && git fetch -q upstream main || exit 1
mkdir -p "$W/wt" "$W/out" "$W/bin"
for x in "N16 origin/exp/n16-join-base" "M 5b1d627" "D origin/exp/n14-wgpu-dense-plan"; do
  set -- $x
  [ -d "$W/wt/$1" ] || git worktree add -q --detach "$W/wt/$1" "$2" || exit 1
  (cd "$W/wt/$1" && echo "$1 $(git log --oneline -1 | cut -c1-70)")
done | tee "$W/out/trees.txt"
