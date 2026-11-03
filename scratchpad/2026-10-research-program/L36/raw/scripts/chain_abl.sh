#!/bin/bash
# chain_abl.sh ROUNDS CONFIGS...: cubecl_cuda_top_fd_timing on the ablation binary X at b62 1e17 and b60 1e16,
# NICE_EXP_TOP_FD_ABL = each config in turn, rounds interleaved (each process = 3 internal rounds).
L=/root/l36/logs; T=/root/l36/test.sh
NR=$1; shift
TAG=${TAG:-abl}
for r in $(seq 1 $NR); do
  for F in 62:7997740455941656911841:1e17 60:1366406074057412100454:1e16; do
    b=${F%%:*}
    for c in "$@"; do
      SRCD=X $T ${TAG}_b${b}_a${c}_r$r X cubecl_join::tests::cubecl_cuda_top_fd_timing NICE_TEST_TOPFD_TIMING=$F NICE_EXP_TOP_FD_ABL=$c
    done
  done
done
echo ABL_DONE $(date -u +%T) > $L/${TAG}.done
