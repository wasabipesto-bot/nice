#!/bin/bash
# timing3.sh: the cube-scoped queue (the WGSL default) forced on CUDA with the production knob
# NICE_CUBECL_PLANE_COMPACT=0: main (RT) against the fix in its ballot form (FT2, CUDA's own choice) and in its scan
# form (FT2 + NICE_TEST_QUEUE_FORM=scan); b54 stride harness as in timing.sh; rounds M Fb Fs / Fb Fs M / Fs M Fb.
W=/root/t26b; S=$W/scripts; O=$W/out/timing3.out
echo "TIMING3 START $(date -u +%T) builds running: $(pgrep -c cargo)" >> $O
run_s() { bash $S/cool.sh >> $O; env NICE_CUBECL_PLANE_COMPACT=0 $3 bash $S/run_s.sh $1 $2 54 2778136280153679229 10000000000000 40 >> $O; }
run_s c54_M_r1 RT X=0; run_s c54_Fb_r1 FT2 NICE_TEST_QUEUE_FORM=ballot; run_s c54_Fs_r1 FT2 NICE_TEST_QUEUE_FORM=scan
run_s c54_Fb_r2 FT2 NICE_TEST_QUEUE_FORM=ballot; run_s c54_Fs_r2 FT2 NICE_TEST_QUEUE_FORM=scan; run_s c54_M_r2 RT X=0
run_s c54_Fs_r3 FT2 NICE_TEST_QUEUE_FORM=scan; run_s c54_M_r3 RT X=0; run_s c54_Fb_r3 FT2 NICE_TEST_QUEUE_FORM=ballot
echo "TIMING3 DONE $(date -u +%T)" >> $O
