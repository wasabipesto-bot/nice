#!/bin/bash
# timing5.sh: NiceMark rounds 5 (M F) and 6 (F M), as in timing.sh, for the b58 msd-strong scenario's spread.
W=/root/t26b; S=$W/scripts; O=$W/out/timing.out
echo "TIMING5 START $(date -u +%T) builds running: $(pgrep -c cargo)" >> $O
run_n() { bash $S/cool.sh >> $O; bash $S/run_nm.sh $1 $2 60 >> $O; }
run_n nm_M_r5 MC; run_n nm_F_r5 FC
run_n nm_F_r6 FC; run_n nm_M_r6 MC
echo "TIMING5 DONE $(date -u +%T)" >> $O
