#!/bin/bash
# ab.sh: interleaved main/pr rounds: b62 1e17 (1 field x 3 rounds), then
# b62, b60, b64 at 1e16 (2 fields each x 3 rounds), then NiceMark x 3.
cd /root
for r in 1 2 3; do
  for t in main pr; do
    echo "== $(date -u +%T) e17 round=$r tree=$t"
    ./run.sh $t e17_${t}_r$r 1e17 1 62
    echo "done $(date -u +%T) $(grep -o 'per_field=[0-9.]*' logs/e17_${t}_r$r.log)"
  done
done
for r in 1 2 3; do
  for t in main pr; do
    echo "== $(date -u +%T) e16 round=$r tree=$t"
    ./run.sh $t e16_${t}_r$r 1e16 2 62,60,64
    echo "done $(date -u +%T) $(grep -o 'per_field=[0-9.]*' logs/e16_${t}_r$r.log | tr '\n' ' ')"
  done
done
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH
for r in 1 2 3; do
  for t in main pr; do
    echo "== $(date -u +%T) nicemark round=$r tree=$t"
    nvidia-smi --query-gpu=timestamp,clocks.sm,power.draw,temperature.gpu,clocks_throttle_reasons.active,memory.used --format=csv -l 5 > logs/nm_r${r}_$t.smi 2>&1 &
    SMI=$!
    RUST_LOG=info /root/bin/$t/nice_client niceonly --gpu --benchmark --benchmark-secs 150 --benchmark-json \
      < /dev/null > logs/nm_r${r}_$t.json 2> logs/nm_r${r}_$t.err
    echo "exit $? $(date -u +%T)"
    kill $SMI
  done
done
echo AB_DONE $(date -u +%T)
