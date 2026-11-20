#!/bin/bash
# box: bstop.sh OUT REF NEW — the wide expansion's time per slice, REF's wide bench against NEW's, interleaved:
# cumulative timing stops 3 and 5 on base-65 field 77777 (one cold process each). Guarded.
set -u; O=/root/runs/$1; R=$2; N=$3; mkdir -p $O; rm -f $O/done; source /root/guard.sh $O || exit 1
md5sum $R $N > $O/bins.txt
nvidia-smi --query-gpu=timestamp,power.draw,clocks.sm,temperature.gpu,utilization.gpu,memory.used --format=csv,noheader -lms 1000 > $O/smi.csv & MP=$!
r() { n=$1; st=$2; x=$3; echo "$(date -u +%FT%TZ) start $n" >> $O/runs.log; MIDOUT_STOP=$st $x --cuda --base 65 --fields 77777 > $O/$n.log 2>&1; echo "$(date -u +%FT%TZ) end $n rc=$? $(grep -o 'TIMING STOP: [0-9.]* s' $O/$n.log)" >> $O/runs.log; }
r ref_s3a 3 $R; r ref_s5a 5 $R; r new_s5a 5 $N; r new_s3a 3 $N; r new_s5b 5 $N; r ref_s5b 5 $R; r ref_s3b 3 $R; r new_s3b 3 $N
kill $MP; echo done > $O/done
