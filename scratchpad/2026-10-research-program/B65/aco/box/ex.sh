#!/bin/bash
# ex.sh TAG BIN [wide|narrow|both]: the ordinary device parity tests on lavapipe (SPIR-V, lavapipe's own plane width,
# not 64) to catch a broken variant early: wide b40 + b65 slices, narrow slices 712012851 + 318575442. Method of
# G2/build4s/box/ex.sh. Exactness is not claimed from these. B65 ACO study, 2026-11-28.
set -u
WT=/home/claude/projects/nice/.worktrees/mo-aco
B=/home/claude/projects/nice/scratchpad/2026-10-research-program/B65/aco
TAG=$1; BIN=$2; WHAT=${3:-both}; OUT=$B/ex/$TAG; mkdir -p $OUT; md5sum $BIN > $OUT/bin.md5
run() { local name=$1 test=$2; shift 2; local E=""; for e in "$@"; do E="$E -e $e"; done
  local t0=$(date +%s)
  timeout 3000 nice -n 19 podman run --rm --cgroups=disabled -v $WT:$WT -v $OUT:$OUT -w $OUT \
    -e VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/lvp_icd.json -e LP_NUM_THREADS=2 $E localhost/lvp26 \
    $BIN --ignored --exact $test --nocapture --test-threads 1 > $OUT/$name.log 2>&1
  local rc=$?; echo "$TAG $name rc=$rc $(( $(date +%s) - t0 )) s: $(grep -o 'test result: [a-zA-Z]*\. [0-9]* passed; [0-9]* failed' $OUT/$name.log)" | tee -a $OUT/rc.txt; }
if [ $WHAT != narrow ] && [ $WHAT != faults ]; then
  run wparity midout::gpu_wide::tests::wide_slices_equal_cpu MIDOUT_CLASSES=2 MIDOUT_WIDE_CASES=40:3:6:1234,65:4:10:717171717
fi
if [ $WHAT = faults ]; then
  run faults midout::gpu::audit::accounts_faults_are_loud MIDOUT_CLASSES=4 AUDIT_SLICES=712012851 AUDIT_AGAIN=0
  run wfaults midout::gpu_wide::tests::wide_faults_are_loud MIDOUT_CLASSES=2
fi
if [ $WHAT != wide ] && [ $WHAT != faults ]; then
  run parity midout::gpu::tests::gpu_slices_equal_cpu MIDOUT_CLASSES=4 MIDOUT_GPU_SLICES=712012851,318575442
fi
