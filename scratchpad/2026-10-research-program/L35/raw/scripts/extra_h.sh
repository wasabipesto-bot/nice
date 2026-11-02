#!/bin/bash
# extra_h.sh: H, b62 1e17 rounds 2-3 (A = FD 0, B = FD 2).
R=/root/l35/run2.sh; L=/root/l35/logs
for r in 2 3; do NICE_EXP_TOP_FD=0 $R abh_A_e17_b62_r$r H 62 1 1e17; NICE_EXP_TOP_FD=2 $R abh_B_e17_b62_r$r H 62 1 1e17; done
echo EXTRA_H_DONE $(date -u +%T) > $L/extrah.done
