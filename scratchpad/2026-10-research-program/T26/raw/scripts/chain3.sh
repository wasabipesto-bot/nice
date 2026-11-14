#!/bin/bash
# chain3.sh: extra b64 1e17 rounds of the A/B (round 3 of b64 was 3.4 % apart, main fast). Rounds 4 (F M) and 5 (M F);
# same protocol as chain.sh.
W=/root/t26; S=$W/scripts; F64=58557331862957161709568
echo "CHAIN3_START $(date -u +%T) M=$(md5sum $W/bin/M | cut -c1-8) F=$(md5sum $W/bin/F | cut -c1-8)"
for r in 4 5; do
  case $r in 4) ORD="F M";; 5) ORD="M F";; esac
  for b in $ORD; do
    [ -e $W/stop ] && { echo "stopped $(date -u +%T)"; exit 0; }
    bash $S/cool.sh 42
    bash $S/run.sh b64_${b}_r$r $b 64 1e17 $F64 1
  done
done
echo "CHAIN3_DONE $(date -u +%T)"
