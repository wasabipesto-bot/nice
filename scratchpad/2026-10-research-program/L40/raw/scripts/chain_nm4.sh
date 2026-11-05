#!/bin/bash
# chain_nm4.sh: after A/B 3 (ab3.done): 4 more NiceMark rounds of M and H2 (order M H2, H2 M, M H2, H2 M; logs nm4_*),
# nothing else on the box, to pin b58 MSD-strong (a short, noisy scenario); then chain_final.sh (and, once Q is
# built, chain_cpu_q.sh).
L=/root/l40/logs; BIN=/root/l40/bin
until [ -e $L/ab3.done ]; do sleep 10; done
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH:-} NICE_API_BASE=http://127.0.0.1:9 NICE_BUILD_SHA=test
echo NM4_START $(date -u +%T)
for r in 1 2 3 4; do
  if [ $((r % 2)) = 0 ]; then O="H2 M"; else O="M H2"; fi
  for t in $O; do
    ( while true; do nvidia-smi --query-gpu=timestamp,clocks.sm,clocks.mem,power.draw,power.limit,temperature.gpu,utilization.gpu,clocks_throttle_reasons.active --format=csv,noheader; sleep 5; done ) > $L/nm4_${t}_r$r.smi 2>&1 &
    SMI=$!
    echo "START nm4_${t}_r$r $(date -u +%T) bin=client_$t md5=$(md5sum $BIN/client_$t | cut -c1-8)" > $L/nm4_${t}_r$r.err
    (cd /root/l40 && $BIN/client_$t niceonly --gpu --benchmark --benchmark-secs 150 --benchmark-json < /dev/null > $L/nm4_${t}_r$r.json 2>> $L/nm4_${t}_r$r.err)
    echo "END nm4_${t}_r$r $(date -u +%T) rc=$?" >> $L/nm4_${t}_r$r.err
    kill $SMI
  done
done
echo NM4_DONE $(date -u +%T)
(setsid nohup /root/l40/chain_cpu_q.sh > $L/chain_cpu_q.out 2>&1 < /dev/null &)
/root/l40/chain_final.sh > $L/chain_final.out 2>&1
echo CHAIN_NM4_DONE $(date -u +%T)
