#!/bin/sh
# chain_C.sh ROUNDS: retune screen on tree E (+ patchC), unprofiled: b62 1e17 at 0.45 (0.35 is empty at 1e17) and b60 1e16 at 0.55, one
# process each per variant; today's constants (base) at the start, middle and end; even rounds run the list reversed.
W=/tmp/claude-exp-2026-11-11-amd; O=$W/out
V1="base ept1 ept3 tm128 tm256 ag2 ag8 base2 tc128 tc512 vram wsync wide naga base3"
one() { n=$1; shift; NICE_TEST_JOIN_LIST=$L sh $W/scripts/wrun.sh $n "$@"; echo "$(date -u +%T) $n $(grep -h 'JOIN THROUGHPUT' $O/$n.log | grep -o 'secs=[0-9.]*\|slots=[0-9]*\|batches=[0-9]*\|survivors=[0-9]*\|checked=[0-9]*' | tr '\n' ' ')"; }
for r in ${1:-1 2}; do
  if [ $((r % 2)) = 1 ]; then V=$V1; else V=$(echo $V1 | tr ' ' '\n' | tac | tr '\n' ' '); fi
  for v in $V; do
    [ -e $W/stop ] && exit 0
    for k in NICE_EXP_JOIN_EPT NICE_EXP_JOIN_TMIN NICE_EXP_JOIN_AG NICE_EXP_JOIN_TCAP NICE_EXP_VRAM NICE_EXP_WALK_SYNC NICE_CUBECL_WIDE; do unset $k; done
    B=E
    case $v in
      ept1) export NICE_EXP_JOIN_EPT=1;; ept3) export NICE_EXP_JOIN_EPT=3;;
      tm128) export NICE_EXP_JOIN_TMIN=128;; tm256) export NICE_EXP_JOIN_TMIN=256;;
      ag2) export NICE_EXP_JOIN_AG=2;; ag8) export NICE_EXP_JOIN_AG=8;;
      tc128) export NICE_EXP_JOIN_TCAP=128 NICE_EXP_JOIN_TMIN=96;; tc512) export NICE_EXP_JOIN_TCAP=512;;
      vram) export NICE_EXP_VRAM=1;; wsync) export NICE_EXP_WALK_SYNC=1;; wide) export NICE_CUBECL_WIDE=1;;
      naga) B=E_naga;;
    esac
    L=7520566762397899821056 one s_${v}_b62_r$r $B 62 1 1e17
    L=1447429612114824200908 one s_${v}_b60_r$r $B 60 1 1e16
  done
done
echo C_DONE $(date -u +%T)
