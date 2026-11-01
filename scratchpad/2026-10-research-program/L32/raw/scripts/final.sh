#!/bin/bash
# After post (quiet box again): NiceMark rounds 2-3 (B A A B), then b60 1e16 round 4 (tail, base).
L=/root/pad
until [ -e $L/post.done ]; do sleep 15; done
echo "FINAL start $(date -u +%T)"
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH:-}
export NICE_API_BASE=http://127.0.0.1:9
cd /root
for s in tail2 off2 off3 tail3; do
  case $s in tail*) export NICE_EXP_JOIN_TAIL=1;; *) unset NICE_EXP_JOIN_TAIL;; esac
  ( while true; do nvidia-smi --query-gpu=timestamp,clocks.sm,clocks.mem,power.draw,power.limit,temperature.gpu,utilization.gpu,clocks_throttle_reasons.active --format=csv,noheader; sleep 5; done ) > $L/nm_$s.smi 2>&1 &
  SMI=$!
  echo "START nm_$s $(date -u +%T) md5=$(md5sum $L/client_pad | cut -c1-8) tail=${NICE_EXP_JOIN_TAIL:-}" > $L/nm_$s.err
  $L/client_pad niceonly --gpu --benchmark --benchmark-secs 150 --benchmark-json < /dev/null > $L/nm_$s.json 2>> $L/nm_$s.err
  echo "END nm_$s $(date -u +%T) rc=$?" >> $L/nm_$s.err
  kill $SMI
done
unset NICE_EXP_JOIN_TAIL
/root/run.sh ab_tail_e16_b60_r4 pad 60 2 1e16 0 NICE_EXP_JOIN_TAIL=1
/root/run.sh ab_base_e16_b60_r4 base 60 2 1e16 0
echo "FINAL DONE $(date -u +%T)" > $L/final.done
