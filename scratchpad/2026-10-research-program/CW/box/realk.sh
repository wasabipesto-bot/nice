#!/bin/bash
# box: the real main kernel on field 77777's first K slices (they include the dumped 4977728, 4977729) by timing
# stops: 2 (tops+parents), 3 (+ main kernel), 3 with MIDOUT_ABL3B (main kernel without phase 3b), 6 (whole slice);
# the head's binary (10ddbf17, no ablation code) at stop 3 as the control. Interleaved, R rounds. GPU clock/power logged.
K=${1:-256}; R=${2:-5}; O=/root/raw/realk_$(date -u +%H%M)
mkdir -p $O
nvidia-smi --query-gpu=timestamp,clocks.sm,clocks.mem,power.draw,temperature.gpu,utilization.gpu --format=csv -lms 250 > $O/smi.csv &
SMI=$!
B=/root/tgt/release/examples/midout_bench; H=/root/midout_bench_head
for r in $(seq 1 $R); do
  for s in 2 3 3a 3h 6; do
    case $s in
      3a) env MIDOUT_STOP=3 MIDOUT_ABL3B=1 $B --cuda --fields 77777 --slices $K --no-cpu-check ;;
      3h) env MIDOUT_STOP=3 $H --cuda --fields 77777 --slices $K --no-cpu-check ;;
      *)  env MIDOUT_STOP=$s $B --cuda --fields 77777 --slices $K --no-cpu-check ;;
    esac > $O/r${r}_s$s.txt 2>&1
    echo "$(date -u +%T) r$r s$s $(grep -o 'FIELD.*' $O/r${r}_s$s.txt)" >> $O/summary.txt
  done
done
kill $SMI; touch $O/done
