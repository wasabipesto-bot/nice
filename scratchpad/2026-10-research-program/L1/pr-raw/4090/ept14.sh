#!/bin/bash
# EPT at production size with the prune: 1e14 fields, NICE_TEST_JOIN_FIELDS=$N consecutive fields per base from
# the A/B starts, EPT list $EPTS, 3 interleaved rounds.
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH
STARTS=58:104400216587923470200,60:1366406074057412100454,62:7997740455941656911841,64:41242006262957161709568
N=${N:-20}; EPTS=${EPTS:-"2 4"}
BIN=$(cat /root/ab/bin_ept)
cd /root/ept
for r in 1 2 3; do
  for ept in $EPTS; do
    echo "== $(date -u +%T) round=$r ept=$ept size=1e14 fields=$N"
    NICE_EXP_JOIN_EPT=$ept NICE_TEST_JOIN_FIELDS=$N NICE_TEST_JOIN_SIZE=1e14 NICE_TEST_JOIN_BASES=58,60,62,64 NICE_TEST_JOIN_STARTS=$STARTS \
      $BIN --ignored --exact cubecl_join::tests::cubecl_cuda_join_throughput_fixed_fields --nocapture --test-threads 1 > /root/ab/ept14_r${r}_e${ept}.log 2>&1
    grep -E "JOIN THROUGHPUT|panicked" /root/ab/ept14_r${r}_e${ept}.log
  done
done
echo "EPT14_DONE $(date -u +%T)"
