#!/bin/bash
# post_a.sh C1: after the timing, on the RTX 3060: the first commit alone (its test against the baseline kernels),
# the brute-force small bases on the series' head (CUDA), the narrow tests once (head, CUDA).
. "$HOME/research/scripts/env.sh"
S=$R/b65/scripts; L=$R/b65l/scripts; C1=$1
bash $S/build_t.sh b65l2 $C1 cubecl-cuda,midout-box-tests c1-t-cuda
O=$R/runs/levers-final-tests; export NICE_BUILD_SHA=test RUST_LOG=warn CUDA_VISIBLE_DEVICES=1 MIDOUT_CUDA=1
g() { tag=$1; n=$2; shift 2; s0=$(date +%s); $R/bin/$tag/t_box --ignored "$@" --nocapture --test-threads 1 > $O/cuda_${tag}_$n.txt 2>&1; rc=$?
  echo "$(date -u +%T) cuda_${tag}_$n rc=$rc $(( $(date +%s) - s0 )) s $(grep -h -o 'test result: [a-zA-Z]*\. [0-9]* passed; [0-9]* failed' $O/cuda_${tag}_$n.txt | tail -1)" >> $O/rc.txt; }
g c1-t-cuda slices --exact midout::gpu_wide::tests::wide_slices_equal_cpu
bash $L/narrow_tests.sh fin-t-cuda
g fin-t-cuda brute --exact midout::gpu_wide::tests::wide_whole_small_bases_vs_brute_force
echo done > $O/post_a.done
