#!/bin/bash
# box: five3.sh OUT — the final timing, nothing else running: base 64 (narrow bench, the defaults: sampled check on)
# for the reference c2152084 (/root/bin/base) against the head (/root/bin/Ch), alternating field by field (ref first
# on fields 1, 3, 5); then base 65 (wide bench, sampled check off) for the reference, the tree before the shared-
# memory change (/root/bin/Bh) and the head (/root/bin/Ch), order rotated per field; one process per run after a
# warm-up field. Holds the GPU lock; guarded (hosts proof); nvidia-smi sampled every second.
set -u; O=/root/runs/$1; mkdir -p $O; rm -f $O/done
until mkdir /root/gpu.lockd 2>/dev/null; do sleep 10; done; trap 'rmdir /root/gpu.lockd' EXIT
source /root/guard.sh $O || exit 1
R=/root/bin/base; B=/root/bin/Bh; C=${HB:-/root/bin/Ch}
md5sum $R/midout_bench $R/midout_wide_bench $B/midout_wide_bench $C/midout_bench $C/midout_wide_bench > $O/bins.txt
uptime > $O/uptime.txt
nvidia-smi --query-gpu=timestamp,power.draw,clocks.sm,temperature.gpu,utilization.gpu,memory.used --format=csv,noheader -lms 1000 > $O/smi.csv & MP=$!
r() { n=$1; shift; echo "$(date -u +%FT%TZ) start $n" >> $O/runs.log; "$@" > $O/$n.log 2>&1; echo "$(date -u +%FT%TZ) end $n rc=$?" >> $O/runs.log; }
if [ -z "${ONLY65:-}" ]; then
r w64 $C/midout_bench --cuda --fields 4095 --no-cpu-check
i=0; for f in 13107 65536 117964 170393 222822; do i=$((i+1))
  if [ $((i % 2)) -eq 1 ]; then r ref64_$f $R/midout_bench --cuda --fields $f; r head64_$f $C/midout_bench --cuda --fields $f
  else r head64_$f $C/midout_bench --cuda --fields $f; r ref64_$f $R/midout_bench --cuda --fields $f; fi
done
fi
r w65 $C/midout_wide_bench --cuda --base 65 --fields 4095
i=0; for f in 13731 77777 137312 200000 260893; do i=$((i+1))
  case $((i % 3)) in
    1) r ref65_$f $R/midout_wide_bench --cuda --base 65 --fields $f; r b65_$f $B/midout_wide_bench --cuda --base 65 --fields $f; r head65_$f $C/midout_wide_bench --cuda --base 65 --fields $f;;
    2) r head65_$f $C/midout_wide_bench --cuda --base 65 --fields $f; r ref65_$f $R/midout_wide_bench --cuda --base 65 --fields $f; r b65_$f $B/midout_wide_bench --cuda --base 65 --fields $f;;
    0) r b65_$f $B/midout_wide_bench --cuda --base 65 --fields $f; r head65_$f $C/midout_wide_bench --cuda --base 65 --fields $f; r ref65_$f $R/midout_wide_bench --cuda --base 65 --fields $f;;
  esac
done
kill $MP; echo done > $O/done
