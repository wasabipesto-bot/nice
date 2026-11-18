#!/bin/sh
# window_1118d: distinct super-units. main f6; then D over 16 distinct units (mu16), the same unit 16x through the
# same multi path (mu1x16: uploads, same data), the same-unit pipe of the morning (pp, g2z); A once; D repeated.
W=/home/justin/claude-exp-2026-11-18-g2; cd $W
export OUT=$W/out_d W=$W
mkdir -p $OUT
S=$W/scripts; S1=$W/data/su64_712012851
VD="--xpose 1 --ept 2 --tdig 1"; VA="--xpose 1 --ept 2"
ok() { [ -e "$W/stop" ] && { echo "stopped by $W/stop"; exit 0; }; [ "$(date -u +%H%M)" -ge 1545 ] && { echo "stopped at 15:45"; exit 0; }; }
echo "MEAS_START $(date -u +%T) g2m=$(md5sum $W/bin/g2m | cut -c1-8) g2z=$(md5sum $W/bin/g2z | cut -c1-8) main=$(md5sum $W/bin/main | cut -c1-8)"
ok; sh $S/run_main.sh main_f6 58557331862957161709568
ok; G2BIN=$W/bin/g2m sh $S/run_g2.sh mu16_D_r1 $W/data16 --multi $W/list16.txt $VD --warm 5 --cycles 360
ok; G2BIN=$W/bin/g2m sh $S/run_g2.sh mu1x16_D_r1 $W/data16 --multi $W/list1x16.txt $VD --warm 5 --cycles 360
ok; G2BIN=$W/bin/g2z sh $S/run_g2.sh pp_D_r1 $S1 --gpu-prep --no-sets --modes 0 --reps 20 $VD --warm 5 --pipe 6000
ok; G2BIN=$W/bin/g2m sh $S/run_g2.sh mu16_A_r1 $W/data16 --multi $W/list16.txt $VA --warm 5 --cycles 360
ok; G2BIN=$W/bin/g2m sh $S/run_g2.sh mu16_D_r2 $W/data16 --multi $W/list16.txt $VD --warm 5 --cycles 360
ok; G2BIN=$W/bin/g2z sh $S/run_g2.sh pp_D_r2 $S1 --gpu-prep --no-sets --modes 0 --reps 20 $VD --warm 5 --pipe 6000
ok; G2BIN=$W/bin/g2m sh $S/run_g2.sh mu1x16_D_r2 $W/data16 --multi $W/list1x16.txt $VD --warm 5 --cycles 360
echo "MEAS_DONE $(date -u +%T)"
