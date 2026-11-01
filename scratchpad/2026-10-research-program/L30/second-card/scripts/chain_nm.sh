#!/bin/bash
# NiceMark nice-only, --benchmark-secs 150, interleaved per round main / #235 / #236 / both.
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH:-}
# no API traffic: the /ping latency samples fail fast and are reported as skipped
export NICE_API_BASE=http://127.0.0.1:9
L=/root/sc
cd /root
for r in 1 2 3; do
  for s in main p235 p236 both; do
    ( while true; do nvidia-smi --query-gpu=timestamp,clocks.sm,clocks.mem,power.draw,power.limit,temperature.gpu,utilization.gpu,clocks_throttle_reasons.active --format=csv,noheader; sleep 5; done ) > $L/nm_${s}_r$r.smi 2>&1 &
    SMI=$!
    echo "START nm_${s}_r$r $(date -u +%T) md5=$(md5sum $L/client_$s | cut -c1-8)" > $L/nm_${s}_r$r.err
    $L/client_$s niceonly --gpu --benchmark --benchmark-secs 150 --benchmark-json < /dev/null > $L/nm_${s}_r$r.json 2>> $L/nm_${s}_r$r.err
    echo "END nm_${s}_r$r $(date -u +%T) rc=$?" >> $L/nm_${s}_r$r.err
    kill $SMI
  done
done
echo CHAIN_NM_DONE $(date -u +%T) > $L/chainNM.done
