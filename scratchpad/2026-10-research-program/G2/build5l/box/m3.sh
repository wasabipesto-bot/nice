#!/bin/bash
# box: piece 3's measurement, one session: base 64 and base 65 fields (BUILD-NOTES §11.4's t values, t 4095 first as warm-up),
# the wide prefilter in base b^2 against digit by digit, b64 before and after; per-stage stops at b65; $1 bin tag, $2 log dir,
# $3 extra b64 flag (e.g. --share-parents or none)
set -u
BN=/root/m5wbin/$1/midout_bench; BW=/root/m5wbin/$1/midout_wide_bench; L=$2; X64=${3:-}; mkdir -p $L; source /root/mo/guard.sh $L || exit 1
md5sum $BN $BW > $L/bins.txt
nvidia-smi --query-gpu=timestamp,power.draw,clocks.sm,temperature.gpu,utilization.gpu,memory.used --format=csv,noheader -lms 1000 > $L/smi.csv & MP=$!
r() { n=$1; shift; echo "$(date -u +%FT%TZ) start $n" >> $L/runs.log; env "$@" > $L/$n.log 2>&1; rc=$?; echo "$(date -u +%FT%TZ) end $n rc=$rc" >> $L/runs.log; }
r b64_a X=1 $BN --cuda --fields 4095,13107,131072,249036,65536,196608 --no-cpu-check $X64
r b65_pf2 X=1 $BW --cuda --base 65 --fields 4095,13731,77777,137312,200000,260893
r b65_pfd X=1 $BW --cuda --base 65 --fields 4095,13731,77777,137312,200000,260893 --pf-digits
r b64_b X=1 $BN --cuda --fields 4095,13107,131072,249036,65536,196608 --no-cpu-check $X64
for s in 3 5; do
  r w65stop${s}_pf2 MIDOUT_STOP=$s $BW --cuda --base 65 --fields 77777
  r w65stop${s}_pfd MIDOUT_STOP=$s $BW --cuda --base 65 --fields 77777 --pf-digits
done
kill $MP; echo done > $L/done
