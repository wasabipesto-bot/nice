#!/bin/bash
# chain_f03.sh: the f0 3, k 9 tile (785 x 14,750, assumed) beside 1,460 x 14,750; L1 and L5, 2 processes each (binary T).
cd /root/n1; L=/root/n1/logs
until [ -e $L/base.done ]; do sleep 5; done
export NICE_N1_ROUNDS=5 NICE_N1_REPS=3 NICE_N1_RPOOL=1071229 NICE_N1_BPOOL=4194304
run() { NICE_N1_CFGS="$(python3 cfgs.py $2)" NICE_N1_LGAP=$3 timeout 1200 bash tile.sh $1 T
  echo "$(date -u +%T) $1 $(grep -c '^N1 round' $L/$1.log 2>/dev/null) rows $(grep -o 'regs=[0-9]*' $L/$1_jit.txt | tr '\n' ' ')"; }
echo F03_START $(date -u +%T)
for p in 1 2; do for g in 1 5; do run tf03_L${g}_p$p f03 $g; done; done
echo F03_DONE $(date -u +%T) | tee $L/f03.done
