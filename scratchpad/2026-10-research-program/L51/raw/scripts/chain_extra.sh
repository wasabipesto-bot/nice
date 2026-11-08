#!/bin/bash
# chain_extra.sh: tree E2 (exp/l51-profile 14f87cd, the slice-setup split) built and profiled at
# b62 1e17 and b60 1e16 (2 rounds, mode c); then the spill counter (pairs past a full stage) on base, stg1, fl768, tc512.
source /root/l51/cfg.sh
R=/root/l51/run.sh; L=/root/l51/logs
# (Run at 07:10, between the two screen chains: E2 was built 07:04-07:09 by this script's first start, which the
# screen's stop file released early; the build part is skipped when bin/E2 exists.)
echo EXTRA_START $(date -u +%T)
if [ ! -e /root/l51/bin/E2 ]; then
  cd /root/nice && git fetch -q origin exp/l51-profile && git worktree add -q --detach /root/l51/src/E2 origin/exp/l51-profile
  (cd /root/l51/src/E2 && echo "E2 $(git log --oneline -1) $(md5sum common/src/cubecl_join.rs)") >> $L/trees.txt
  cd /root/l51 && J=10 bash build.sh E2 E2 > build_E2.out 2>&1 || { cat build_E2.out; exit 1; }
fi
for r in 1 2; do
  for f in "62 1 1e17 e17_b62" "60 2 1e16 e16_b60"; do
    set -- $f
    setcfg c
    $R x_up_$4_r$r E2 $1 $2 $3
    echo "$(date -u +%T) x_up_$4_r$r $(grep -o 'device=[0-9.]*s' $L/x_up_$4_r$r.log | tail -1) $(grep -o 'upload=[0-9.]*' $L/x_up_$4_r$r.log | tail -1) $(grep -o 'up_host=.*up_warm=[0-9.]*' $L/x_up_$4_r$r.log | tail -1)"
  done
done
for spec in "spc 62 1 1e17 e17_b62" "spc 60 2 1e16 e16_b60" "spcstg1 60 2 1e16 e16_b60" "spcfl768 60 2 1e16 e16_b60" "spctc512 60 2 1e16 e16_b60" "spcstg1 62 1 1e17 e17_b62"; do
  set -- $spec
  setcfg $1; export NICE_EXP_GPU_PROFILE=1
  $R x_$1_$5 E $2 $3 $4
  echo "$(date -u +%T) x_$1_$5 $(grep -o 'device=[0-9.]*s' $L/x_$1_$5.log | tail -1) $(grep -o 'spilled=[0-9]*' $L/x_$1_$5.log | tail -1) $(grep -o 'survivors=[0-9]* checked=[0-9]*' $L/x_$1_$5.log | tail -1)"
done
echo EXTRA_DONE $(date -u +%T) | tee $L/extra.done
