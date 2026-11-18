#!/bin/bash
# ex.sh TAG [extra args]: exactness of g2bin/g2_spirv_TAG on lavapipe 26.0.8, whole super-units, two at a time:
# W=8 + GPU prep on both super-units (defaults), W=16 (512-bit) + host prep + --cmask 0 on both super-units
# (W=16 with GPU prep or cmask 1 crashes lavapipe's 512-bit JIT, PORT-NOTES). -> g2out/tune/ex_TAG/*.txt
W=/home/claude/projects/nice/.worktrees/g2-cubecl; TAG=$1; shift; B=$W/g2bin/g2_spirv_$TAG
G=/home/claude/projects/nice/scratchpad/2026-10-research-program/G2/bench; O=$W/g2out/tune/ex_$TAG; mkdir -p $O
run() { # name su vecwidth args...
  local n=$1 su=$2 vw=$3; shift 3; local D=$G/su64_$su
  podman run --rm --cgroups=disabled -v $W:$W -v $D:$D -w $O -e VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/lvp_icd.json -e LP_NUM_THREADS=2 -e LP_NATIVE_VECTOR_WIDTH=$vw localhost/lvp26 $B $D --jobs all --batch 252 "$@" > $O/$n.txt 2>&1
  echo "$n: $(grep -c 'EQUAL' $O/$n.txt) EQUAL, $(grep -o 'errors: plane [0-9]* pmax [0-9]* slab [0-9]*' $O/$n.txt | sort -u | tr '\n' ';') $(tail -1 $O/$n.txt)"
}
run S8_su1 712012851 256 --gpu-prep "$@" & run S8_su2 391856203 256 --gpu-prep "$@" & wait
run S16_su1_cm0 712012851 512 --cmask 0 "$@" & run S16_su2_cm0 391856203 512 --cmask 0 "$@" & wait
# 16-chunk rounds (fill 1024, the W >= 32 setting) fit lavapipe's 32 KB since b7d6af65
run S8_su1_f1024 712012851 256 --gpu-prep --fill 1024 "$@" & run S8_su2_f1024 391856203 256 --gpu-prep --fill 1024 "$@" & wait
run S16_su1_cm0_f1024 712012851 512 --cmask 0 --fill 1024 "$@" & run S8_su1_xp0_f1024 712012851 256 --gpu-prep --xpose 0 --fill 1024 "$@" & wait
# W=16 with cmask 1 runs on lavapipe since c11 (32-bit transpose); W=16 with GPU prep still crashes its 512-bit JIT
run S16_su1_cm1_f1024 712012851 512 --fill 1024 "$@" & run S16_su2_cm1_f1024 391856203 512 --fill 1024 "$@" & wait
