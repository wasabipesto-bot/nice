#!/bin/bash
# A/B on one binary F: A = NICE_EXP_TOP_FD=0, B = NICE_EXP_TOP_FD=2; interleaved A B per round; nothing else on the box.
R=/root/l35/run2.sh; L=/root/l35/logs; BIN=/root/l35/bin
until [ -e $L/cudax.done ] && [ -e $L/lvp.done ]; do sleep 10; done
echo AB_START $(date -u +%T) > $L/ab.start
# the base binary against F with FD=0 (no regression from the refactor), one b62 1e16 run each
SRCD=A NICE_EXP_TOP_FD=0 $R base_e16_b62 A 62 2 1e16
NICE_EXP_TOP_FD=0 $R F0_e16_b62 F 62 2 1e16
for r in 1 2 3; do NICE_EXP_TOP_FD=0 $R ab_A_e17_b62_r$r F 62 1 1e17; NICE_EXP_TOP_FD=2 $R ab_B_e17_b62_r$r F 62 1 1e17; done
for r in 1 2 3; do NICE_EXP_TOP_FD=0 $R ab_A_e16_b62_r$r F 62 2 1e16; NICE_EXP_TOP_FD=2 $R ab_B_e16_b62_r$r F 62 2 1e16; done
for r in 1 2 3; do NICE_EXP_TOP_FD=0 $R ab_A_e16_b60_r$r F 60 2 1e16; NICE_EXP_TOP_FD=2 $R ab_B_e16_b60_r$r F 60 2 1e16; done
for r in 1 2 3; do NICE_EXP_TOP_FD=0 $R ab_A_e16_b64_r$r F 64 2 1e16; NICE_EXP_TOP_FD=2 $R ab_B_e16_b64_r$r F 64 2 1e16; done
echo CHAIN_AB_DONE $(date -u +%T) > $L/chainAB.done
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH:-}
export NICE_API_BASE=http://127.0.0.1:9
cd /root/l35
for r in 1 2 3; do
  for s in A B; do
    if [ $s = A ]; then FD=0; else FD=2; fi
    ( while true; do nvidia-smi --query-gpu=timestamp,clocks.sm,clocks.mem,power.draw,power.limit,temperature.gpu,utilization.gpu,clocks_throttle_reasons.active --format=csv,noheader; sleep 5; done ) > $L/nm_${s}_r$r.smi 2>&1 &
    SMI=$!
    echo "START nm_${s}_r$r $(date -u +%T) md5=$(md5sum $BIN/client_F | cut -c1-8) NICE_EXP_TOP_FD=$FD" > $L/nm_${s}_r$r.err
    NICE_EXP_TOP_FD=$FD $BIN/client_F niceonly --gpu --benchmark --benchmark-secs 150 --benchmark-json < /dev/null > $L/nm_${s}_r$r.json 2>> $L/nm_${s}_r$r.err
    echo "END nm_${s}_r$r $(date -u +%T) rc=$?" >> $L/nm_${s}_r$r.err
    kill $SMI
  done
done
echo CHAIN_NM_DONE $(date -u +%T) > $L/chainNM.done
