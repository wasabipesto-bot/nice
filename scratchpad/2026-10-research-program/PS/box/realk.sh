#!/bin/bash
# box (PS copy of CW/box/realk.sh, stops 2, 3 and 3 ablated only): the real main kernel on field 77777's first K
# slices, interleaved, R rounds, GPU clock/power logged; 3b in situ = stop 3 - stop 3 with MIDOUT_ABL3B
K=${1:-4096}; R=${2:-3}; O=/root/raw/realk_$(date -u +%H%M)
mkdir -p $O
nvidia-smi --query-gpu=timestamp,clocks.sm,clocks.mem,power.draw,temperature.gpu,utilization.gpu --format=csv -lms 250 > $O/smi.csv &
SMI=$!
B=/root/tgt/release/examples/midout_bench
for r in $(seq 1 $R); do
  for s in 2 3 3a; do
    case $s in
      3a) env MIDOUT_STOP=3 MIDOUT_ABL3B=1 $B --cuda --fields 77777 --slices $K --no-cpu-check ;;
      *)  env MIDOUT_STOP=$s $B --cuda --fields 77777 --slices $K --no-cpu-check ;;
    esac > $O/r${r}_s$s.txt 2>&1
    echo "$(date -u +%T) r$r s$s $(grep -o 'FIELD.*' $O/r${r}_s$s.txt)" >> $O/summary.txt
  done
done
kill $SMI; touch $O/done
