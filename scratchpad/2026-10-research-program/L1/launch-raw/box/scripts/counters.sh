#!/bin/bash
# The extra-checks study on the experiment binary (PR + counters): b64 1e14,
# 20 fields, at 16, 32, 64 partitions per launch and the PR's own (memory-
# bound) count, each 3 times, then the same with NICE_EXP_FLUSH_SYNC=1.
# Budget: this card's own (4 GiB), so 64 fits on main's sizing too.
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH
STARTS=64:41242006262957161709568
for rep in 1 2 3; do
  for sync in 0 1; do
    for s in 16 32 64 max; do
      tag=cnt_s${s}_sync${sync}_r$rep
      if [ $s = max ]; then se=NICE_EXP_NONE=1; else se=NICE_EXP_SLOTS=$s; fi
      echo "== $(date -u +%T) $tag"
      env NICE_EXP_FLUSH_SYNC=$sync $se NICE_TEST_JOIN_FIELDS=20 NICE_TEST_JOIN_SIZE=1e14 NICE_TEST_JOIN_BASES=64 NICE_TEST_JOIN_STARTS=$STARTS \
        /root/bin/exp/nice_common_test --ignored --exact cubecl_join::tests::cubecl_cuda_join_throughput_fixed_fields --nocapture --test-threads 1 > /root/logs/$tag.log 2>&1
      /root/summ.sh /root/logs/$tag.log
    done
  done
done
echo COUNTERS_DONE $(date -u +%T)
