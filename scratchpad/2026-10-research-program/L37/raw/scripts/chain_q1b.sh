#!/bin/bash
# chain_q1.sh: after the ablation rounds: H2 sanity/registers and screen, the stage-check cadence screen (A2, profiled),
# then the H1 A/B (C, NICE_EXP_JOIN_COMPACT 0/1/2
# interleaved, 2 rounds: b62 1e17, b60 1e16, b62 1e16, b64 1e16), then NiceMark (client_C) per setting.
R=/root/l37/run.sh; L=/root/l37/logs; BIN=/root/l37/bin
until [ -e $L/abl.done ] && [ -e /root/l37/bin/S ]; do sleep 10; done
echo Q1_START $(date -u +%T)
unset NICE_EXP_GPU_PROFILE NICE_EXP_JOIN_ABL NICE_EXP_JOIN_TMIN NICE_EXP_JOIN_COMPACT NICE_EXP_JOIN_SHFL
/root/l37/regs.sh S S S NICE_EXP_JOIN_SHFL 0 1 > $L/regs_S.out 2>&1
for s in 0 1; do NICE_EXP_JOIN_SHFL=$s SRCD=S $R scr_S${s}_e16_b62 S 62 2 1e16; done
export NICE_EXP_GPU_PROFILE=1
for s in 0 1; do NICE_EXP_JOIN_ABL=1 NICE_EXP_JOIN_SHFL=$s SRCD=S $R scrabl_S${s}_e16_b62 S 62 2 1e16; done
unset NICE_EXP_GPU_PROFILE
echo H2_SCREEN_DONE $(date -u +%T) > $L/h2screen.done
until [ -e $L/A2.built ]; do sleep 10; done
/root/l37/regs.sh A2 A2 A2 NICE_EXP_JOIN_ABL 0 5 7 8 > $L/regs_A2.out 2>&1
export NICE_EXP_GPU_PROFILE=1
for m in 0 4 5 7 8; do NICE_EXP_JOIN_ABL=$m SRCD=A2 $R scrbar_A2m${m}_e16_b62 A2 62 2 1e16; done
unset NICE_EXP_GPU_PROFILE NICE_EXP_JOIN_ABL
echo BAR_SCREEN_DONE $(date -u +%T) > $L/barscreen.done
for r in 1 2; do
  for c in 0 1 2; do NICE_EXP_JOIN_COMPACT=$c SRCD=C $R ab1_C${c}_e17_b62_r$r C 62 1 1e17; done
  for f in "60 e16_b60" "62 e16_b62" "64 e16_b64"; do
    set -- $f
    for c in 0 1 2; do NICE_EXP_JOIN_COMPACT=$c SRCD=C $R ab1_C${c}_$2_r$r C $1 2 1e16; done
  done
done
echo H1_AB_FIELDS_DONE $(date -u +%T) > $L/h1abf.done
until [ -e $L/clients.built ]; do sleep 10; done
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH:-} NICE_API_BASE=http://127.0.0.1:9 NICE_BUILD_SHA=test
cd /root/l37
for r in 1 2; do
  for c in 0 1 2; do
    ( while true; do nvidia-smi --query-gpu=timestamp,clocks.sm,clocks.mem,power.draw,power.limit,temperature.gpu,utilization.gpu,clocks_throttle_reasons.active --format=csv,noheader; sleep 5; done ) > $L/nm1_C${c}_r$r.smi 2>&1 &
    SMI=$!
    echo "START nm1_C${c}_r$r $(date -u +%T) bin=client_C md5=$(md5sum $BIN/client_C | cut -c1-8) COMPACT=$c" > $L/nm1_C${c}_r$r.err
    NICE_EXP_JOIN_COMPACT=$c $BIN/client_C niceonly --gpu --benchmark --benchmark-secs 150 --benchmark-json < /dev/null > $L/nm1_C${c}_r$r.json 2>> $L/nm1_C${c}_r$r.err
    echo "END nm1_C${c}_r$r $(date -u +%T) rc=$?" >> $L/nm1_C${c}_r$r.err
    kill $SMI
  done
done
echo Q1_DONE $(date -u +%T) > $L/q1.done
