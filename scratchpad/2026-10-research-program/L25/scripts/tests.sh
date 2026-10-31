#!/bin/bash
# tests.sh <tree dir> <tag> [cuda|lvp|host|tput|all]: join parity tests for one tree.
source /root/.cargo/env
TREE=$1; TAG=$2; WHAT=${3:-all}
L=/root/logs; mkdir -p $L
cd $TREE/common
T=$(ls -t $TREE/target/release/deps/nice_common-* | grep -v '\.d$' | head -1)
export NICE_API_BASE=http://127.0.0.1:9
LVP=/usr/share/vulkan/icd.d/lvp_icd.json
run() { # run <log> <env...> -- <filters...>
  local log=$1; shift
  local envs=(); while [ "$1" != "--" ]; do envs+=("$1"); shift; done; shift
  local s=$(date +%s)
  { echo "== $TAG $(git -C $TREE log --oneline -1) $(git -C $TREE status --short | tr '\n' ' ')"; date -u
    env "${envs[@]}" $T --ignored --nocapture --test-threads 1 "$@" 2>&1
    echo "rc=$? secs=$(( $(date +%s) - s ))"; } > $L/$log 2>&1
}
if [ $WHAT = host ] || [ $WHAT = all ]; then
  s=$(date +%s); { $T --test-threads 8 2>&1 | grep -E "^test result|FAILED|panicked|failures:" ; echo "rc=$? secs=$(( $(date +%s) - s ))"; } > $L/host_$TAG.log 2>&1
fi
if [ $WHAT = cuda ] || [ $WHAT = all ]; then
  run cuda_$TAG.log NICE_TEST_JOIN_DENSE=16 -- --exact \
    cubecl_join::tests::cubecl_cuda_join_matches_the_cpu_reference \
    cubecl_join::tests::cubecl_cuda_join_matches_the_cpu_join_on_a_dense_field \
    cubecl_backend::tests::cubecl_cuda_matches_cpu_niceonly
fi
if [ $WHAT = lvp ] || [ $WHAT = all ]; then
  run lvp_$TAG.log VK_ICD_FILENAMES=$LVP CUBECL_DEBUG_LOG=$L/wgsl_lvp_$TAG.log -- --exact \
    cubecl_join::tests::cubecl_join_matches_the_cpu_reference \
    cubecl_join::tests::join_sample_runs_partitions_of_a_production_field \
    cubecl_join::tests::cubecl_niceonly_keeps_join_and_stride_apart_by_ticket
fi
if [ $WHAT = tput ]; then
  run tput_$TAG.log NICE_TEST_JOIN_BASES=58,62 NICE_TEST_JOIN_FIELDS=3 -- --exact \
    cubecl_join::tests::cubecl_cuda_join_throughput_fixed_fields
fi
echo "TESTS_DONE $TAG $WHAT" >> $L/tests.status
