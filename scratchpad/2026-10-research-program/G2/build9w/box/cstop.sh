#!/bin/bash
# box: cstop.sh OUT REF NEW — the wide main kernel's time, REF's wide bench against NEW's: cumulative timing stops
# 2 (through the parents) and 3 (through the main kernel) on base-65 field 77777, interleaved, one cold process each;
# holds /root/gpu.lock. Guarded.
set -u; O=/root/runs/$1; R=$2; N=$3; mkdir -p $O; rm -f $O/done
until mkdir /root/gpu.lockd 2>/dev/null; do sleep 10; done; trap 'rmdir /root/gpu.lockd' EXIT
source /root/guard.sh $O || exit 1
md5sum $R $N > $O/bins.txt
nvidia-smi --query-gpu=timestamp,power.draw,clocks.sm,temperature.gpu,utilization.gpu,memory.used --format=csv,noheader -lms 1000 > $O/smi.csv & MP=$!
r() { n=$1; st=$2; x=$3; echo "$(date -u +%FT%TZ) start $n" >> $O/runs.log; MIDOUT_STOP=$st $x --cuda --base 65 --fields 77777 > $O/$n.log 2>&1; echo "$(date -u +%FT%TZ) end $n rc=$? $(grep -o 'TIMING STOP: [0-9.]* s' $O/$n.log)" >> $O/runs.log; }
r ref_s3a 3 $R; r new_s3a 3 $N; r new_s2a 2 $N; r ref_s2a 2 $R; r ref_s3b 3 $R; r new_s3b 3 $N; r new_s3c 3 $N; r ref_s3c 3 $R
kill $MP; echo done > $O/done
