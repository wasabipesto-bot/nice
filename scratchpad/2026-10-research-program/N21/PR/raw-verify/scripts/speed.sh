#!/bin/bash
# speed.sh: two interleaved pairs (M B, B M) at b62 1e17 (7520566762397899821056), card cooled to <= 40 C first.
W=/root/n21v; S=$W/scripts; F62=7520566762397899821056
for x in M:1 B:1 B:2 M:2; do b=${x%:*}; r=${x#*:}; bash $S/cool.sh 40; bash $S/run.sh b62_${b}_r$r $b 62 1e17 $F62 1; done
python3 $S/ptxjit.py $W/ptx/b62_* > $W/out/ptxjit.out 2>&1
echo SPEED_DONE
