#!/bin/bash
# Production size: 20 consecutive 1e14 fields per base from the A/B starts (after a 1e14 warm-up),
# main / pr / ept2 (pr/join-ept-2) interleaved, 3 rounds (run under nohup).
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH
STARTS=58:104400216587923470200,60:1366406074057412100454,62:7997740455941656911841,64:41242006262957161709568
for r in 1 2 3; do
  for t in main pr ept2; do
    cd /root/$t
    echo "== $(date -u +%T) round=$r tree=$t commit=$(git rev-parse --short HEAD)"
    NICE_TEST_JOIN_FIELDS=20 NICE_TEST_JOIN_SIZE=1e14 NICE_TEST_JOIN_BASES=58,60,62,64 NICE_TEST_JOIN_STARTS=$STARTS \
      /root/bins/$t/nice_common_test --ignored --exact cubecl_join::tests::cubecl_cuda_join_throughput_fixed_fields \
      --nocapture --test-threads 1 > /root/ab/x14_r${r}_$t.log 2>&1
    grep -E "panicked|test result" /root/ab/x14_r${r}_$t.log
    grep -oE "base=[0-9]+ fields|per_field=[0-9.]+|device=[0-9.]+s|survivors=[0-9]+ checked=[0-9]+" /root/ab/x14_r${r}_$t.log | paste -d' ' - - - - | sed 's/^/   /'
  done
done
echo X14_DONE $(date -u +%T)
