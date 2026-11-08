#!/bin/bash
# chain_screen.sh (first form; stopped at 07:04 by a bug: `setcfg ${v%2}` turned tm512, ag2, tc512, fd512 into
# unknown names, so those runs ran the defaults; superseded by chain_screen2.sh): unprofiled retune screen, 2 rounds; per round b62 1e17 then b60 1e16; base twice per block (first and
# middle); round 2 runs the list reversed. After each run its join kernel is replayed through the driver's JIT
# (ptxjit.py); a run whose join kernel is the 40-register spill variant is kept as <name>_spillK and re-run (up to 2
# more tries), so variants are compared spill-free (the spill tax is measured separately).
source /root/l51/cfg.sh
R=/root/l51/run.sh; L=/root/l51/logs
until [ -e $L/main.done ] || [ -e $L/stop ]; do sleep 10; done
echo SCREEN_START $(date -u +%T)
V1="base ept1 ept3 tm128 tm256 tm512 ag2 ag8 base2 tc128 tc512 fd128 fd512 stg1 fl256 fl768"
V2=$(echo $V1 | tr ' ' '\n' | tac | tr '\n' ' ')
for r in 1 2; do
  if [ $r = 1 ]; then V=$V1; else V=$V2; fi
  for f in "62 1 1e17 e17_b62" "60 2 1e16 e16_b60"; do
    set -- $f
    for v in $V; do
      n=s_${v}_$4_r$r
      for try in 0 1 2; do
        [ -e $L/stop ] && { echo STOPPED $(date -u +%T); exit 0; }
        setcfg ${v%2}
        $R $n $BIN $1 $2 $3
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
  touch $L/screen_r$r.done
done
echo SCREEN_DONE $(date -u +%T) | tee $L/screen.done
