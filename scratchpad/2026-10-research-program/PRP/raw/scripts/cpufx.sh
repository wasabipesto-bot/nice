#!/bin/bash
# cpufx.sh: CPU join timing at b64 1e16 (0.55; every 256th partition, 16 partitions, one thread), the prefilter digits by
# multiplication (main) and by shifts (NICE_EXP_FX_SHIFT=1), alternating, 3 rounds each. Throwaway binary C.
L=/root/prp/logs/cpufx; mkdir -p $L; cd /tmp
for r in 1 2 3; do for m in 0 1; do
  NICE_EXP_FX_SHIFT=$m NICE_TEST_CPU_JOIN=256 NICE_TEST_CPU_JOIN_FIELD=64:58557331862957161709568:1e16 taskset -c 2 /root/prp/bin/C --ignored --exact cpu_join::tests::cpu_join_partition_timing --nocapture > $L/fx${m}_r$r.log 2>&1
  echo "r$r shift=$m $(grep -o "[0-9]* partitions in [0-9.]*s ([0-9.]* ms each)" $L/fx${m}_r$r.log) $(grep -o "survivors [0-9]* checked [0-9]*" $L/fx${m}_r$r.log)"
done; done
