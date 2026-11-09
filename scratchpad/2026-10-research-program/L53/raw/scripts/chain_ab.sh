#!/bin/bash
# chain_ab.sh: A/B of N (87958fd + the layer-sort commit) against B (87958fd), unprofiled, interleaved:
# 3 rounds of b62 1e17 (1 field) and b60 1e16 (2 fields), 2 rounds of b62 1e16 and b64 1e16 (2 fields);
# order B N / N B / B N. Each process's join kernel is replayed through the driver JIT (ptxjit.py); a process that
# compiled a spill variant is kept as *_spill<k> and re-run (up to twice), so the A/B compares spill-free kernels.
R=/root/l53/run.sh; L=/root/l53/logs
echo AB_START $(date -u +%T)
for r in 1 2 3; do
  if [ $r = 2 ]; then O="N B"; else O="B N"; fi
  F=("62 1 1e17 e17_b62" "60 2 1e16 e16_b60")
  [ $r -le 2 ] && F+=("62 2 1e16 e16_b62" "64 2 1e16 e16_b64")
  for f in "${F[@]}"; do
    set -- $f
    for t in $O; do
      n=ab_${t}_$4_r$r
      for try in 0 1 2; do
        [ -e $L/stop ] && exit 0
        $R $n $t $1 $2 $3
        nice -n 19 python3 /root/l53/ptxjit.py --only join /root/l53/ptx/$n > $L/${n}_jit.txt 2>&1
        echo "$(date -u +%T) $n try$try $(grep -o 'per_field=[0-9.]*' $L/$n.log | tail -1) $(grep -o 'device=[0-9.]*s' $L/$n.log | tail -1) $(grep -o 'survivors=[0-9]* checked=[0-9]*' $L/$n.log | tail -1) $(grep -o 'regs=[0-9]* local=[0-9]*' $L/${n}_jit.txt | tail -1)"
        if grep -q 'variant=SPILL' $L/${n}_jit.txt && [ $try -lt 2 ]; then
          for x in log smi; do mv $L/$n.$x $L/${n}_spill$try.$x; done
          mv $L/${n}_jit.txt $L/${n}_spill${try}_jit.txt; mv /root/l53/ptx/$n /root/l53/ptx/${n}_spill$try
        else
          break
        fi
      done
    done
  done
done
echo AB_DONE $(date -u +%T) | tee $L/ab.done
