#!/bin/bash
# ex.sh TAG BIN: the exactness set of step 4S on lavapipe (SPIR-V, W 8, container lvp26): the narrow path's parity
# test on two whole slices (device tops, lists n for n, every count) and its fault test (every fault loud, the
# sampled check sees the silent ones), and (WIDE=1) the wide parity at b40 and b65 and its fault test at b40.
set -u
W=/home/claude/projects/nice/.worktrees/midout
G=/home/claude/projects/nice/scratchpad/2026-10-research-program/G2
TAG=$1; BIN=$2; OUT=$G/build4s/ex/$TAG; mkdir -p $OUT
run() { local name=$1 test=$2; shift 2; local E=""; for e in "$@"; do E="$E -e $e"; done
  local t0=$(date +%s)
  timeout 3000 podman run --rm --cgroups=disabled -v $W:$W -v $G:$G -w $OUT \
    -e VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/lvp_icd.json -e LP_NUM_THREADS=2 $E localhost/lvp26 \
    $BIN --ignored --exact $test --nocapture --test-threads 1 > $OUT/$name.log 2>&1
  local rc=$?; echo "$name rc=$rc $(( $(date +%s) - t0 )) s: $(grep -o 'test result: [a-zA-Z]*\. [0-9]* passed; [0-9]* failed' $OUT/$name.log)"; }
run parity midout::gpu::tests::gpu_slices_equal_cpu MIDOUT_CLASSES=4 MIDOUT_GPU_SLICES=712012851,318575442
run faults midout::gpu::audit::accounts_faults_are_loud MIDOUT_CLASSES=4 AUDIT_SLICES=712012851 AUDIT_AGAIN=0
if [ "${WIDE:-0}" = 1 ]; then
  run wparity midout::gpu_wide::tests::wide_slices_equal_cpu MIDOUT_CLASSES=2 MIDOUT_WIDE_CASES=40:3:6:1234,65:4:10:717171717
  run wfaults midout::gpu_wide::tests::wide_faults_are_loud MIDOUT_CLASSES=2 MIDOUT_WIDE_FAULT_CASE=40:1234 MIDOUT_WIDE_FAULT_SHAPE=3:6 AUDIT_AGAIN=0
fi
