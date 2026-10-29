#!/bin/bash
# Exact counters (flush at 256: no overrun) on main, to compare with fl_r*_xpr_256 (the PR): one 1e16 field per base.
[ -n "$NOWAIT" ] || until grep -q CHAIN_DONE /root/ab/tests.log 2>/dev/null; do sleep 15; done
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH
STARTS=58:104400216587923470200,60:1366406074057412100454,62:7997740455941656911841,64:41242006262957161709568
cd /root/xmain
echo "== $(date -u +%T) xmain flush=256 commit=$(git rev-parse --short HEAD)"
NICE_EXP_SURV_FLUSH=256 NICE_TEST_JOIN_FIELDS=1 NICE_TEST_JOIN_SIZE=1e16 NICE_TEST_JOIN_BASES=58,60,62,64 \
  NICE_TEST_JOIN_STARTS=$STARTS /root/bins/xmain/nice_common_test --ignored --exact \
  cubecl_join::tests::cubecl_cuda_join_throughput_fixed_fields --nocapture --test-threads 1 > /root/ab/fl_r3_xmain_256.log 2>&1
grep -E "EXP_OVERRAN|panicked|test result" /root/ab/fl_r3_xmain_256.log
echo EXACT256_DONE $(date -u +%T)
