#!/bin/bash
# timing4.sh: two more rounds of timing2 (plane-scoped queue, the fix's scan form forced vs main), Fs M / M Fs.
W=/root/t26b; S=$W/scripts; O=$W/out/timing2.out
echo "TIMING4 START $(date -u +%T) builds running: $(pgrep -c cargo)" >> $O
run_s() { bash $S/cool.sh >> $O; env $3 bash $S/run_s.sh $1 $2 54 2778136280153679229 10000000000000 40 >> $O; }
run_s s54scan_Fs_r4 FT2 NICE_TEST_QUEUE_FORM=scan; run_s s54scan_M_r4 RT X=0
run_s s54scan_M_r5 RT X=0; run_s s54scan_Fs_r5 FT2 NICE_TEST_QUEUE_FORM=scan
echo "TIMING4 DONE $(date -u +%T)" >> $O
