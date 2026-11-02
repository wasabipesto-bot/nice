#!/bin/bash
# chain_ab.sh G: A/B of one binary (F), switch off (A side) vs NICE_EXP_JOIN_TRANSPOSE=1 G (B side), interleaved
# off/on per round, nothing else on the box. Then NiceMark off/on x3 with client_F.
G=${1:-8}
R=/root/l34/run.sh; L=/root/l34/logs; BIN=/root/l34/bin
on() { NICE_EXP_JOIN_TRANSPOSE=1 NICE_EXP_JOIN_TRANSPOSE_G=$G "$@"; }
echo AB_START $(date -u +%T) G=$G > $L/ab.start
for r in 1 2 3; do $R ab_off_e17_b62_r$r F 62 1 1e17; on $R ab_on_e17_b62_r$r F 62 1 1e17; done
for r in 1 2 3; do $R ab_off_e16_b62_r$r F 62 2 1e16; on $R ab_on_e16_b62_r$r F 62 2 1e16; done
for r in 1 2 3; do $R ab_off_e16_b60_r$r F 60 2 1e16; on $R ab_on_e16_b60_r$r F 60 2 1e16; done
for r in 1 2 3; do $R ab_off_e16_b64_r$r F 64 2 1e16; on $R ab_on_e16_b64_r$r F 64 2 1e16; done
echo CHAIN_AB_DONE $(date -u +%T) > $L/chainAB.done
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH:-}
export NICE_API_BASE=http://127.0.0.1:9
cd /root/l34
for r in 1 2 3; do
  for s in off on; do
    ( while true; do nvidia-smi --query-gpu=timestamp,clocks.sm,clocks.mem,power.draw,power.limit,temperature.gpu,utilization.gpu,clocks_throttle_reasons.active --format=csv,noheader; sleep 5; done ) > $L/nm_${s}_r$r.smi 2>&1 &
    SMI=$!
    if [ $s = on ]; then export NICE_EXP_JOIN_TRANSPOSE=1 NICE_EXP_JOIN_TRANSPOSE_G=$G; else unset NICE_EXP_JOIN_TRANSPOSE NICE_EXP_JOIN_TRANSPOSE_G; fi
    echo "START nm_${s}_r$r $(date -u +%T) T=${NICE_EXP_JOIN_TRANSPOSE:-unset} G=${NICE_EXP_JOIN_TRANSPOSE_G:-unset} md5=$(md5sum $BIN/client_F | cut -c1-8)" > $L/nm_${s}_r$r.err
    $BIN/client_F niceonly --gpu --benchmark --benchmark-secs 150 --benchmark-json < /dev/null > $L/nm_${s}_r$r.json 2>> $L/nm_${s}_r$r.err
    echo "END nm_${s}_r$r $(date -u +%T) rc=$?" >> $L/nm_${s}_r$r.err
    kill $SMI
  done
done
unset NICE_EXP_JOIN_TRANSPOSE NICE_EXP_JOIN_TRANSPOSE_G
echo CHAIN_NM_DONE $(date -u +%T) > $L/chainNM.done
