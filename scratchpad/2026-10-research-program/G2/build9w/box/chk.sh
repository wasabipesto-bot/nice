#!/bin/bash
# box: chk.sh OUT BINDIR — does the sampled check starve the device's host thread? Base 65 (wide bench) and base 64
# (narrow bench), five warm fields each with the check on and off, alternating (on, off on fields 1, 3, 5; off, on
# on 2, 4), one process per run after a warm-up field, the check on its default thread count (or CT). Guarded.
set -u; O=/root/runs/$1; D=$2; mkdir -p $O; rm -f $O/done; source /root/guard.sh $O || exit 1
md5sum $D/midout_bench $D/midout_wide_bench > $O/bins.txt
nvidia-smi --query-gpu=timestamp,power.draw,clocks.sm,temperature.gpu,utilization.gpu,memory.used --format=csv,noheader -lms 1000 > $O/smi.csv & MP=$!
r() { n=$1; shift; echo "$(date -u +%FT%TZ) start $n" >> $O/runs.log; "$@" > $O/$n.log 2>&1; echo "$(date -u +%FT%TZ) end $n rc=$?" >> $O/runs.log; }
CT=${CT:-0}
if [ -z "${ONLY64:-}" ]; then
r w65 $D/midout_wide_bench --cuda --base 65 --fields 4095
i=0; for f in 13731 77777 137312 200000 260893; do i=$((i+1))
  if [ $((i % 2)) -eq 1 ]; then r on65_$f $D/midout_wide_bench --cuda --base 65 --fields $f --cpu-check --cpu-threads $CT; r off65_$f $D/midout_wide_bench --cuda --base 65 --fields $f
  else r off65_$f $D/midout_wide_bench --cuda --base 65 --fields $f; r on65_$f $D/midout_wide_bench --cuda --base 65 --fields $f --cpu-check --cpu-threads $CT; fi
done
fi
r w64 $D/midout_bench --cuda --fields 4095 --no-cpu-check
i=0; for f in 13107 65536 117964 170393 222822; do i=$((i+1))
  if [ $((i % 2)) -eq 1 ]; then r on64_$f $D/midout_bench --cuda --fields $f --cpu-threads $CT; r off64_$f $D/midout_bench --cuda --fields $f --no-cpu-check
  else r off64_$f $D/midout_bench --cuda --fields $f --no-cpu-check; r on64_$f $D/midout_bench --cuda --fields $f --cpu-threads $CT; fi
done
kill $MP; echo done > $O/done
