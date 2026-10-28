#!/bin/bash
# Exactness on the prune tree (run under nohup). GPU tests run one at a time.
source ~/.cargo/env
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH
STARTS=58:104400216587923470200,60:1366406074057412100454,62:7997740455941656911841,64:41242006262957161709568
BIN=$(cat /root/ab/bin_prune)
cd /root/prune
echo "== $(date -u +%T) non-ignored nice_common tests (gpu features)"
$BIN --test-threads 16 2>&1 | grep -E "^test result|FAILED|panicked|failures:" 
echo "== $(date -u +%T) ignored CUDA join tests (dense b58 1e15 on 64 partitions, whole b42 field)"
NICE_TEST_JOIN_DENSE=64 NICE_TEST_JOIN_FULL_FIELD=1 $BIN --ignored cubecl_cuda_join --skip throughput --test-threads 1 --nocapture 2>&1 | grep -vE "^\s*$" | tail -40
echo "== $(date -u +%T) CPU join vs reference on production fields (2 partitions each)"
NICE_TEST_CPU_JOIN_REF=2 $BIN --ignored --exact cpu_join::tests::cpu_join_matches_the_reference_on_production_fields --nocapture 2>&1 | grep -E "^b|test result|panicked"
echo "== $(date -u +%T) throughput harness with NICE_TEST_JOIN_COMPARE=1 (2 fields of 1e14 per base, A/B starts)"
NICE_TEST_JOIN_COMPARE=1 NICE_TEST_JOIN_FIELDS=2 NICE_TEST_JOIN_BASES=58,60,62,64 NICE_TEST_JOIN_STARTS=$STARTS \
  $BIN --ignored --exact cubecl_join::tests::cubecl_cuda_join_throughput_fixed_fields --nocapture --test-threads 1 2>&1 | grep -E "JOIN THROUGHPUT|STRIDE|test result|panicked|differs"
echo "== $(date -u +%T) bottoms before/after on the A/B fields (1e16, 2 per base)"
F=""
for bs in 58:104400216587923470200 60:1366406074057412100454 62:7997740455941656911841 64:41242006262957161709568; do
  b=${bs%%:*}; s=${bs#*:}
  F="$F,$b:$s:1e16,$b:$(python3 -c "print($s+10**16)"):1e16"
done
NICE_TEST_PRUNE_FIELDS=${F#,} $BIN --exact cpu_join::tests::the_field_prune_drops_exactly_the_bottoms_that_meet_the_certificate --nocapture 2>&1 | grep -E "^b|test result|panicked"
echo "EXACT_DONE $(date -u +%T)"
