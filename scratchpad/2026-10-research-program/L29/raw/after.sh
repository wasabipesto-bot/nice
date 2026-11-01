#!/bin/bash
# after.sh: once the A/B is done: per-phase profile (main+profile vs pr+profile),
# main dense b64 for the overrun reference, then the host test suite.
while ! grep -q AB_DONE /root/logs/ab.log; do sleep 10; done
cd /root
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH
for r in 1 2; do
  for t in mprof pprof; do
    echo "== $(date -u +%T) profile round=$r tree=$t"
    NICE_EXP_GPU_PROFILE=1 ./run.sh $t prof_${t}_r$r 1e16 1 62,60,64
    echo "done $(date -u +%T)"
  done
done
echo "== $(date -u +%T) dense64 main"
cd /root/src/main
NICE_TEST_JOIN_DENSE=8 NICE_TEST_JOIN_DENSE_FIELD=64:41242006262957161709568:1e16 /root/bin/main/nice_common_test --ignored --exact cubecl_join::tests::cubecl_cuda_join_matches_the_cpu_join_on_a_dense_field --nocapture --test-threads 1 > /root/logs/x_main_dense64.log 2>&1
echo "exit $? $(date -u +%T)"
echo "== $(date -u +%T) host suite pr"
cd /root/src/pr
/root/bin/pr/nice_common_test > /root/logs/host_pr.log 2>&1
echo "exit $? $(date -u +%T)"
echo AFTER_DONE $(date -u +%T)
