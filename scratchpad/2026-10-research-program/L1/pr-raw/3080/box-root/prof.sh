#!/bin/bash
# Profiled runs (NICE_EXP_GPU_PROFILE=1): main vs the PR, and the PR at EPT 2; 1 field of 1e16 per base.
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH
FLUSH=${FLUSH:?set FLUSH}
STARTS=58:104400216587923470200,60:1366406074057412100454,62:7997740455941656911841,64:41242006262957161709568
for t in ${PROF_TREES:-xmain xpr xpr_ept2}; do
  case $t in
    xmain)    dir=xmain; envs="";;
    xpr)      dir=xpr;   envs="NICE_EXP_SURV_FLUSH=$FLUSH";;
    xpr_ept2) dir=xpr;   envs="NICE_EXP_SURV_FLUSH=$FLUSH NICE_EXP_JOIN_EPT=2";;
  esac
  cd /root/$dir
  echo "== $(date -u +%T) tree=$t commit=$(git rev-parse --short HEAD) $envs"
  env $envs NICE_EXP_GPU_PROFILE=1 NICE_TEST_JOIN_FIELDS=1 NICE_TEST_JOIN_SIZE=1e16 NICE_TEST_JOIN_BASES=58,60,62,64 \
    NICE_TEST_JOIN_STARTS=$STARTS /root/bins/$dir/nice_common_test --ignored --exact \
    cubecl_join::tests::cubecl_cuda_join_throughput_fixed_fields --nocapture --test-threads 1 > /root/ab/prof_$t.log 2>&1
  grep -E "panicked|test result|EXP_OVERRAN" /root/ab/prof_$t.log
done
echo PROF_DONE $(date -u +%T)
