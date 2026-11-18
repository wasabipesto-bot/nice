#!/bin/bash
# session 2: base 64 narrow vs wide in one process (first field = warm-up, discarded), then base 65 warm in one process
cd /root/mo
B=t-wide/release/examples/midout_wide_bench
L=logs/m2
mkdir -p $L
md5sum $B > $L/bin_md5.txt
nvidia-smi --query-gpu=timestamp,power.draw,clocks.sm,temperature.gpu,utilization.gpu,power.limit --format=csv -l 1 > $L/smi.csv 2>&1 &
SMI=$!
echo "$(date -u +%FT%TZ) start b64 warm" >> $L/runs.log
$B --cuda --base 64 --narrow --fields 4095,13107,131072,249036,65536,196608 > $L/b64_warm.log 2>&1
echo "$(date -u +%FT%TZ) b64 done rc=$?" >> $L/runs.log
kill $SMI
echo "$(date -u +%FT%TZ) end" >> $L/runs.log
