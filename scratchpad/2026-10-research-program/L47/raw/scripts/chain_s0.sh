#!/bin/bash
# chain_s0.sh: L47 step 0 on binary S0 (profile on): the full check at 1024 / 408 / 2048 cubes and the gather-only
# kernel at 1024 / 408 cubes; b62 1e17 (1 field) and b60 1e16 (2 fields); 2 rounds, the order reversed in round 2.
R=/root/l47/scripts/run.sh; L=/root/l47/logs
export NICE_EXP_GPU_PROFILE=1
echo S0_START $(date -u +%T)
for r in 1 2; do
  M="F1024 G1024 F408 F2048 G408"; [ $r = 2 ] && M="G408 F2048 F408 G1024 F1024"
  for f in "62 e17_b62 1 1e17" "60 e16_b60 2 1e16"; do
    set -- $f
    for m in $M; do
      unset NICE_EXP_CHECK
      case $m in G*) export NICE_EXP_CHECK=gather;; esac
      export NICE_EXP_CHECK_CUBES=${m:1}
      SRCD=S0 $R s0_${m}_$2_r$r S0 $1 $3 $4
    done
  done
done
echo S0_DONE $(date -u +%T) > $L/s0.done
