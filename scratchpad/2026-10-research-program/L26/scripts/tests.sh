#!/bin/bash
# tests.sh <tree> [what]: CUDA + lavapipe tests and WGSL dumps for one tree's
# test binary (/root/bin/<tree>-test), run from /root/nice/common.
source /root/.cargo/env
TREE=$1; WHAT=${2:-all}
L=/root/logs/$TREE; mkdir -p $L
T=/root/bin/$TREE-test
cd /root/nice/common
export NICE_API_BASE=http://127.0.0.1:9
LVP=/usr/share/vulkan/icd.d/lvp_icd.json
run() { # run <log> <env...> -- <tests...>
  local log=$1; shift
  local envs=(); while [ "$1" != "--" ]; do envs+=("$1"); shift; done; shift
  local s=$(date +%s)
  { echo "== $TREE $(sha256sum $T | cut -c1-16) $*"; date -u
    env "${envs[@]}" $T --ignored --nocapture --test-threads 1 --exact "$@" 2>&1
    echo "rc=$? secs=$(( $(date +%s) - s ))"; } > $L/$log 2>&1
}
if [ $WHAT = all ] || [ $WHAT = cuda ]; then
  run cuda.log -- \
    cubecl_backend::l26_local::l26_cuda_prefilter_probe \
    cubecl_backend::l26_local::l26_cuda_cross_filter \
    cubecl_backend::tests::cubecl_cuda_matches_cpu_niceonly
fi
if [ $WHAT = all ] || [ $WHAT = dump ]; then
  for b in 30 34 40; do
    run dump_b$b.log VK_ICD_FILENAMES=$LVP CUBECL_DEBUG_LOG=$L/wgsl_stride_b$b.log L26_BASE=$b -- \
      cubecl_backend::l26_local::l26_stride
  done
fi
if [ $WHAT = all ] || [ $WHAT = lvp ]; then
  run lvp.log VK_ICD_FILENAMES=$LVP CUBECL_DEBUG_LOG=$L/wgsl_lvp_tests.log -- \
    cubecl_backend::tests::cubecl_prefilter_survivors_match_the_host_mirror \
    cubecl_backend::tests::cubecl_matches_cpu_niceonly \
    cubecl_backend::tests::cubecl_cross_filter_survivors_match_the_host_mirror \
    cubecl_backend::tests::cubecl_niceonly_finds_69_in_base_10
fi
echo "TESTS_DONE $TREE $WHAT $(date -u +%T)" >> /root/logs/tests.status
