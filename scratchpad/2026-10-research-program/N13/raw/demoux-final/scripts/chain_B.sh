#!/bin/sh
# chain_B.sh: profile (tree E + patchC, main's join kernels + #250's FD; L51's modes c a z b p) on b62 1e17 at 0.45 (0.35 is empty at 1e17)
# and b60 1e16 at 0.55 + 0.85; mode c twice (the first with NICE_EXP_INFO=1), the others once.
W=/tmp/claude-exp-2026-11-11-amd; . $W/scripts/lists.sh; O=$W/out
one() { n=$1; shift; NICE_TEST_JOIN_LIST=$L sh $W/scripts/wrun.sh $n "$@"; echo "$(date -u +%T) $n $(grep -h 'JOIN THROUGHPUT' $O/$n.log | grep -o 'secs=[0-9.]*' | tr '\n' ' ')"; }
export NICE_EXP_GPU_PROFILE=1
for m in c a z b p c2; do
  [ -e $W/stop ] && exit 0
  mm=${m%2}; case $mm in c) a=0;; a) a=1;; b) a=2;; p) a=3;; z) a=4;; esac
  export NICE_EXP_JOIN_ABL=$a
  if [ $m = c ]; then export NICE_EXP_INFO=1; else unset NICE_EXP_INFO; fi
  L=7520566762397899821056 one p_${m}_b62 E 62 1 1e17
  L=$B60 one p_${m}_b60 E 60 2 1e16
done
echo B_DONE $(date -u +%T)
