#!/bin/bash
# narrow_tests.sh TAG: the narrow path's device tests once (CUDA, RTX 3060): gpu_slices_equal_cpu,
# accounts_faults_are_loud, field_parent_sharing_is_exact_and_loud.
. "$HOME/research/scripts/env.sh"
O=$R/runs/levers-final-tests; mkdir -p $O; TAG=$1; X=$R/bin/$TAG/t_box
export NICE_BUILD_SHA=test RUST_LOG=${RUST_LOG:-warn} CUDA_VISIBLE_DEVICES=1 MIDOUT_CUDA=1
for t in "--exact midout::gpu::tests::gpu_slices_equal_cpu" "accounts_faults_are_loud" "--exact midout::gpu::tests::field_parent_sharing_is_exact_and_loud"; do
  n=$(echo $t | sed 's/.*:://; s/--exact //'); s0=$(date +%s)
  $X --ignored $t --nocapture --test-threads 1 > $O/narrow_${TAG}_$n.txt 2>&1; rc=$?
  echo "$(date -u +%T) narrow_${TAG}_$n rc=$rc $(( $(date +%s) - s0 )) s $(grep -h -o 'test result: [a-zA-Z]*\. [0-9]* passed; [0-9]* failed' $O/narrow_${TAG}_$n.txt | tail -1)" >> $O/rc.txt
done
echo narrow-done > $O/narrow.done
