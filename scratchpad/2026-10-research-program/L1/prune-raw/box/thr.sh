#!/bin/bash
# Usage: thr.sh TREE TAG SIZE FIELDS BASES [extra env...]
# One run of the fixed-field throughput harness on /root/TREE.
T=$1; TAG=$2; SIZE=$3; N=$4; BASES=$5
cd /root/$T
BIN=$(cat /root/ab/bin_$T)
echo "== $(date -u +%FT%TZ) tree=$T tag=$TAG size=$SIZE fields=$N bases=$BASES commit=$(git rev-parse --short HEAD)"
LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH NICE_TEST_JOIN_BASES=$BASES NICE_TEST_JOIN_FIELDS=$N NICE_TEST_JOIN_SIZE=$SIZE \
  $BIN --ignored --exact cubecl_join::tests::cubecl_cuda_join_throughput_fixed_fields --nocapture --test-threads 1 2>&1
echo "== end $(date -u +%FT%TZ) exit=$?"
