#!/bin/bash
# extra.sh: after post2.sh: b62 1e17 rounds 4-5 (A = FD 0, B = FD 2), as L33's extra.sh.
R=/root/l35/run2.sh; L=/root/l35/logs
until [ -e $L/post2.done ]; do sleep 10; done
for r in 4 5; do NICE_EXP_TOP_FD=0 $R ab_A_e17_b62_r$r F 62 1 1e17; NICE_EXP_TOP_FD=2 $R ab_B_e17_b62_r$r F 62 1 1e17; done
echo EXTRA_DONE $(date -u +%T) > $L/extra.done
