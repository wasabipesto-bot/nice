#!/bin/bash
# NiceMark nice-only once per arm: client_pad with the tail off, then on (no API traffic).
L=/root/pad
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH:-}
export NICE_API_BASE=http://127.0.0.1:9
cd /root
for s in off tail off2 tail2; do
  case $s in tail*) export NICE_EXP_JOIN_TAIL=1;; *) unset NICE_EXP_JOIN_TAIL;; esac
  [ -e $L/nm_more ] || case $s in *2) continue;; esac
  ( while true; do nvidia-smi --query-gpu=timestamp,clocks.sm,clocks.mem,power.draw,power.limit,temperature.gpu,utilization.gpu,clocks_throttle_reasons.active --format=csv,noheader; sleep 5; done ) > $L/nm_$s.smi 2>&1 &
  SMI=$!
  echo "START nm_$s $(date -u +%T) md5=$(md5sum $L/client_pad | cut -c1-8) tail=${NICE_EXP_JOIN_TAIL:-}" > $L/nm_$s.err
  $L/client_pad niceonly --gpu --benchmark --benchmark-secs 150 --benchmark-json < /dev/null > $L/nm_$s.json 2>> $L/nm_$s.err
  echo "END nm_$s $(date -u +%T) rc=$?" >> $L/nm_$s.err
  kill $SMI
done
echo CHAIN_NM_DONE $(date -u +%T) > $L/chainNM.done
