#!/bin/bash
# NiceMark rounds 4-6 (main vs rp/launch-with-barrier), then the b58 1e15
# fixed-field A/B (main vs prb), 2 fields, 3 rounds, card's own budget.
source ~/.cargo/env
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH
cd /root/prb && git log --oneline -1
CARGO_TARGET_DIR=/root/pr/target cargo build --release -p nice_client --features gpu > /root/logs/build_prb_client.log 2>&1; echo "client exit $?" >> /root/logs/build_prb_client.log
tail -n 1 /root/logs/build_prb_client.log
cp /root/pr/target/release/nice_client /root/bin/prb/nice_client; md5sum /root/bin/prb/* > /root/bin/prb/md5.txt; cat /root/bin/prb/md5.txt
for r in 4 5 6; do
  for t in main prb; do
    echo "== $(date -u +%T) nicemark round=$r tree=$t"
    nvidia-smi --query-gpu=timestamp,clocks.sm,power.draw,temperature.gpu,clocks_throttle_reasons.active,memory.used --format=csv -l 15 > /root/logs/nm_r${r}_$t.smi 2>&1 &
    SMI=$!
    RUST_LOG=info /root/bin/$t/nice_client niceonly --gpu --benchmark --benchmark-secs 150 --benchmark-json \
      < /dev/null > /root/logs/nm_r${r}_$t.json 2> /root/logs/nm_r${r}_$t.err
    echo "exit $? $(date -u +%T)"
    kill $SMI
  done
done
for r in 1 2 3; do
  for t in main prb; do
    echo "== $(date -u +%T) b58 e15 round=$r tree=$t"
    nvidia-smi --query-gpu=timestamp,clocks.sm,power.draw,temperature.gpu,clocks_throttle_reasons.active,memory.used --format=csv -l 15 > /root/logs/h15_${t}_r$r.smi 2>&1 &
    SMI=$!
    NICE_TEST_JOIN_FIELDS=2 NICE_TEST_JOIN_SIZE=1e15 NICE_TEST_JOIN_BASES=58 NICE_TEST_JOIN_STARTS=58:104400216587923470200 \
      /root/bin/$t/nice_common_test --ignored --exact cubecl_join::tests::cubecl_cuda_join_throughput_fixed_fields --nocapture --test-threads 1 > /root/logs/h15_${t}_r$r.log 2>&1
    kill $SMI
    /root/summ.sh /root/logs/h15_${t}_r$r.log
  done
done
echo NM2_DONE $(date -u +%T)
