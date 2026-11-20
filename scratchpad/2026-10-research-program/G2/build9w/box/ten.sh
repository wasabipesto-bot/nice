#!/bin/bash
# box: ten.sh OUT — the ten base-64 fields (t = 13107 ... 249036, the build notes' set) through the trunk's bench and
# the head's, alternating trunk, head, trunk, head in one session; the bench's defaults (group 16, parents shared,
# sampled CPU check on); nvidia-smi sampled every second. Guarded like card.sh.
set -u; O=/root/runs/$1; mkdir -p $O; rm -f $O/done; source /root/guard.sh $O || exit 1
T=/root/bin/trunkb/midout_bench; H=/root/bin/fin/midout_bench; md5sum $T $H > $O/bins.txt
F=13107,39321,65536,91750,117964,144179,170393,196608,222822,249036
nvidia-smi --query-gpu=timestamp,power.draw,clocks.sm,temperature.gpu,utilization.gpu,memory.used --format=csv,noheader -lms 1000 > $O/smi.csv & MP=$!
r() { n=$1; shift; echo "$(date -u +%FT%TZ) start $n" >> $O/runs.log; "$@" > $O/$n.log 2>&1; echo "$(date -u +%FT%TZ) end $n rc=$?" >> $O/runs.log; }
r warm $H --cuda --fields 4095 --no-cpu-check
r trunk1 $T --cuda --fields $F
r head1 $H --cuda --fields $F
r trunk2 $T --cuda --fields $F
r head2 $H --cuda --fields $F
kill $MP; echo done > $O/done
