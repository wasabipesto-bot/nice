#!/bin/bash
# Gate screen (follow-up): H (fcd6581) G=4 with NICE_EXP_JOIN_TRANSPOSE_MIN = 192 and 256 (and 128 on the cheap fields)
# against the switch off, interleaved per round, 2 rounds, nothing else on the box. Then NiceMark (client_H) x2.
L=/root/l34/logs; S=/root/l34; R=$S/run.sh; BIN=/root/l34/bin
cfg() { if [ "$1" = off ]; then echo ""; else echo "NICE_EXP_JOIN_TRANSPOSE=1 NICE_EXP_JOIN_TRANSPOSE_G=4 NICE_EXP_JOIN_TRANSPOSE_MIN=${1#m}"; fi; }
echo MIN_START $(date -u +%T) > $L/min.start
for r in 1 2; do
  for c in off m192 m256; do env $(cfg $c) $R mn_${c}_e17_b62_r$r H 62 1 1e17; done
  for c in off m128 m192 m256; do env $(cfg $c) $R mn_${c}_e16_b62_r$r H 62 2 1e16; done
  for c in off m192 m256; do env $(cfg $c) $R mn_${c}_e16_b60_r$r H 60 2 1e16; done
  for c in off m192 m256; do env $(cfg $c) $R mn_${c}_e16_b64_r$r H 64 2 1e16; done
  for c in off m128 m192 m256; do env $(cfg $c) $R mn_${c}_e14_r$r H 60,62,64 3 1e14; done
done
echo MIN_AB_DONE $(date -u +%T) > $L/minab.done
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH:-} NICE_API_BASE=http://127.0.0.1:9
cd /root/l34
for r in 1 2; do
  for c in off m128 m192 m256; do
    ( while true; do nvidia-smi --query-gpu=timestamp,clocks.sm,clocks.mem,power.draw,power.limit,temperature.gpu,utilization.gpu,clocks_throttle_reasons.active --format=csv,noheader; sleep 5; done ) > $L/mnm_${c}_r$r.smi 2>&1 &
    SMI=$!
    echo "START mnm_${c}_r$r $(date -u +%T) cfg=[$(cfg $c)] md5=$(md5sum $BIN/client_H | cut -c1-8)" > $L/mnm_${c}_r$r.err
    env $(cfg $c) $BIN/client_H niceonly --gpu --benchmark --benchmark-secs 150 --benchmark-json < /dev/null > $L/mnm_${c}_r$r.json 2>> $L/mnm_${c}_r$r.err
    echo "END mnm_${c}_r$r $(date -u +%T) rc=$?" >> $L/mnm_${c}_r$r.err
    kill $SMI
  done
done
echo MIN_DONE $(date -u +%T) > $L/min.done
