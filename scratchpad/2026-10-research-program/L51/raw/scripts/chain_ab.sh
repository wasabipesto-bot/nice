#!/bin/bash
# chain_ab.sh CFG: 3-round interleaved A/B of the knob config CFG (side A) against the defaults (side B), both binary E,
# unprofiled, b62 1e17 then b60 1e16 (order A B / B A / A B; spill-variant processes re-run as in chain_screen.sh); then
# NiceMark nice-only (150 s, 4 rounds, client_E with CFG's environment or none, alternating).
source /root/l51/cfg.sh
CFG=$1; R=/root/l51/run.sh; L=/root/l51/logs
echo AB_START $CFG $(date -u +%T)
for r in 1 2 3; do
  if [ $r = 2 ]; then O="B A"; else O="A B"; fi
  for f in "62 1 1e17 e17_b62" "60 2 1e16 e16_b60"; do
    set -- $f
    for t in $O; do
      n=ab_${t}_$4_r$r
      for try in 0 1 2; do
        [ -e $L/stop ] && exit 0
        if [ $t = A ]; then setcfg $CFG; else setcfg base; fi
        $R $n E $1 $2 $3
        nice -n 19 python3 /root/l51/ptxjit.py --only join /root/l51/ptx/$n > $L/${n}_jit.txt 2>&1
        echo "$(date -u +%T) $n try$try $(grep -o 'device=[0-9.]*s' $L/$n.log | tail -1) $(grep -o 'survivors=[0-9]* checked=[0-9]*' $L/$n.log | tail -1) $(grep -o 'regs=[0-9]* local=[0-9]*' $L/${n}_jit.txt | tail -1)"
        if grep -q 'variant=SPILL' $L/${n}_jit.txt && [ $try -lt 2 ]; then
          for x in log smi; do mv $L/$n.$x $L/${n}_spill$try.$x; done
          mv $L/${n}_jit.txt $L/${n}_spill${try}_jit.txt; mv /root/l51/ptx/$n /root/l51/ptx/${n}_spill$try
        else
          break
        fi
      done
    done
  done
done
echo AB_FIELDS_DONE $(date -u +%T)
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH:-} NICE_API_BASE=http://127.0.0.1:9 NICE_BUILD_SHA=test
mkdir -p /root/l51/nm && cd /root/l51/nm
for r in 1 2 3 4; do
  if [ $((r % 2)) = 0 ]; then O="B A"; else O="A B"; fi
  for t in $O; do
    [ -e $L/stop ] && exit 0
    if [ $t = A ]; then setcfg $CFG; else setcfg base; fi
    ( while true; do nvidia-smi --query-gpu=timestamp,clocks.sm,clocks.mem,power.draw,power.limit,temperature.gpu,utilization.gpu,clocks_throttle_reasons.active --format=csv,noheader; sleep 5; done ) > $L/nm_${t}_r$r.smi 2>&1 &
    SMI=$!
    echo "START nm_${t}_r$r $(date -u +%T) cfg=$([ $t = A ] && echo $CFG || echo base) env=[$(env | grep '^NICE_EXP_' | sort | tr '\n' ' ')] md5=$(md5sum /root/l51/bin/client_E | cut -c1-8)" > $L/nm_${t}_r$r.err
    /root/l51/bin/client_E niceonly --gpu --benchmark --benchmark-secs 150 --benchmark-json < /dev/null > $L/nm_${t}_r$r.json 2>> $L/nm_${t}_r$r.err
    echo "END nm_${t}_r$r $(date -u +%T) rc=$?" >> $L/nm_${t}_r$r.err
    kill $SMI
    echo "$(date -u +%T) nm_${t}_r$r $(python3 -c "import json;d=json.load(open('$L/nm_${t}_r$r.json'));print(d.get('score', d.get('nicemark', '?')))" 2>/dev/null)"
  done
done
echo AB_DONE $(date -u +%T) | tee $L/ab.done
