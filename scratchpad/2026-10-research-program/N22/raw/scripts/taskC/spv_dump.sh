#!/bin/sh
# spv_dump.sh MODE...: CubeCL's SPIR-V of every kernel a small lavapipe run compiles (binary N16dump, built with
# --features gpu,cubecl-spirv,cubecl/spirv-dump), into $OUT/spv_<mode>/. Two lavapipe threads, niced, killed after
# ${TMO:-60} s (only the compile is wanted).
. "${SCRIPTS:-/root/n16/scripts}/env.sh"
. "$SCRIPTS/modes.sh"
for m in ${@:-c}; do
  setmode $m; unset NICE_EXP_HOSTACC
  mkdir -p $OUT/spv_$m
  CUBECL_DEBUG_SPIRV=$OUT/spv_$m LP_NUM_THREADS=2 NICE_TEST_JOIN_FIELDS=1 NICE_TEST_JOIN_SIZE=1e13 NICE_TEST_JOIN_BASES=60 \
    NICE_TEST_JOIN_STARTS=60:$F60 NICE_TEST_JOIN_LIST=$F60 timeout ${TMO:-60} nice -n 19 "$BIN/N16dump" --ignored --exact \
    cubecl_join::tests::join_throughput_fixed_fields --nocapture --test-threads 1 > $OUT/spv_$m.log 2>&1
  echo "$m rc=$? $(ls $OUT/spv_$m | tr '\n' ' ')"
done
