#!/bin/bash
# NiceMark once each: A, then B with each ER in "$@" (default 2 6). Nothing else runs.
ERS=${@:-2 6}
L=/root/l33/logs; BIN=/root/l33/bin
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH:-}
export NICE_API_BASE=http://127.0.0.1:9 NICE_BUILD_SHA=test
cd /root/l33
for s in A $ERS; do
  if [ $s = A ]; then unset NICE_EXP_TOP_ER; C=client_A; N=nm_A; else export NICE_EXP_TOP_ER=$s; C=client_B; N=nm_er$s; fi
  ( while true; do nvidia-smi --query-gpu=timestamp,clocks.sm,clocks.mem,power.draw,power.limit,temperature.gpu,utilization.gpu,clocks_throttle_reasons.active --format=csv,noheader; sleep 5; done ) > $L/$N.smi 2>&1 &
  SMI=$!
  echo "START $N $(date -u +%T) md5=$(md5sum $BIN/$C | cut -c1-8) er=${NICE_EXP_TOP_ER:-}" > $L/$N.err
  $BIN/$C niceonly --gpu --benchmark --benchmark-secs 150 --benchmark-json < /dev/null > $L/$N.json 2>> $L/$N.err
  echo "END $N $(date -u +%T) rc=$?" >> $L/$N.err
  kill $SMI
done
echo CHAIN_NM_DONE $(date -u +%T) > $L/chainNM.done
