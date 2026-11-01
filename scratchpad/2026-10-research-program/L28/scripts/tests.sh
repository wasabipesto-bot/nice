#!/bin/bash
# tests.sh <label> <what>: run one tree's test binary (/root/bin/<label>-test)
# from /root/nice/common. what = cuda | lvp | dump | cudadump | host
source /root/.cargo/env
LABEL=$1; WHAT=$2
L=/root/logs/$LABEL; mkdir -p $L
T=/root/bin/$LABEL-test
cd /root/nice/common
export NICE_API_BASE=http://127.0.0.1:9
LVP=/usr/share/vulkan/icd.d/lvp_icd.json
run() { # run <log> <env...> -- <args...>
  local log=$1; shift
  local envs=(); while [ "$1" != "--" ]; do envs+=("$1"); shift; done; shift
  local s=$(date +%s)
  { echo "== $LABEL $(sha256sum $T | cut -c1-16) $*"; date -u
    env "${envs[@]}" $T "$@" 2>&1
    echo "rc=$? secs=$(( $(date +%s) - s ))"; } > $L/$log 2>&1
}
case $WHAT in
cuda)
  run cuda.log -- --ignored --nocapture --test-threads 1 --exact \
    cubecl_detailed_fd::tests::cubecl_cuda_fd_matches_cpu_detailed \
    cubecl_backend::tests::cubecl_cuda_matches_cpu_detailed \
    cubecl_backend::tests::cubecl_cuda_reads_back_every_near_miss \
    cubecl_detailed_fd::l28_local::l28_cuda_fd_sweep ;;
lvp)
  run lvp.log VK_ICD_FILENAMES=$LVP -- --ignored --nocapture --test-threads 1 --exact \
    cubecl_detailed_fd::tests::cubecl_fd_seed_matches_cpu \
    cubecl_detailed_fd::tests::cubecl_fd_matches_cpu_detailed \
    cubecl_backend::tests::cubecl_reads_back_every_near_miss \
    cubecl_backend::tests::cubecl_matches_cpu_detailed \
    cubecl_web::tests::web_fd_matches_cpu_detailed \
    cubecl_web::tests::web_fd_seed_matches_cpu \
    cubecl_detailed_fd::l28_local::l28_wgpu_fd_sweep ;;
dump)
  rm -f $L/wgsl.log
  run dump.log VK_ICD_FILENAMES=$LVP CUBECL_DEBUG_LOG=$L/wgsl.log -- --ignored --nocapture --test-threads 1 --exact \
    cubecl_backend::tests::wgsl_dump_for_lint
  python3 /root/nice/scripts/wgsl-lint.py $L/wgsl.log \
      --require DetailedKernelU32@80 --require DetailedFdKernelU32@40 \
      --require DetailedFdKernelU32@50 \
      --require DetailedFdKernel@23 --require DetailedFdKernel@40 \
      --require DetailedFdKernel@50 --require DetailedFdKernel@62 \
      --require DetailedKernel@80 --require NiceonlyKernel@40 \
      --require BucketKernel@57 --require JoinKernel@57 \
      --require TopKernel@57 --require CheckKernel@57 > $L/wgsl-lint.out 2>&1
  echo "lint rc=$?" >> $L/wgsl-lint.out ;;
cudadump)
  for b in 40 62; do
    rm -f $L/cuda_b$b.log
    run cudadump_b$b.log L28_CUDA=1 L28_BASE=$b CUBECL_DEBUG_LOG=$L/cuda_b$b.log -- --ignored --nocapture --test-threads 1 --exact \
      cubecl_detailed_fd::l28_local::l28_dump
  done ;;
host)
  run host.log -- 2>&1 ;;
esac
echo "TESTS_DONE $LABEL $WHAT $(date -u +%T)" >> /root/logs/tests.status
