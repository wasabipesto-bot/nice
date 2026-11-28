#!/bin/bash
# dump.sh TAG BIN wide|narrow: the 64-lane SPIR-V of the wide path at base 65 (wide_slices_equal_cpu, case
# 65:4:10:717171717, maxpop 18) or the narrow path at base 64 (gpu_slices_equal_cpu, slice 712012851) from a test
# binary built with cubecl/spirv-dump, via the compile-only path (MIDOUT_FORCE_W=64 on lavapipe W 8: results invalid
# by design, only the modules are wanted), then ACO for GFX1201 in g2mesa. Method of G2/build4s/box/dump.sh.
# B65 ACO study, 2026-11-28.
set -u
WT=/home/claude/projects/nice/.worktrees/mo-aco
B=/home/claude/projects/nice/scratchpad/2026-10-research-program/B65/aco
ACO=/home/claude/projects/nice/.worktrees/g2-cubecl/aco
TAG=$1; BIN=$2; WHAT=$3
OUT=/home/claude/projects/nice/.worktrees/g2-cubecl/g2out/b65aco/${TAG}_$WHAT; rm -rf $OUT; mkdir -p $OUT  # g2mesa mounts only g2-cubecl
case $WHAT in
  narrow) T=midout::gpu::tests::gpu_slices_equal_cpu; E="-e MIDOUT_GPU_SLICES=712012851 -e MIDOUT_CLASSES=1 -e MIDOUT_BATCHES=1";;
  wide)   T=midout::gpu_wide::tests::wide_slices_equal_cpu; E="-e MIDOUT_WIDE_CASES=65:4:10:717171717 -e MIDOUT_CLASSES=1";;
esac
md5sum $BIN > $OUT/bin.md5
timeout 1500 nice -n 19 podman run --rm --cgroups=disabled -v $WT:$WT -v $OUT:$OUT -w $OUT -e CUBECL_DEBUG_SPIRV=$OUT \
  -e VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/lvp_icd.json -e LP_NUM_THREADS=2 -e MIDOUT_FORCE_W=64 $E \
  localhost/lvp26 $BIN --ignored --exact $T --nocapture --test-threads 1 > $OUT/run.txt 2>&1
echo "run rc=$? (a failure is expected: W 64 on lavapipe's planes)"; grep -m3 'COMPILE-ONLY\|device' $OUT/run.txt
ls $OUT/*.spv | wc -l
podman exec g2mesa bash -c "for s in $OUT/*.spv; do spirv-val --target-env vulkan1.3 --uniform-buffer-standard-layout --allow-vulkan-32-bit-bitwise \$s > \${s%.spv}.val 2>&1 || echo spirv-val FAIL \$(basename \$s); done"
podman exec g2mesa bash $ACO/aco.sh $OUT
rm -rf $B/${TAG}_$WHAT; cp -r $OUT $B/
