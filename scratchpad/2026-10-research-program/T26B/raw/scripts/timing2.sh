#!/bin/bash
# timing2.sh: the fix's scan form forced on CUDA (FT2 with NICE_TEST_QUEUE_FORM=scan) against main (RT), b54 stride
# harness as in timing.sh, rounds 1-3 (M Fs / Fs M / M Fs); nothing else on the box.
W=/root/t26b; S=$W/scripts; O=$W/out/timing2.out
echo "TIMING2 START $(date -u +%T) builds running: $(pgrep -c cargo)" >> $O
run_s() { bash $S/cool.sh >> $O; env $3 bash $S/run_s.sh $1 $2 54 2778136280153679229 10000000000000 40 >> $O; }
run_s s54scan_M_r1 RT X=0; run_s s54scan_Fs_r1 FT2 NICE_TEST_QUEUE_FORM=scan
run_s s54scan_Fs_r2 FT2 NICE_TEST_QUEUE_FORM=scan; run_s s54scan_M_r2 RT X=0
run_s s54scan_M_r3 RT X=0; run_s s54scan_Fs_r3 FT2 NICE_TEST_QUEUE_FORM=scan
echo "TIMING2 DONE $(date -u +%T)" >> $O
