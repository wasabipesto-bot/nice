#!/bin/bash
# chain_B.sh: Task B walk variants + the entry-wave hoist on tree E3 (E + patchB + patchH), unprofiled, 3 interleaved rounds (order rotated):
# v0 today (stg 0), v2 one walk over both entry slots (stg 2), v4 no per-round plane barrier (stg 4), v6 the entry wave prepared once per bucket (stg 6).
# Fields: b62 1e17 at 7997740455941656911841 (L30's), b60 1e16 x2 at L30's start, b64 1e16 at 0.35 + 0.55.
source /root/b64/scripts/lists.sh
R=/root/b64/scripts/run.sh; L=/root/b64/logs
IFS=, read -ra A <<< "$L64"
CFG=(0 2 4 6)
echo B_START $(date -u +%T)
# sanity: every variant at 1e14 (b62, b64; the stride compare of hits on), counts must equal v0's
for c in 0 2 4 6; do
  export NICE_EXP_JOIN_STAGE=$c NICE_TEST_JOIN_COMPARE=1; unset NICE_TEST_JOIN_LIST
  n=bsan_v${c}; $R $n E3 62,64 1 1e14; bash /root/b64/scripts/jit.sh $n
  echo "$(date -u +%T) $n $(grep -o 'base=[0-9]* .*survivors=[0-9]* checked=[0-9]*' $L/$n.log | grep -o 'base=[0-9]*\|survivors=[0-9]* checked=[0-9]*' | tr '\n' ' ') $(grep -c 'test result: ok' $L/$n.log)ok"
done
unset NICE_TEST_JOIN_COMPARE
for r in 1 2 3; do
  for f in "62 1 1e17" "60 2 1e16" "64 2 1e16"; do
    set -- $f
    for i in 0 1 2 3; do
      c=${CFG[$(( (i + r - 1) % 4 ))]}
      [ -e $L/stop ] && exit 0
      unset NICE_TEST_JOIN_LIST; export NICE_EXP_JOIN_STAGE=$c
      [ $1 = 64 ] && export NICE_TEST_JOIN_LIST=${A[3]},${A[5]}
      n=b_v${c}_b$1_$3_r$r; $R $n E3 $1 $2 $3; bash /root/b64/scripts/jit.sh $n
      echo "$(date -u +%T) $n $(grep -o 'secs=[0-9.]* per_field=[0-9.]*' $L/$n.log | tail -1) $(grep -o 'survivors=[0-9]* checked=[0-9]*' $L/$n.log | tail -1) $(grep -o 'join_kernel.*regs=[0-9]* local=[0-9]*' $L/${n}_jit.txt | head -1 | grep -o 'regs.*')"
    done
  done
done
echo B_DONE $(date -u +%T)
