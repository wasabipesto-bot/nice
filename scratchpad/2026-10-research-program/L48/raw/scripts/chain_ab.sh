#!/bin/bash
# chain_ab.sh W LV [SRCW]: A/B of the base B (f3fb390) against binary W at NICE_EXP_TOPFD=LV, interleaved, nothing else on
# the box (waits for ab_go): 3 rounds of b62 1e17 (1 field), b62/b60/b64 1e16 (2 fields each), order alternating
# (B W, W B, B W); 3 rounds of the 1e14 set (b60/b62/b64, 3 fields each); NiceMark nice-only (150 s, 6 rounds,
# client_B / client_W, order alternating).
R=/root/l48/run.sh; L=/root/l48/logs; BIN=/root/l48/bin; W=$1; LV=$2; SW=${3:-X}; A=${PFX:-ab}; N=nm${A#ab}
until [ -e $L/ab_go ]; do sleep 10; done
echo AB_START $(date -u +%T)
run_side() { # side name args...
  local t=$1; shift
  if [ $t = B ]; then SRCD=B NICE_EXP_TOPFD=0 $R "$@"; else SRCD=$SW NICE_EXP_TOPFD=$LV $R "$@"; fi
}
for r in 1 2 3; do
  if [ $r = 2 ]; then O="$W B"; else O="B $W"; fi
  for t in $O; do [ -e $L/stop ] && exit 0; if [ $t = B ]; then run_side B ${A}_B_e17_b62_r$r B 62 1 1e17; else run_side W ${A}_${W}_e17_b62_r$r $W 62 1 1e17; fi; done
  for f in "62 e16_b62" "60 e16_b60" "64 e16_b64"; do
    set -- $f
    for t in $O; do [ -e $L/stop ] && exit 0; if [ $t = B ]; then run_side B ${A}_B_$2_r$r B $1 2 1e16; else run_side W ${A}_${W}_$2_r$r $W $1 2 1e16; fi; done
  done
  echo "AB round $r done $(date -u +%T)"
done
echo AB_FIELDS_DONE $(date -u +%T)
for r in 1 2 3; do
  if [ $r = 2 ]; then O="$W B"; else O="B $W"; fi
  for b in 60 62 64; do
    for t in $O; do [ -e $L/stop ] && exit 0; if [ $t = B ]; then run_side B ${A}_B_e14_b${b}_r$r B $b 3 1e14; else run_side W ${A}_${W}_e14_b${b}_r$r $W $b 3 1e14; fi; done
  done
done
echo AB_E14_DONE $(date -u +%T)
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH:-} NICE_API_BASE=http://127.0.0.1:9 NICE_BUILD_SHA=test
cd /root/l48
for r in 1 2 3 4 5 6; do
  if [ $((r % 2)) = 0 ]; then O="$W B"; else O="B $W"; fi
  for t in $O; do
    [ -e $L/stop ] && exit 0
    if [ $t = B ]; then export NICE_EXP_TOPFD=0; else export NICE_EXP_TOPFD=$LV; fi
    ( while true; do nvidia-smi --query-gpu=timestamp,clocks.sm,clocks.mem,power.draw,power.limit,temperature.gpu,utilization.gpu,clocks_throttle_reasons.active --format=csv,noheader; sleep 5; done ) > $L/${N}_${t}_r$r.smi 2>&1 &
    SMI=$!
    echo "START ${N}_${t}_r$r $(date -u +%T) bin=client_$t md5=$(md5sum $BIN/client_$t | cut -c1-8) TOPFD=$NICE_EXP_TOPFD" > $L/${N}_${t}_r$r.err
    $BIN/client_$t niceonly --gpu --benchmark --benchmark-secs 150 --benchmark-json < /dev/null > $L/${N}_${t}_r$r.json 2>> $L/${N}_${t}_r$r.err
    echo "END ${N}_${t}_r$r $(date -u +%T) rc=$?" >> $L/${N}_${t}_r$r.err
    kill $SMI
  done
done
echo AB_DONE $(date -u +%T) | tee $L/${A}.done
