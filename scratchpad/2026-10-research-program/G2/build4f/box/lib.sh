#!/bin/bash
# the library's own results and cost on the same fields: midout_bench (b64, sampled check on) and midout_wide_bench (b65); $1 = run tag
set -u
B=/root/mo/bin; R=/root/mo/runs/$1; mkdir -p $R
N=${N64:-24}; T64=$(python3 -c "print(','.join(str((2*i+1)*262144//(2*$N)) for i in range($N)))")
md5sum $B/midout_bench $B/midout_wide_bench > $R/bin.txt
nvidia-smi --query-gpu=timestamp,power.draw,clocks.sm,temperature.gpu,utilization.gpu,memory.used --format=csv,noheader -lms 1000 > $R/smi.csv & MP=$!
echo "$(date -u +%FT%T.%3NZ) lib64 start" >> $R/run.log
$B/midout_bench --cuda --fields $T64 > $R/lib64.log 2>&1; echo "$(date -u +%FT%T.%3NZ) lib64 rc=$?" >> $R/run.log
$B/midout_wide_bench --cuda --base 65 --fields ${T65:-13731,77777} > $R/lib65.log 2>&1; echo "$(date -u +%FT%T.%3NZ) lib65 rc=$?" >> $R/run.log
kill $MP; echo done > $R/done
