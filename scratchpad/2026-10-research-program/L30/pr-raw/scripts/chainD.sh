#!/bin/bash
# NiceMark nice-only, interleaved A B A B A B (A = client_main, B = client_pr).
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH:-}
L=/root/l30pr
cd /root
for r in 1 2 3; do
  for s in main pr; do
    ( while true; do nvidia-smi --query-gpu=timestamp,clocks.sm,clocks.mem,power.draw,power.limit,temperature.gpu,utilization.gpu,clocks_throttle_reasons.active --format=csv,noheader; sleep 5; done ) > $L/nm_${s}_r$r.smi 2>&1 &
    SMI=$!
    echo "START nm_${s}_r$r $(date -u +%T)" > $L/nm_${s}_r$r.err
    $L/client_$s niceonly --gpu --benchmark --benchmark-secs 150 --benchmark-json < /dev/null > $L/nm_${s}_r$r.json 2>> $L/nm_${s}_r$r.err
    echo "END nm_${s}_r$r $(date -u +%T) rc=$?" >> $L/nm_${s}_r$r.err
    kill $SMI
  done
done
echo CHAIN_D_DONE $(date -u +%T) > $L/chainD.done
