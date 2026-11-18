#!/bin/sh
# window_1118d part 2: the multi path with inputs uploaded once (--no-upload), 16 distinct and 1 x 16, D; then
# with uploads again (same build), to bracket
W=/home/justin/claude-exp-2026-11-18-g2; cd $W
export OUT=$W/out_d W=$W G2BIN=$W/bin/g2n
S=$W/scripts; VD="--xpose 1 --ept 2 --tdig 1"
echo "MEAS2_START $(date -u +%T) g2n=$(md5sum $G2BIN | cut -c1-8)"
sh $S/run_g2.sh nu16_D_r1 $W/data16 --multi $W/list16.txt $VD --warm 5 --cycles 360 --no-upload
sh $S/run_g2.sh nu1x16_D_r1 $W/data16 --multi $W/list1x16.txt $VD --warm 5 --cycles 360 --no-upload
sh $S/run_g2.sh mu16_D_r3 $W/data16 --multi $W/list16.txt $VD --warm 5 --cycles 360
sh $S/run_g2.sh nu16_D_r2 $W/data16 --multi $W/list16.txt $VD --warm 5 --cycles 360 --no-upload
echo "MEAS2_DONE $(date -u +%T)"
