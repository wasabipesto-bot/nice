#!/bin/sh
# chain_C3.sh: third round for the movers of chain_C (tc128 = TOP_CAP 128 / TRANSPOSE_MIN 96; vram = CUDA's denser
# plan), the near-movers (tm128, ag8) and the combination tc128 + vram, between base runs; same fields.
W=/tmp/claude-exp-2026-11-11-amd; O=$W/out
one() { n=$1; shift; NICE_TEST_JOIN_LIST=$L sh $W/scripts/wrun.sh $n "$@"; echo "$(date -u +%T) $n $(grep -h 'JOIN THROUGHPUT' $O/$n.log | grep -o 'secs=[0-9.]*\|slots=[0-9]*\|batches=[0-9]*\|survivors=[0-9]*\|checked=[0-9]*' | tr '\n' ' ')"; }
for v in base tc128 vram tcvram base2 tm128 ag8 base3; do
  [ -e $W/stop ] && exit 0
  for k in NICE_EXP_JOIN_TMIN NICE_EXP_JOIN_AG NICE_EXP_JOIN_TCAP NICE_EXP_VRAM; do unset $k; done
  case $v in
    tc128) export NICE_EXP_JOIN_TCAP=128 NICE_EXP_JOIN_TMIN=96;;
    vram) export NICE_EXP_VRAM=1;;
    tcvram) export NICE_EXP_JOIN_TCAP=128 NICE_EXP_JOIN_TMIN=96 NICE_EXP_VRAM=1;;
    tm128) export NICE_EXP_JOIN_TMIN=128;; ag8) export NICE_EXP_JOIN_AG=8;;
  esac
  L=7520566762397899821056 one s_${v}_b62_r3 E 62 1 1e17
  L=1447429612114824200908 one s_${v}_b60_r3 E 60 1 1e16
done
echo C3_DONE $(date -u +%T)
