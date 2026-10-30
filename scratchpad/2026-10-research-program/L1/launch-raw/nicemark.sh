#!/bin/bash
# NiceMark nice-only, main and pr interleaved x 3 (this card's own budget).
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH
for r in 1 2 3; do
  for t in main pr; do
    echo "== $(date -u +%T) nicemark round=$r tree=$t"
    nvidia-smi --query-gpu=timestamp,clocks.sm,power.draw,temperature.gpu,clocks_throttle_reasons.active,memory.used --format=csv -l 15 > /root/logs/nm_r${r}_$t.smi 2>&1 &
    SMI=$!
    RUST_LOG=info /root/bin/$t/nice_client niceonly --gpu --benchmark --benchmark-secs 150 --benchmark-json \
      < /dev/null > /root/logs/nm_r${r}_$t.json 2> /root/logs/nm_r${r}_$t.err
    echo "exit $? $(date -u +%T)"
    kill $SMI
  done
done
echo NM_DONE $(date -u +%T)
