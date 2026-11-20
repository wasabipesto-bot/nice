#!/bin/bash
# box: xabl.sh OUT BIN — the wide expansion's time by part: cumulative timing stops 3 (through the main kernel) and
# 5 (through the expansion) on base-65 field 77777 (one cold process each; the one-time cost cancels in the
# difference), stop 5 with ablation bits (MIDOUT_XABL, read only by the diagnostic build xdiag.patch):
# 65536 no list writes; 131072 a trivial prefilter (rf % 31 == 0) instead of pf_w2; 262144 no per-bit work;
# 786432 no per-bit work and no top walk; 1048576 no record read; 1 F_NOPF (every survivor written).
# Guarded (hosts proof). nvidia-smi sampled every second.
set -u; O=/root/runs/$1; X=$2; mkdir -p $O; rm -f $O/done; source /root/guard.sh $O || exit 1
md5sum $X > $O/bins.txt
nvidia-smi --query-gpu=timestamp,power.draw,clocks.sm,temperature.gpu,utilization.gpu,memory.used --format=csv,noheader -lms 1000 > $O/smi.csv & MP=$!
r() { n=$1; st=$2; xa=$3; echo "$(date -u +%FT%TZ) start $n" >> $O/runs.log; MIDOUT_STOP=$st MIDOUT_XABL=$xa $X --cuda --base 65 --fields 77777 > $O/$n.log 2>&1; echo "$(date -u +%FT%TZ) end $n rc=$? $(grep -o 'TIMING STOP: [0-9.]* s' $O/$n.log)" >> $O/runs.log; }
r s3a 3 0
for v in ${XV:-0 65536 131072 262144 786432 1048576 1}; do r s5_$v 5 $v; done
r s3b 3 0
r s5_0b 5 0
kill $MP; echo done > $O/done
