#!/bin/bash
# chain.sh: the speed A/B, three rounds, binaries rotated per round (B = bc9d87c7 the PR head, F = the fix, M = upstream
# main a7a59c11); per round b62 1e17 (1 field), b64 1e17 (1 field), b60 1e16 (2 fields), each run after cool.sh.
# Nothing else may run on the box meanwhile. $W/stop ends the chain before its next run.
W=/root/ckf; S=$W/scripts
F62=7520566762397899821056; F64=58557331862957161709568; F60=1447429612114824200908
echo "CHAIN_START $(date -u +%T)"
for r in 1 2 3; do
  case $r in 1) ORD="B F3 M";; 2) ORD="F3 M B";; 3) ORD="M B F3";; esac
  for f in "b62 62 1e17 $F62 1" "b64 64 1e17 $F64 1" "b60 60 1e16 $F60 2"; do
    set -- $f
    for b in $ORD; do
      [ -e $W/stop ] && { echo "stopped $(date -u +%T)"; exit 0; }
      bash $S/cool.sh 40
      bash $S/run.sh ${1}_${b}_r$r $b $2 $3 $4 $5
    done
  done
done
echo "CHAIN_DONE $(date -u +%T)"
