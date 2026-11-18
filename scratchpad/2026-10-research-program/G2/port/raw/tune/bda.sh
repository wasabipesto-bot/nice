#!/bin/bash
# bda.sh TAG: build the SPIR-V example (+dump), copy to g2bin/g2_spirv_TAG, dump W=64 full-mode SPIR-V (records on, and
# --noout), run ACO for GFX1201, print loop counts. Tuning session 2026-11-18.
set -e
W=/home/claude/projects/nice/.worktrees/g2-cubecl; cd $W; TAG=$1; shift
df -h / | tail -1
AV=$(df --output=avail -k / | tail -1); [ $AV -lt 5000000 ] && { echo "DISK under 5 GB: stop"; exit 9; }
export CARGO_TARGET_DIR=$W/target-g2
nice -n 19 cargo build --offline --release -j 2 -p nice_common --example g2_cubecl --features cubecl-spirv,cubecl/spirv-dump > g2out/tune/build_$TAG.log 2>&1 || { tail -40 g2out/tune/build_$TAG.log; exit 1; }
cp target-g2/release/examples/g2_cubecl g2bin/g2_spirv_$TAG
D=/home/claude/projects/nice/scratchpad/2026-10-research-program/G2/bench/su64_712012851
for v in full noout; do
  OUT=$W/g2out/tune/aco_${TAG}_$v; rm -rf $OUT; mkdir -p $OUT
  X=; [ $v = noout ] && X=--noout
  podman run --rm --cgroups=disabled -v $W:$W -v $D:$D -w $OUT -e CUBECL_DEBUG_SPIRV=$OUT -e VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/lvp_icd.json -e LP_NUM_THREADS=2 localhost/lvp26 $W/g2bin/g2_spirv_$TAG $D --jobs 0-0:0-0 --batch 252 --force-w 64 --fill 1024 --modes 2 --no-sets $X "$@" > $OUT/run.txt 2>&1 || true
  podman exec g2mesa bash $W/aco/aco.sh $OUT > /dev/null
  python3 -I aco/loops.py $OUT/G2Kernel*.aco.txt; [ $v = full ] && for k in $OUT/Hist*.aco.txt $OUT/Scatter*.aco.txt; do [ -f $k ] && python3 -I aco/loops.py $k | head -2; done
done
