#!/bin/bash
# After master: EPT 3 + tail once at b62 1e16 (exploratory), then the CUDA source dump (register counts).
L=/root/pad
until grep -q "ALL DONE" $L/master.out 2>/dev/null; do sleep 15; done
echo "EXTRA start $(date -u +%T)"
/root/run.sh ab_ept3tail_e16_b62_r1 pad 62 2 1e16 0 NICE_EXP_JOIN_EPT=3 NICE_EXP_JOIN_TAIL=1
/root/run.sh ab_tail_e16_b62_r4 pad 62 2 1e16 0 NICE_EXP_JOIN_TAIL=1
/root/run.sh ab_base_e16_b62_r4 base 62 2 1e16 0
/root/cudadump.sh
echo "EXTRA DONE $(date -u +%T)" > $L/extra.done
