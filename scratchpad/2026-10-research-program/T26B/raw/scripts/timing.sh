#!/bin/bash
# timing.sh: main (RT/MC) against the fix (FT/FC) on the 3080, interleaved, card cooled before every run, nothing else
# on the box. Stride harness: b54 at 2778136280153679229, 40 fields of 1e13 (NICE_JOIN_ROUTE=stride), rounds 1-3
# (M F / F M / M F). NiceMark (nice-only, stride forced, 60 s budget): rounds 1-4 (M F / F M / M F / F M).
W=/root/t26b; S=$W/scripts; O=$W/out/timing.out
echo "TIMING START $(date -u +%T) builds running: $(pgrep -c cargo)" >> $O
run_s() { bash $S/cool.sh >> $O; bash $S/run_s.sh $1 $2 54 2778136280153679229 10000000000000 40 >> $O; }
run_n() { bash $S/cool.sh >> $O; bash $S/run_nm.sh $1 $2 60 >> $O; }
run_s s54_M_r1 RT; run_s s54_F_r1 FT
run_s s54_F_r2 FT; run_s s54_M_r2 RT
run_s s54_M_r3 RT; run_s s54_F_r3 FT
run_n nm_M_r1 MC; run_n nm_F_r1 FC
run_n nm_F_r2 FC; run_n nm_M_r2 MC
run_n nm_M_r3 MC; run_n nm_F_r3 FC
run_n nm_F_r4 FC; run_n nm_M_r4 MC
echo "TIMING DONE $(date -u +%T)" >> $O
