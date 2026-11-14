#!/bin/bash
# chain2.sh: extra b62 1e17 rounds of the A/B (round 2's F ran 2 % slower than its M; more rounds and the register
# variants decide). Rounds 4 (F M) and 5 (M F); same protocol as chain.sh.
W=/root/t26; S=$W/scripts; F62=7520566762397899821056
echo "CHAIN2_START $(date -u +%T) M=$(md5sum $W/bin/M | cut -c1-8) F=$(md5sum $W/bin/F | cut -c1-8)"
for r in 4 5; do
  case $r in 4) ORD="F M";; 5) ORD="M F";; esac
  for b in $ORD; do
    [ -e $W/stop ] && { echo "stopped $(date -u +%T)"; exit 0; }
    bash $S/cool.sh 42
    bash $S/run.sh b62_${b}_r$r $b 62 1e17 $F62 1
  done
done
echo "CHAIN2_DONE $(date -u +%T)"
