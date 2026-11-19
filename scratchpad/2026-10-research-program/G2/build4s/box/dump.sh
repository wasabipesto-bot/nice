#!/bin/bash
# dump.sh TAG BIN [narrow|wide|hosttops]: run one library parity test on lavapipe (W 8) with MIDOUT_FORCE_W=64
# (FW=..), so that GpuJoin / WideJoin compile every kernel for W = 64 (`with_width`); lavapipe runs them on 8-lane
# planes, so the run's results are INVALID (the test prints COMPILE-ONLY and skips its CPU part); only the SPIR-V
# modules are wanted. (LP_NATIVE_VECTOR_WIDTH=2048 makes lavapipe report 64 itself, but its 2048-bit JIT crashed
# with "stack smashing detected" running the preparation, before the main kernel was compiled.) Modules land in g2-cubecl/g2out/s4/TAG_<what>/ (copied to G2/build4s/spv/), then spirv-val, then ACO for GFX1201 (g2mesa).
# Step 4S, 2026-11-19.
set -u
W=/home/claude/projects/nice/.worktrees/midout
G=/home/claude/projects/nice/scratchpad/2026-10-research-program/G2
ACO=/home/claude/projects/nice/.worktrees/g2-cubecl/aco
TAG=$1; BIN=$2; WHAT=${3:-narrow}; LPW=${LPW:-256}
OUT=/home/claude/projects/nice/.worktrees/g2-cubecl/g2out/s4/${TAG}_$WHAT; rm -rf $OUT; mkdir -p $OUT  # g2mesa mounts only that worktree
case $WHAT in
  narrow)   T=midout::gpu::tests::gpu_slices_equal_cpu; E="-e MIDOUT_GPU_SLICES=712012851 -e MIDOUT_CLASSES=1 -e MIDOUT_BATCHES=1";;
  hosttops) T=midout::gpu::tests::gpu_slices_equal_cpu; E="-e MIDOUT_GPU_SLICES=712012851 -e MIDOUT_CLASSES=1 -e MIDOUT_BATCHES=1 -e MIDOUT_HOST_TOPS=1";;
  wide)     T=midout::gpu_wide::tests::wide_slices_equal_cpu; E="-e MIDOUT_WIDE_CASES=65:4:10:717171717 -e MIDOUT_CLASSES=1";;
esac
timeout 1200 podman run --rm --cgroups=disabled -v $W:$W -v $G:$G -v $OUT:$OUT -w $OUT -e CUBECL_DEBUG_SPIRV=$OUT \
  -e VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/lvp_icd.json -e LP_NUM_THREADS=2 -e LP_NATIVE_VECTOR_WIDTH=$LPW -e MIDOUT_FORCE_W=${FW:-64} $E \
  localhost/lvp26 $BIN --ignored --exact $T --nocapture --test-threads 1 > $OUT/run.txt 2>&1
echo "run rc=$? (a failure is expected: W = 64 on 16-lane planes)"; grep -m3 'W \|device' $OUT/run.txt
ls $OUT/*.spv | wc -l
podman exec g2mesa bash -c "for s in $OUT/*.spv; do spirv-val --target-env vulkan1.3 --uniform-buffer-standard-layout --allow-vulkan-32-bit-bitwise \$s > \${s%.spv}.val 2>&1 || echo spirv-val FAIL \$(basename \$s); done"
podman exec g2mesa bash $ACO/aco.sh $OUT
mkdir -p $G/build4s/spv; rm -rf $G/build4s/spv/${TAG}_$WHAT; cp -r $OUT $G/build4s/spv/
