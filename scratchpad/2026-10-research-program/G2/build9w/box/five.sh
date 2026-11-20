#!/bin/bash
# box: five.sh OUT — five warm base-64 fields through 5a048669's bench and the head's, alternating field by field
# (ref, head on fields 1, 3, 5; head, ref on 2, 4) after one warm-up field; the bench's defaults (group 16,
# parents shared, sampled CPU check on); nvidia-smi sampled every second. Guarded (hosts proof).
set -u; O=/root/runs/$1; mkdir -p $O; rm -f $O/done; source /root/guard.sh $O || exit 1
R=/root/bin/base5a/midout_bench; H=/root/bin/fin/midout_bench; md5sum $R $H > $O/bins.txt
nvidia-smi --query-gpu=timestamp,power.draw,clocks.sm,temperature.gpu,utilization.gpu,memory.used --format=csv,noheader -lms 1000 > $O/smi.csv & MP=$!
r() { n=$1; shift; echo "$(date -u +%FT%TZ) start $n" >> $O/runs.log; "$@" > $O/$n.log 2>&1; echo "$(date -u +%FT%TZ) end $n rc=$?" >> $O/runs.log; }
r warm $H --cuda --fields 4095 --no-cpu-check
i=0
for f in 13107 65536 117964 170393 222822; do
  i=$((i+1))
  if [ $((i % 2)) -eq 1 ]; then r ref_$f $R --cuda --fields $f; r head_$f $H --cuda --fields $f
  else r head_$f $H --cuda --fields $f; r ref_$f $R --cuda --fields $f; fi
done
kill $MP; echo done > $O/done
