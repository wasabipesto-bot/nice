#!/bin/bash
# nm.sh: NiceMark nice-only (150 s budget), four rounds, M, S and F per round, order rotating; nothing else on the box.
W=/root/prp; B=$W/bin; L=$W/logs/nm; mkdir -p $L
export NICE_BUILD_SHA=test
echo NM_START $(date -u +%T)
for r in ${ROUNDS:-1 2 3 4}; do
  case $r in 1) O="M S F";; 2) O="S F M";; 3) O="F M S";; *) O="M F S";; esac
  for t in $O; do
    [ -e $W/stop ] && { echo stopped; exit 0; }
    N=nm_${t}_r$r
    t0=$(date +%s); while [ $(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits) -gt ${COOL_C:-50} ] && [ $(( $(date +%s) - t0 )) -lt 240 ]; do sleep 3; done
    TSTART="cooled $(( $(date +%s) - t0 ))s to $(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits)C"
    ( while true; do nvidia-smi --query-gpu=timestamp,clocks.sm,clocks.mem,power.draw,power.limit,temperature.gpu,utilization.gpu,clocks_throttle_reasons.active --format=csv,noheader; sleep 2; done ) > $L/$N.smi 2>&1 &
    SMI=$!
    echo "START $N $(date -u +%T) md5=$(md5sum $B/client_$t | cut -c1-8) $TSTART" > $L/$N.err
    $B/client_$t niceonly --gpu --benchmark --benchmark-secs 150 --benchmark-json < /dev/null > $L/$N.json 2>> $L/$N.err
    echo "END $N $(date -u +%T) rc=$?" >> $L/$N.err
    kill $SMI
    echo "$(date -u +%T) $N $(python3 -c "import json,sys; d=json.load(open('$L/$N.json')); print(d.get('score'), [(s.get('key'), s.get('rate')) for s in d.get('scenarios',[])])" 2>&1 | tail -1)"
  done
done
echo NM_DONE $(date -u +%T)
