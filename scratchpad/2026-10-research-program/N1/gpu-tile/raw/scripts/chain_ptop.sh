#!/bin/bash
# chain_ptop.sh: small buckets (per-top AND below TRANSPOSE_MIN 192) at today's entries, L1 and L5 (binary T).
cd /root/n1; L=/root/n1/logs
until [ -e $L/f03.done ]; do sleep 5; done
export NICE_N1_ROUNDS=5 NICE_N1_REPS=3 NICE_N1_RPOOL=1071229 NICE_N1_BPOOL=4194304
run() { NICE_N1_CFGS="$(python3 cfgs.py $2)" NICE_N1_LGAP=$3 timeout 1200 bash tile.sh $1 T
  echo "$(date -u +%T) $1 $(grep -c '^N1 round' $L/$1.log 2>/dev/null) rows $(grep -o 'regs=[0-9]*' $L/$1_jit.txt | tr '\n' ' ')"; }
for g in 1 5; do run tptop_L${g}_p1 ptop $g; done
echo PTOP_DONE $(date -u +%T) | tee $L/ptop.done
