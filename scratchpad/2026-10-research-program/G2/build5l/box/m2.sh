#!/bin/bash
# box: piece 2's measurement, one session: per-slice stops on (4,8,5) field 77777 with and without parent sharing, then the
# ten fields (BUILD-NOTES §10.6's t values) through the trunk's bench (cc0a9e04 library, (4,9,6) fields) and this tree's
# ((4,8,5) default) without and with sharing, the trunk again at the end; $1 bin tag, $2 log dir
set -u
BN=/root/m5wbin/$1/midout_bench; T0=/root/mo/bin/mo_bench_merged; L=$2; mkdir -p $L; source /root/mo/guard.sh $L || exit 1
md5sum $BN $T0 > $L/bins.txt
F=13107,39321,65536,91750,117964,144179,170393,196608,222822,249036
nvidia-smi --query-gpu=timestamp,power.draw,clocks.sm,temperature.gpu,utilization.gpu,memory.used --format=csv,noheader -lms 1000 > $L/smi.csv & MP=$!
r() { n=$1; shift; echo "$(date -u +%FT%TZ) start $n" >> $L/runs.log; env "$@" > $L/$n.log 2>&1; rc=$?; echo "$(date -u +%FT%TZ) end $n rc=$rc" >> $L/runs.log; }
for s in 1 2 3; do
  r stop${s}_off MIDOUT_STOP=$s $BN --cuda --fields 77777 --no-cpu-check
  r stop${s}_on MIDOUT_STOP=$s $BN --cuda --fields 77777 --no-cpu-check --share-parents
done
r one_off X=1 $BN --cuda --fields 77777 --no-cpu-check
r one_on X=1 $BN --cuda --fields 77777 --no-cpu-check --share-parents
r ten_trunk X=1 $T0 --cuda --fields $F
r ten_off X=1 $BN --cuda --fields $F
r ten_on X=1 $BN --cuda --fields $F --share-parents
r ten_trunk2 X=1 $T0 --cuda --fields $F
kill $MP; echo done > $L/done
