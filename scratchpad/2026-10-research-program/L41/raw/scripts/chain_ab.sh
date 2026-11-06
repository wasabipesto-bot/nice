#!/bin/bash
# chain_ab.sh W [PF]: the A/B of the base (B) against binary W (with NICE_EXP_JOIN_PF=PF when given), interleaved,
# nothing else on the box: 3 rounds of b62 1e17 (1 field), b62/b60/b64 1e16 (2 fields each), the order alternating per
# round (B W, W B, B W); 3 rounds of the 1e14 set (b57/b60/b62/b64, 3 fields each); NiceMark nice-only (150 s, 6 rounds,
# client_B / client_W, alternating).
R=/root/l41/run.sh; L=/root/l41/logs; BIN=/root/l41/bin; W=$1; PF=${2:-}
envw() { if [ "$1" = B ] || [ -z "$PF" ]; then env -u NICE_EXP_JOIN_PF "${@:2}"; else env NICE_EXP_JOIN_PF=$PF "${@:2}"; fi; }
echo AB_START $(date -u +%T) W=$W PF=$PF
for r in 1 2 3; do
  if [ $r = 2 ]; then O="$W B"; else O="B $W"; fi
  for t in $O; do envw $t SRCD=$t $R ab_${t}_e17_b62_r$r $t 62 1 1e17; done
  for f in "62 e16_b62" "60 e16_b60" "64 e16_b64"; do
    set -- $f
    for t in $O; do envw $t SRCD=$t $R ab_${t}_$2_r$r $t $1 2 1e16; done
  done
done
echo AB_FIELDS_DONE $(date -u +%T)
for r in 1 2 3; do
  if [ $r = 2 ]; then O="$W B"; else O="B $W"; fi
  for b in 57 60 62 64; do
    for t in $O; do envw $t SRCD=$t $R ab_${t}_e14_b${b}_r$r $t $b 3 1e14; done
  done
done
echo AB_E14_DONE $(date -u +%T)
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH:-} NICE_API_BASE=http://127.0.0.1:9 NICE_BUILD_SHA=test
cd /root/l41
for r in 1 2 3 4 5 6; do
  if [ $((r % 2)) = 0 ]; then O="$W B"; else O="B $W"; fi
  for t in $O; do
    ( while true; do nvidia-smi --query-gpu=timestamp,clocks.sm,clocks.mem,power.draw,power.limit,temperature.gpu,utilization.gpu,clocks_throttle_reasons.active --format=csv,noheader; sleep 5; done ) > $L/nm_${t}_r$r.smi 2>&1 &
    SMI=$!
    echo "START nm_${t}_r$r $(date -u +%T) bin=client_$t md5=$(md5sum $BIN/client_$t | cut -c1-8) pf=$([ $t = B ] || echo $PF)" > $L/nm_${t}_r$r.err
    envw $t $BIN/client_$t niceonly --gpu --benchmark --benchmark-secs 150 --benchmark-json < /dev/null > $L/nm_${t}_r$r.json 2>> $L/nm_${t}_r$r.err
    echo "END nm_${t}_r$r $(date -u +%T) rc=$?" >> $L/nm_${t}_r$r.err
    kill $SMI
  done
done
echo AB_DONE $(date -u +%T) > $L/ab.done
