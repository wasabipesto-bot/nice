#!/bin/bash
# chain_q4.sh: after chain_q3: exactness of H1's variant 2 (C, COMPACT=2), a third A/B round of C0 vs C2 at the four
# fields, the 1e14 set (b57/60/62/64, 1 field each, 3 interleaved rounds), and a third NiceMark round of C0 vs C2.
R=/root/l37/run.sh; L=/root/l37/logs; BIN=/root/l37/bin
until [ -e $L/q3.done ]; do sleep 10; done
echo Q4_START $(date -u +%T)
unset NICE_EXP_GPU_PROFILE NICE_EXP_JOIN_ABL NICE_EXP_JOIN_TMIN NICE_EXP_JOIN_SHFL
/root/l37/chain_x.sh C C NICE_EXP_JOIN_COMPACT 2 C2 > $L/chain_x_C2.out 2>&1
unset NICE_EXP_JOIN_COMPACT
r=3
for c in 0 2; do NICE_EXP_JOIN_COMPACT=$c SRCD=C $R ab1_C${c}_e17_b62_r$r C 62 1 1e17; done
for f in "60 e16_b60" "62 e16_b62" "64 e16_b64"; do
  set -- $f
  for c in 0 2; do NICE_EXP_JOIN_COMPACT=$c SRCD=C $R ab1_C${c}_$2_r$r C $1 2 1e16; done
done
for r in 1 2 3; do
  for b in 57 60 62 64; do
    for c in 0 2; do NICE_EXP_JOIN_COMPACT=$c SRCD=C $R ab1_C${c}_e14_b${b}_r$r C $b 1 1e14; done
  done
done
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH:-} NICE_API_BASE=http://127.0.0.1:9 NICE_BUILD_SHA=test
cd /root/l37
r=3
for c in 0 2; do
  ( while true; do nvidia-smi --query-gpu=timestamp,clocks.sm,clocks.mem,power.draw,power.limit,temperature.gpu,utilization.gpu,clocks_throttle_reasons.active --format=csv,noheader; sleep 5; done ) > $L/nm1_C${c}_r$r.smi 2>&1 &
  SMI=$!
  echo "START nm1_C${c}_r$r $(date -u +%T) bin=client_C md5=$(md5sum $BIN/client_C | cut -c1-8) COMPACT=$c" > $L/nm1_C${c}_r$r.err
  NICE_EXP_JOIN_COMPACT=$c $BIN/client_C niceonly --gpu --benchmark --benchmark-secs 150 --benchmark-json < /dev/null > $L/nm1_C${c}_r$r.json 2>> $L/nm1_C${c}_r$r.err
  echo "END nm1_C${c}_r$r $(date -u +%T) rc=$?" >> $L/nm1_C${c}_r$r.err
  kill $SMI
done
echo Q4_DONE $(date -u +%T) > $L/q4.done
