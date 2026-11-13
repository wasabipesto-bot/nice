#!/bin/bash
# builds2.sh: after X2/Xd2, the candidate trees CM (exp/n21-popcount-test) and CP (exp/n21-ffs-pop) with production's
# features and with naga's (gpu only), and E's naga build (X2n). Own target dir per tree.
W=/root/n21; cd /root/nice
git fetch -q origin exp/n21-popcount-test exp/n21-ffs-pop
for x in "CM origin/exp/n21-popcount-test" "CP origin/exp/n21-ffs-pop"; do
  set -- $x; [ -d $W/wt/$1 ] || git worktree add -q --detach $W/wt/$1 $2; echo "$1 $(git -C $W/wt/$1 log --oneline -1)"
done
until grep -q "built Xd2\|FAILED" $W/out/b_X2.out; do sleep 10; done
JOBS=8 bash $W/scripts/build.sh CM CM & JOBS=8 bash $W/scripts/build.sh CP CP; wait
JOBS=8 bash $W/scripts/build.sh CM CMn gpu & JOBS=8 bash $W/scripts/build.sh CP CPn gpu; wait
JOBS=16 bash $W/scripts/build.sh E X2n gpu
echo BUILDS2_DONE $(date -u +%T)
