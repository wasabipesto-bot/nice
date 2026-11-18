#!/bin/bash
# session 1 on the box: base 64 narrow vs wide (alternating per field), base 65 fields, base 65 stage stops
cd /root/mo
B=t-wide/release/examples/midout_wide_bench
L=logs/m1
mkdir -p $L
md5sum $B > $L/bin_md5.txt
nvidia-smi -q -d POWER,CLOCK > $L/smi_q_start.txt
nvidia-smi --query-gpu=timestamp,power.draw,clocks.sm,temperature.gpu,utilization.gpu,power.limit --format=csv -l 1 > $L/smi.csv 2>&1 &
SMI=$!
echo "$(date -u +%FT%TZ) start b64" >> $L/runs.log
for t in 13107 131072 249036; do
  $B --cuda --base 64 --narrow --fields $t > $L/b64_t$t.log 2>&1
  echo "$(date -u +%FT%TZ) b64 t $t done rc=$?" >> $L/runs.log
done
echo "$(date -u +%FT%TZ) start b65" >> $L/runs.log
$B --cuda --base 65 --fields 13731,77777,137312,200000,260893 > $L/b65_5f.log 2>&1
echo "$(date -u +%FT%TZ) b65 done rc=$?" >> $L/runs.log
for s in 1 2 3 5; do
  MIDOUT_STOP=$s $B --cuda --base 65 --fields 137312 > $L/b65_stop$s.log 2>&1
  echo "$(date -u +%FT%TZ) b65 stop $s done rc=$?" >> $L/runs.log
done
for s in 1 2 3 5; do
  MIDOUT_STOP=$s $B --cuda --base 64 --fields 131072 > $L/b64w_stop$s.log 2>&1
  echo "$(date -u +%FT%TZ) b64 wide stop $s done rc=$?" >> $L/runs.log
done
kill $SMI
echo "$(date -u +%FT%TZ) end" >> $L/runs.log
