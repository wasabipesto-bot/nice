#!/bin/bash
# chain_prab.sh: A/B, A = base 51410e7 (P0), B = pr/top-fd (P); interleaved A B per round; nothing else on the box.
R=/root/l35/run2.sh; L=/root/l35/logs; BIN=/root/l35/bin
until [ -e $L/pcuda.done ] && [ -e $L/plvp.done ]; do sleep 10; done
export STARTS=57:28151599893042801193,58:130525216587923470200,60:1366406074057412100454,62:7997740455941656911841,64:41242006262957161709568
unset NICE_EXP_TOP_FD
echo PRAB_START $(date -u +%T) > $L/prab.start
for r in 1 2; do SRCD=P0 $R pr_A_e17_b62_r$r P0 62 1 1e17; SRCD=P $R pr_B_e17_b62_r$r P 62 1 1e17; done
for f in "62 e16_b62" "60 e16_b60" "58 e16_b58" "64 e16_b64"; do
  set -- $f
  for r in 1 2; do SRCD=P0 $R pr_A_$2_r$r P0 $1 2 1e16; SRCD=P $R pr_B_$2_r$r P $1 2 1e16; done
done
echo PRAB_FIELDS_DONE $(date -u +%T) > $L/prabf.done
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH:-} NICE_API_BASE=http://127.0.0.1:9
cd /root/l35
for r in 1 2; do
  for s in A B; do
    if [ $s = A ]; then C=client_P0; else C=client_P; fi
    ( while true; do nvidia-smi --query-gpu=timestamp,clocks.sm,clocks.mem,power.draw,power.limit,temperature.gpu,utilization.gpu,clocks_throttle_reasons.active --format=csv,noheader; sleep 5; done ) > $L/prnm_${s}_r$r.smi 2>&1 &
    SMI=$!
    echo "START prnm_${s}_r$r $(date -u +%T) bin=$C md5=$(md5sum $BIN/$C | cut -c1-8)" > $L/prnm_${s}_r$r.err
    $BIN/$C niceonly --gpu --benchmark --benchmark-secs 150 --benchmark-json < /dev/null > $L/prnm_${s}_r$r.json 2>> $L/prnm_${s}_r$r.err
    echo "END prnm_${s}_r$r $(date -u +%T) rc=$?" >> $L/prnm_${s}_r$r.err
    kill $SMI
  done
done
echo PRAB_DONE $(date -u +%T) > $L/prab.done
