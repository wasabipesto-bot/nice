#!/bin/bash
# chain_ab.sh W (round 2): A/B of the base S (87958fd, #249) against binary W (tree W), interleaved, nothing else on
# the box (waits for ab_go): 3 rounds of b62 1e17 (1 field), b62/b60/b64 1e16 (2 fields each), order alternating
# (S W, W S, S W); 3 rounds of the 1e14 set (b60/b62/b64, 3 fields each); NiceMark nice-only (150 s, 6 rounds,
# client_S / client_W, order alternating). Logs ab_{S,W}_*, nm_{S,W}_r*.
R=/root/l48/run.sh; L=/root/l48/logs; BIN=/root/l48/bin; W=$1
until [ -e $L/ab_go ]; do sleep 10; done
echo AB_START $(date -u +%T)
unset NICE_EXP_TOPFD
for r in 1 2 3; do
  if [ $r = 2 ]; then O="$W S"; else O="S $W"; fi
  for t in $O; do [ -e $L/stop ] && exit 0; SRCD=$t $R ab_${t}_e17_b62_r$r $t 62 1 1e17; done
  for f in "62 e16_b62" "60 e16_b60" "64 e16_b64"; do
    set -- $f
    for t in $O; do [ -e $L/stop ] && exit 0; SRCD=$t $R ab_${t}_$2_r$r $t $1 2 1e16; done
  done
  echo "AB round $r done $(date -u +%T)"
done
echo AB_FIELDS_DONE $(date -u +%T)
for r in 1 2 3; do
  if [ $r = 2 ]; then O="$W S"; else O="S $W"; fi
  for b in 60 62 64; do
    for t in $O; do [ -e $L/stop ] && exit 0; SRCD=$t $R ab_${t}_e14_b${b}_r$r $t $b 3 1e14; done
  done
done
echo AB_E14_DONE $(date -u +%T)
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH:-} NICE_API_BASE=http://127.0.0.1:9 NICE_BUILD_SHA=test
cd /root/l48
for r in 1 2 3 4 5 6; do
  if [ $((r % 2)) = 0 ]; then O="$W S"; else O="S $W"; fi
  for t in $O; do
    [ -e $L/stop ] && exit 0
    ( while true; do nvidia-smi --query-gpu=timestamp,clocks.sm,clocks.mem,power.draw,power.limit,temperature.gpu,utilization.gpu,clocks_throttle_reasons.active --format=csv,noheader; sleep 5; done ) > $L/nm_${t}_r$r.smi 2>&1 &
    SMI=$!
    echo "START nm_${t}_r$r $(date -u +%T) bin=client_$t md5=$(md5sum $BIN/client_$t | cut -c1-8)" > $L/nm_${t}_r$r.err
    $BIN/client_$t niceonly --gpu --benchmark --benchmark-secs 150 --benchmark-json < /dev/null > $L/nm_${t}_r$r.json 2>> $L/nm_${t}_r$r.err
    echo "END nm_${t}_r$r $(date -u +%T) rc=$?" >> $L/nm_${t}_r$r.err
    kill $SMI
  done
done
echo AB_DONE $(date -u +%T) | tee $L/ab.done
