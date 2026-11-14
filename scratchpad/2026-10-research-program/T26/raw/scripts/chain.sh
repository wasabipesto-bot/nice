#!/bin/bash
# chain.sh: the speed A/B of the fix (F) against upstream main (M), three rounds, order rotated per round; per round
# b62 1e17 (1 field) and b64 1e17 (1 field), each run after cool.sh (<= 40 C). Nothing else may run on the box meanwhile
# (the caller holds the box lock). $W/stop ends the chain before its next run.
W=/root/t26; S=$W/scripts
F62=7520566762397899821056; F64=58557331862957161709568
echo "CHAIN_START $(date -u +%T) M=$(md5sum $W/bin/M | cut -c1-8) F=$(md5sum $W/bin/F | cut -c1-8)"
for r in ${ROUNDS:-1 2 3}; do
  case $r in 1) ORD="M F";; 2) ORD="F M";; 3) ORD="M F";; *) ORD="F M";; esac
  for f in "b62 62 1e17 $F62 1" "b64 64 1e17 $F64 1"; do
    set -- $f
    for b in $ORD; do
      [ -e $W/stop ] && { echo "stopped $(date -u +%T)"; exit 0; }
      bash $S/cool.sh 42
      bash $S/run.sh ${1}_${b}_r$r $b $2 $3 $4 $5
    done
  done
done
echo "CHAIN_DONE $(date -u +%T)"
