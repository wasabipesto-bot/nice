#!/bin/bash
# pr/join-ept-2 itself at 1e16 (two fields per base), one round, to set beside the knob's three.
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH
STARTS=58:104400216587923470200,60:1366406074057412100454,62:7997740455941656911841,64:41242006262957161709568
cd /root/ept2
echo "== $(date -u +%T) tree=ept2 commit=$(git rev-parse --short HEAD)"
NICE_TEST_JOIN_FIELDS=2 NICE_TEST_JOIN_SIZE=1e16 NICE_TEST_JOIN_BASES=58,60,62,64 NICE_TEST_JOIN_STARTS=$STARTS \
  /root/bins/ept2/nice_common_test --ignored --exact cubecl_join::tests::cubecl_cuda_join_throughput_fixed_fields \
  --nocapture --test-threads 1 > /root/ab/thr_r4_ept2real.log 2>&1
grep -E "panicked|test result" /root/ab/thr_r4_ept2real.log
echo E16_DONE $(date -u +%T)
