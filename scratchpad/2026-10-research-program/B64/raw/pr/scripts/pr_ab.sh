#!/bin/bash
# pr_ab.sh: the PR's A/B. N = the branch (+ harness list), R = ee303030 (+ harness list): 3 interleaved rounds on the
# b64 1e17 field at 0.55 and on b64 1e16 at 0.35 + 0.55; main only (MF: c0c357a + harness + NICE_EXP_FD_POW2): FD
# off/on, 1 round at 1e17, 2 at 1e16; b62 1e17 (L30's field) R and N once.
source /root/b64/scripts/lists.sh
R=/root/b64/scripts/run.sh; L=/root/b64/logs
IFS=, read -ra A <<< "$L64"
one() { # name bin bases n size [list] [fdenv]
  unset NICE_TEST_JOIN_LIST NICE_EXP_FD_POW2
  [ -n "$6" ] && export NICE_TEST_JOIN_LIST=$6
  [ "$7" = on ] && export NICE_EXP_FD_POW2=1
  $R $1 $2 $3 $4 $5; bash /root/b64/scripts/jit.sh $1
  echo "$(date -u +%T) $1 $(grep -o 'secs=[0-9.]* per_field=[0-9.]*' $L/$1.log | tail -1) $(grep -o 'survivors=[0-9]* checked=[0-9]*' $L/$1.log | tail -1) $(grep -o 'join_kernel.*regs=[0-9]* local=[0-9]*' $L/$1_jit.txt | head -1 | grep -o 'regs.*')"
}
echo AB_START $(date -u +%T)
for r in 1 2 3; do
  if [ $((r % 2)) = 1 ]; then O="R N"; else O="N R"; fi
  for t in $O; do [ -e $L/stop ] && exit 0; one ab_${t}_e17_r$r $t 64 1 1e17 ${A[5]}; done
  for t in $O; do [ -e $L/stop ] && exit 0; one ab_${t}_e16_r$r $t 64 2 1e16 ${A[3]},${A[5]}; done
done
one ab_MFoff_e17_r1 MF 64 1 1e17 ${A[5]} off
one ab_MFon_e17_r1 MF 64 1 1e17 ${A[5]} on
for r in 1 2; do
  if [ $r = 1 ]; then O="off on"; else O="on off"; fi
  for o in $O; do one ab_MF${o}_e16_r$r MF 64 2 1e16 ${A[3]},${A[5]} $o; done
done
one ab_R_b62_r1 R 62 1 1e17
one ab_N_b62_r1 N 62 1 1e17
echo AB_DONE $(date -u +%T)
