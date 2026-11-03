#!/bin/bash
# chain_ab.sh: A/B, A = upstream main 04693ac (M), B = exp/join-all5 6ddab24 (S); interleaved A B per round;
# nothing else on the box. 3 rounds each: b62 1e17 (1 field), b62/b60/b64 1e16 (2 fields). Then NiceMark A B x3.
R=/root/l36/run.sh; L=/root/l36/logs; BIN=/root/l36/bin
until [ -e $L/cudax.done ] && [ -e $L/lvp.done ] && [ -e $L/clients.built ] && [ -e $L/go_ab ]; do sleep 10; done
unset NICE_EXP_GPU_PROFILE NICE_EXP_TOP_FD_ABL
echo AB_START $(date -u +%T) > $L/ab.start
for r in 1 2 3; do SRCD=M $R ab_A_e17_b62_r$r M 62 1 1e17; SRCD=S $R ab_B_e17_b62_r$r S 62 1 1e17; done
for f in "62 e16_b62" "60 e16_b60" "64 e16_b64"; do
  set -- $f
  for r in 1 2 3; do SRCD=M $R ab_A_$2_r$r M $1 2 1e16; SRCD=S $R ab_B_$2_r$r S $1 2 1e16; done
done
echo AB_FIELDS_DONE $(date -u +%T) > $L/abf.done
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH:-} NICE_API_BASE=http://127.0.0.1:9 NICE_BUILD_SHA=test
cd /root/l36
for r in 1 2 3; do
  for s in A B; do
    if [ $s = A ]; then C=client_M; else C=client_S; fi
    ( while true; do nvidia-smi --query-gpu=timestamp,clocks.sm,clocks.mem,power.draw,power.limit,temperature.gpu,utilization.gpu,clocks_throttle_reasons.active --format=csv,noheader; sleep 5; done ) > $L/nm_${s}_r$r.smi 2>&1 &
    SMI=$!
    echo "START nm_${s}_r$r $(date -u +%T) bin=$C md5=$(md5sum $BIN/$C | cut -c1-8)" > $L/nm_${s}_r$r.err
    $BIN/$C niceonly --gpu --benchmark --benchmark-secs 150 --benchmark-json < /dev/null > $L/nm_${s}_r$r.json 2>> $L/nm_${s}_r$r.err
    echo "END nm_${s}_r$r $(date -u +%T) rc=$?" >> $L/nm_${s}_r$r.err
    kill $SMI
  done
done
echo AB_DONE $(date -u +%T) > $L/ab.done
