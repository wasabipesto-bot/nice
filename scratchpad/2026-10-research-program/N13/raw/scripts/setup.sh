#!/bin/sh
# setup.sh (on demoux): worktrees M = upstream main c0c357a, T250 = ee303030 (#250), T251 = a97e3d7 (fork pr/check-d,
# #250 + #251), T254 = 69c514d (fork pr/top-fd-base64, #250 + #254), E = 44eee52 (fork exp/b64-profile: d813aea-based
# profile/knob tree + harness list); each but E + patch_harness.py.
W=/tmp/claude-exp-2026-11-11-amd
cd $W/src/nice || exit 1
git fetch -q origin pr/check-d pr/top-fd-base64 exp/b64-profile pr/top-fd-round2 && git fetch -q upstream main || exit 1
mkdir -p $W/wt
for x in "M c0c357a" "T250 ee303030" "T251 a97e3d7" "T254 69c514d" "E 44eee52"; do
  set -- $x
  git worktree add -q --detach $W/wt/$1 $2 || exit 1
  [ $1 = E ] || python3 $W/scripts/patch_harness.py $W/wt/$1
  (cd $W/wt/$1 && echo "$1 $(git log --oneline -1 | cut -c1-70) $(md5sum common/src/cubecl_join.rs | cut -c1-8)")
done > $W/out/trees.txt
cat $W/out/trees.txt
