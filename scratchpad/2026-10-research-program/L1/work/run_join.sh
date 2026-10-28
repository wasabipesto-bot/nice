#!/bin/bash
# Usage: run_join.sh <label> <bases> <fields> <size> <profile 0|1>
set -u
cd /root/nice
LABEL=$1; BASES=$2; FIELDS=$3; SIZE=$4; PROF=$5
T=$(grep -o 'target/release/deps/nice_common-[0-9a-f]*' /root/build1.log | head -1)
mkdir -p /root/runs
OUT=/root/runs/$LABEL.log
{
  echo "# $(date -u +%FT%TZ) label=$LABEL bases=$BASES fields=$FIELDS size=$SIZE profile=$PROF starts=${STARTS:-default} commit=$(git rev-parse --short HEAD) test=$T"
  nvidia-smi --query-gpu=name,driver_version,clocks.sm,clocks.max.sm,temperature.gpu,power.draw --format=csv,noheader
  if [ "$PROF" = 1 ]; then export NICE_EXP_GPU_PROFILE=1; else unset NICE_EXP_GPU_PROFILE; fi
  NICE_TEST_JOIN_FIELDS=$FIELDS NICE_TEST_JOIN_SIZE=$SIZE NICE_TEST_JOIN_BASES=$BASES \
  NICE_TEST_JOIN_STARTS=${STARTS:-60:1366405974057412100454} \
    ./$T --ignored --exact cubecl_join::tests::cubecl_cuda_join_throughput_fixed_fields --nocapture --test-threads 1
  echo "# done $(date -u +%FT%TZ) rc=$?"
} > $OUT 2>&1
