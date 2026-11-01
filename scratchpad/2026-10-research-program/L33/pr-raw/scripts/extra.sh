#!/bin/bash
# After NiceMark (quiet box): two more b62 1e17 rounds, A then B2, because rounds 1-2 differed by 3 %.
L=/root/l33p/logs; R=/root/l33p/run.sh
until [ -e $L/chainNM.done ]; do sleep 10; done
for r in 4 5; do $R ab_A_e17_b62_r$r A 62 1 1e17; $R ab_B_e17_b62_r$r B2 62 1 1e17; done
echo EXTRA_DONE $(date -u +%T) > $L/extra.done
