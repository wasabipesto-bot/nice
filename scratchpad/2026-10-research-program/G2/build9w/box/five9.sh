#!/bin/bash
# box: five9.sh OUT HEADDIR — five warm fields at base 64 (narrow bench, check on: the defaults) and base 65 (wide
# bench, sampled check as the route sets it: CK65=--cpu-check or empty), the reference c2152084 (/root/bin/base)
# against HEADDIR, alternating field by field (ref, head on fields 1, 3, 5; head, ref on 2, 4), one process per run
# after a warm-up field. Guarded (hosts proof). nvidia-smi sampled every second.
set -u; O=/root/runs/$1; H=$2; R=/root/bin/base; mkdir -p $O; rm -f $O/done; source /root/guard.sh $O || exit 1
md5sum $R/midout_bench $R/midout_wide_bench $H/midout_bench $H/midout_wide_bench > $O/bins.txt
nvidia-smi --query-gpu=timestamp,power.draw,clocks.sm,temperature.gpu,utilization.gpu,memory.used --format=csv,noheader -lms 1000 > $O/smi.csv & MP=$!
r() { n=$1; shift; echo "$(date -u +%FT%TZ) start $n" >> $O/runs.log; "$@" > $O/$n.log 2>&1; echo "$(date -u +%FT%TZ) end $n rc=$?" >> $O/runs.log; }
if [ -z "${ONLY65:-}" ]; then
r w64 $H/midout_bench --cuda --fields 4095 --no-cpu-check
i=0; for f in 13107 65536 117964 170393 222822; do i=$((i+1))
  if [ $((i % 2)) -eq 1 ]; then r ref64_$f $R/midout_bench --cuda --fields $f; r head64_$f $H/midout_bench --cuda --fields $f
  else r head64_$f $H/midout_bench --cuda --fields $f; r ref64_$f $R/midout_bench --cuda --fields $f; fi
done
fi
if [ -z "${ONLY64:-}" ]; then
r w65 $H/midout_wide_bench --cuda --base 65 --fields 4095
i=0; for f in 13731 77777 137312 200000 260893; do i=$((i+1))
  if [ $((i % 2)) -eq 1 ]; then r ref65_$f $R/midout_wide_bench --cuda --base 65 --fields $f; r head65_$f $H/midout_wide_bench --cuda --base 65 --fields $f ${CK65:-}
  else r head65_$f $H/midout_wide_bench --cuda --base 65 --fields $f ${CK65:-}; r ref65_$f $R/midout_wide_bench --cuda --base 65 --fields $f; fi
done
fi
kill $MP; echo done > $O/done
