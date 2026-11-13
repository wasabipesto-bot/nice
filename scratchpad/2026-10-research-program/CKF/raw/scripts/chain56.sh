#!/bin/bash
# chain4.sh: b62 1e17 round 4 (F3 B M), because b62_F3_r3's process compiled the join kernel's spill variant (40
# registers, ptxjit) and is excluded as L53 did; re-runs F3 up to twice more if it spills again.
W=/root/ckf; S=$W/scripts; F62=7520566762397899821056
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH:-}
for rb in F3:5 B:5 B:6 F3:6; do b=${rb%:*}; r=${rb#*:}; bash $S/cool.sh 40; bash $S/run.sh b62_${b}_r$r $b 62 1e17 $F62 1; done
python3 $S/ptxjit.py $W/ptx/b62_*_r[56] > $W/out/ptxjit56.out 2>&1
echo CHAIN56_DONE $(date -u +%T)
