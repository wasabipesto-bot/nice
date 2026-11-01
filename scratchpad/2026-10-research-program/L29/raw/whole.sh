#!/bin/bash
while ! grep -q EXACT_DONE /root/logs/exact_pr.log; do sleep 5; done
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH
cd /root/src/pr
echo "== $(date -u +%T) whole"
NICE_TEST_JOIN_FULL_FIELD=1 /root/bin/pr/nice_common_test --ignored --exact cubecl_join::tests::cubecl_cuda_join_matches_the_reference_on_a_whole_field --nocapture --test-threads 1 > /root/logs/x_pr_whole_cuda.log 2>&1
echo "exit $? $(date -u +%T)"
echo WHOLE_DONE
