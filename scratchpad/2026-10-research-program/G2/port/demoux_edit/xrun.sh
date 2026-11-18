#!/bin/sh
# exactness of the 2026-11-18 build on the card (sets, counts, prep order) and the prep on lavapipe (W = 8)
W=/home/justin/claude-exp-2026-11-18-g2; cd $W
export OUT=$W/out_b G2BIN=$W/bin/g2y W=$W
S1=$W/data/su64_712012851; S2=$W/data/su64_391856203
sh scripts/run_g2.sh x_A_su1 $S1 --gpu-prep --xpose 1 --ept 2 --reps 1
sh scripts/run_g2.sh x_A_su2 $S2 --gpu-prep --xpose 1 --ept 2 --reps 1
sh scripts/run_g2.sh x_D_su1 $S1 --gpu-prep --xpose 1 --ept 2 --tdig 1 --reps 1
sh scripts/run_g2.sh x_D_su2 $S2 --gpu-prep --xpose 1 --ept 2 --tdig 1 --reps 1
sh scripts/run_g2.sh x_Dpipe_su2 $S2 --gpu-prep --no-sets --modes 0 --reps 20 --xpose 1 --ept 2 --tdig 1 --warm 2 --pipe 200 --pipe-parts
VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/lvp_icd.x86_64.json G2JOBS=0-1:0-63 G2BATCH=252 sh scripts/run_g2.sh x_lvp_su1 $S1 --gpu-prep --reps 1 --modes 2
echo XRUN_DONE
