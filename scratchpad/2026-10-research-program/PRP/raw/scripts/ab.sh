#!/bin/bash
# ab.sh: the timed A/B on CUDA. Three rounds; per round each field runs M, S and F back to back, the order rotating
# between rounds (M S F, S F M, F M S). Nothing else runs on the box (no builds, no tests). A file $W/stop ends it.
# Fields: b62 1e17 at 0.45, b60 1e16 at 0.55, b64 1e17 at 0.55, b64 1e16 x 2 (consecutive, from 0.55).
W=/root/prp; R=$W/scripts/run.sh
F60=1447429612114824200908; F62=7520566762397899821056; F64=58557331862957161709568
echo AB_START $(date -u +%T)
for r in ${ROUNDS:-1 2 3}; do
  case $r in 1) O="M S F";; 2) O="S F M";; *) O="F M S";; esac
  for f in "b62 62 1 1e17 $F62" "b60 60 1 1e16 $F60" "b64e17 64 1 1e17 $F64" "b64e16 64 2 1e16 $F64"; do
    set -- $f
    for t in $O; do
      [ -e $W/stop ] && { echo stopped; exit 0; }
      bash $R ab_${t}_$1_r$r $t $2 $3 $4 $5
    done
  done
done
echo AB_DONE $(date -u +%T)
