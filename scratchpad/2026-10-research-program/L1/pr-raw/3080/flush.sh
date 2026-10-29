#!/bin/bash
# Stage flush level vs overruns (run under nohup): exp trees, one 1e16 field per base
# at the A/B starts. NICE_EXP_SURV_FLUSH = the stage level that triggers a flush (default 512).
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH
STARTS=58:104400216587923470200,60:1366406074057412100454,62:7997740455941656911841,64:41242006262957161709568
run() { # tag tree flush
  cd /root/$2
  echo "== $(date -u +%T) $1 tree=$2 flush=$3 commit=$(git rev-parse --short HEAD)"
  NICE_EXP_SURV_FLUSH=$3 NICE_TEST_JOIN_FIELDS=1 NICE_TEST_JOIN_SIZE=1e16 NICE_TEST_JOIN_BASES=58,60,62,64 \
    NICE_TEST_JOIN_STARTS=$STARTS /root/bins/$2/nice_common_test --ignored --exact \
    cubecl_join::tests::cubecl_cuda_join_throughput_fixed_fields --nocapture --test-threads 1 > /root/ab/fl_$1.log 2>&1
  grep -E "EXP_OVERRAN|panicked|test result" /root/ab/fl_$1.log
  grep -oE "base=[0-9]+ fields.*per_field=[0-9.]+|device=[0-9.]+s|survivors=[0-9]+ checked=[0-9]+" /root/ab/fl_$1.log | paste - - - | sed 's/^/   /'
}
run r1_xmain_512 xmain 512
run r1_xpr_512 xpr 512
run r1_xpr_256 xpr 256
run r1_xpr_128 xpr 128
run r2_xpr_256 xpr 256
run r2_xpr_512 xpr 512
echo FLUSH_DONE $(date -u +%T)
