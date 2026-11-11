#!/bin/bash
# exact.sh NAME BIN START SIZE NPARTS: the dense-field test on another field: NPARTS partitions spread over slice 0, the
# device's hits and (survivors, checked) against the CPU join's (asserted equal).
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH:-} NICE_BUILD_SHA=test
L=/root/b64/logs; mkdir -p /root/b64/run/$1; cd /root/b64/run/$1
echo "START $1 $(date -u +%T) $2 64:$3:$4 parts=$5" > $L/$1.log
NICE_TEST_JOIN_DENSE=$5 NICE_TEST_JOIN_DENSE_FIELD=64:$3:$4 /root/b64/bin/$2 --ignored --exact \
  cubecl_join::tests::cubecl_cuda_join_matches_the_cpu_join_on_a_dense_field --nocapture --test-threads 1 >> $L/$1.log 2>&1
echo "END $1 $(date -u +%T) rc=$?" >> $L/$1.log
