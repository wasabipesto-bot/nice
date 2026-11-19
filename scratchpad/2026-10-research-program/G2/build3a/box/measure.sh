#!/bin/bash
# step 3A cost: cumulative stops on field 77777 before (91ac0761) and after (a7d3099a), then the 10 fields
cd /root/b3
grep -q "127.0.0.1 api.nicenumbers.net" /etc/hosts || { echo "ABORT: hosts block missing"; exit 1; }
OLD=/root/mo/mo_bench_head; NEW=/root/b3/mo_bench_3a
md5sum $OLD $NEW > bins.txt
nvidia-smi --query-gpu=timestamp,power.draw,clocks.sm,utilization.gpu,temperature.gpu --format=csv,noheader -l 5 > smi_measure.csv &
MP=$!
F10=13107,39321,65536,91750,117964,144179,170393,196607,222822,249036
for st in 1 2 3 5 6; do
  echo "== before stop $st $(date -u +%T)"; MIDOUT_STOP=$st $OLD --cuda --fields 77777 2>&1 | grep -E "FIELD|TOTAL|rror"
  echo "== after stop $st $(date -u +%T)"; MIDOUT_STOP=$st $NEW --cuda --fields 77777 --no-cpu-check 2>&1 | grep -E "FIELD|TOTAL|rror"
done > stops.log 2>&1
for r in 1 2; do
  echo "== before full $(date -u +%T)"; $OLD --cuda --fields 77777 2>&1 | grep -E "FIELD|TOTAL|rror"
  echo "== after full, no cpu check $(date -u +%T)"; $NEW --cuda --fields 77777 --no-cpu-check 2>&1 | grep -E "FIELD|TOTAL|rror"
  echo "== after full, cpu check $(date -u +%T)"; $NEW --cuda --fields 77777 2>&1 | grep -E "FIELD|TOTAL|SAMPLE|rror"
done > f77777.log 2>&1
echo "$(date -u +%FT%TZ) start ten_after_nocheck" >> runs.log
$NEW --cuda --group 16 --fields $F10 --no-cpu-check > ten_after_nocheck.log 2>&1
echo "$(date -u +%FT%TZ) start ten_before" >> runs.log
$OLD --cuda --group 16 --fields $F10 > ten_before.log 2>&1
echo "$(date -u +%FT%TZ) start ten_after_check" >> runs.log
$NEW --cuda --group 16 --fields $F10 > ten_after_check.log 2>&1
echo "$(date -u +%FT%TZ) end" >> runs.log
kill $MP
echo done > measure_done
