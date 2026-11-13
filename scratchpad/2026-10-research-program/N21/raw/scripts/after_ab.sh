#!/bin/bash
# after_ab.sh: once the timed A/B (ab3.out) is done: build tree E at the exp head (switch Z) -> X5 and Xd5, and the
# candidate CMw (exp/n21-popcount-test-wgpu) -> CMw / CMwn; ACO dumps of Z; then CMw's host tests, clippy, and lavapipe
# tests with both compilers. (tests2.sh runs at the same time: untimed.)
W=/root/n21; S=$W/scripts; L=$W/logs/t; mkdir -p $L
until grep -q AB_DONE $W/out/ab3.out; do sleep 20; done
cd /root/nice && git fetch -q origin exp/n21-walk-loop exp/n21-popcount-test-wgpu
[ -d $W/wt/CMw ] || git worktree add -q --detach $W/wt/CMw origin/exp/n21-popcount-test-wgpu
echo "CMw $(git -C $W/wt/CMw log --oneline -1)"
cd $W/wt/E && git checkout -q --detach origin/exp/n21-walk-loop && echo "E $(git log --oneline -1)"
JOBS=8 bash $S/build.sh E X5 & JOBS=8 bash $S/build.sh CMw CMw; wait
TSUF=-dump JOBS=8 bash $S/build.sh E Xd5 gpu,cubecl-spirv,cubecl/spirv-dump & JOBS=8 bash $S/build.sh CMw CMwn gpu; wait
for x in "62 0 9 137 393" "64 0 9 137 393 457"; do
  set -- $x; B=$1; shift
  for m in "$@"; do DB=Xd5 TMO=30 bash $S/spvdump.sh z${B}_$m $m $B 2>&1 | grep -v "^ *+ pass\|SHADER"; done
done
touch $W/out/dumps3.done
( cd $W/run/h && $W/bin/CMw --test-threads 8 > $L/host_CMw.log 2>&1; echo "host CMw: $(grep 'test result' $L/host_CMw.log)" )
bash $S/clippy.sh CMw
export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/lvp_icd.json LP_NUM_THREADS=4
mkdir -p $W/run/l2 && cd $W/run/l2
for b in CMw CMwn; do ( timeout 5400 nice -n 5 $W/bin/$b --ignored cubecl_join::tests:: --skip cuda --nocapture --test-threads 1 > $L/lvp_${b}_0.log 2>&1
  echo "lavapipe $b: $(grep 'test result' $L/lvp_${b}_0.log)" ) & done; wait
echo AFTER_AB_DONE $(date -u +%T)
