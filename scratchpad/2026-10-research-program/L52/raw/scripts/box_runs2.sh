#!/bin/bash
# Second block on the AVX-512 box: rounds 4-6, 1 and 8 threads (the
# container's CPU quota is ~15 cores, so 16-thread runs were noisy).
O=/root/l52
R=$O/runs2.txt
for r in 4 5 6; do
  if (( r % 2 == 1 )); then ORDER="base pr pr-avx2"; else ORDER="pr-avx2 pr base"; fi
  for c in "b60e16_1t|60 1157209632114824200908 1e16 1 4" "b62e17s0_1t|62 4473066762334864396992 1e17 1 4 0" "b60e16_8t|60 1157209632114824200908 1e16 8 32" "b62e17s0_8t|62 4473066762334864396992 1e17 8 32 0"; do
    name=${c%%|*}; args=${c#*|}
    for bin in $ORDER; do
      echo "### r$r $name $bin $(date -u +%H:%M:%S) load $(cut -d' ' -f1 /proc/loadavg)" >> $R
      $O/bin/$bin $args >> $R 2>&1
    done
  done
done
touch $O/DONE2
