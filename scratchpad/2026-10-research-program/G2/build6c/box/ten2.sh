#!/bin/bash
# box: ten2.sh OUT — a second session of ten.sh's comparison: per-stage stops on field 77777 (cumulative: 2 parents,
# 3 main kernel, 5 expansion; no accounts), trunk and head alternating, twice; then the ten fields head, trunk, head,
# trunk (the reverse order of ten.sh). Guarded like ten.sh.
set -u; O=/root/runs/$1; mkdir -p $O; rm -f $O/done; source /root/guard.sh $O || exit 1
T=/root/bin/trunkb/midout_bench; H=/root/bin/fin/midout_bench; md5sum $T $H > $O/bins.txt
F=13107,39321,65536,91750,117964,144179,170393,196608,222822,249036
nvidia-smi --query-gpu=timestamp,power.draw,clocks.sm,temperature.gpu,utilization.gpu,memory.used --format=csv,noheader -lms 1000 > $O/smi.csv & MP=$!
r() { n=$1; shift; echo "$(date -u +%FT%TZ) start $n" >> $O/runs.log; env "$@" > $O/$n.log 2>&1; echo "$(date -u +%FT%TZ) end $n rc=$?" >> $O/runs.log; }
r warm X=1 $H --cuda --fields 4095 --no-cpu-check
for k in 1 2; do for s in 2 3 5; do
  r stop${s}_trunk$k MIDOUT_STOP=$s $T --cuda --fields 77777 --no-cpu-check
  r stop${s}_head$k MIDOUT_STOP=$s $H --cuda --fields 77777 --no-cpu-check
done; done
r head3 X=1 $H --cuda --fields $F
r trunk3 X=1 $T --cuda --fields $F
r head4 X=1 $H --cuda --fields $F
r trunk4 X=1 $T --cuda --fields $F
kill $MP; echo done > $O/done
