#!/bin/bash
# chain_screen2.sh: the screen restarted after chain_screen.sh's name bug (07:04). Round 1 b62 finishes the variants
# that ran (base, ept1, ept3, tm128, tm256, ag8, base2 stay valid; tm512's and ag2's runs were the defaults and are kept
# as base4 / base3; base5 and base6 re-anchor the continuation), then round 1 b60 and round 2 (reversed lists) as designed. Spill-variant processes re-run (2 more tries).
source /root/l51/cfg.sh
R=/root/l51/run.sh; L=/root/l51/logs
echo SCREEN2_START $(date -u +%T)
V1="base ept1 ept3 tm128 tm256 tm512 ag2 ag8 base2 tc128 tc512 fd128 fd512 stg1 fl256 fl768"
V2=$(echo $V1 | tr ' ' '\n' | tac | tr '\n' ' ')
R1B62="base5 tm512 ag2 tc128 tc512 base6 fd128 fd512 stg1 fl256 fl768"
for blk in "1 62 1 1e17 e17_b62" "1 60 2 1e16 e16_b60" "2 62 1 1e17 e17_b62" "2 60 2 1e16 e16_b60"; do
  set -- $blk; r=$1; shift
  if [ $r = 1 ]; then V=$V1; else V=$V2; fi
  if [ $r = 1 ] && [ $4 = e17_b62 ]; then V=$R1B62; fi
  for v in $V; do
    n=s_${v}_$4_r$r
    for try in 0 1 2; do
      [ -e $L/stop ] && { echo STOPPED $(date -u +%T); exit 0; }
      setcfg $v || { echo "BAD CFG $v"; exit 1; }
      $R $n $BIN $1 $2 $3
      nice -n 19 python3 /root/l51/ptxjit.py --only join /root/l51/ptx/$n > $L/${n}_jit.txt 2>&1
      echo "$(date -u +%T) $n try$try $(grep -o 'device=[0-9.]*s' $L/$n.log | tail -1) $(grep -o 'survivors=[0-9]* checked=[0-9]*' $L/$n.log | tail -1) $(grep -o 'regs=[0-9]* local=[0-9]*' $L/${n}_jit.txt | tail -1) env=[$(head -1 $L/$n.log | grep -o 'env=\[[^]]*' | cut -c6-)]"
      if grep -q 'variant=SPILL' $L/${n}_jit.txt && [ $try -lt 2 ]; then
        for x in log smi; do mv $L/$n.$x $L/${n}_spill$try.$x; done
        mv $L/${n}_jit.txt $L/${n}_spill${try}_jit.txt; mv /root/l51/ptx/$n /root/l51/ptx/${n}_spill$try
      else
        break
      fi
    done
  done
  touch $L/screen_r${r}_$4.done
done
echo SCREEN_DONE $(date -u +%T) | tee $L/screen.done
