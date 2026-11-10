#!/bin/bash
# chain_base.sh: dense phase split into base (no AND: the loads, the transposed copy, one shared read per chunk) and
# AND, binary T2 (= T + the noand mode), layouts L5 and L1, 2 processes each.
cd /root/n1; L=/root/n1/logs
until [ -e $L/tile2.done ] && grep -q BUILD_DONE build_T2.out; do sleep 5; done
export NICE_N1_ROUNDS=5 NICE_N1_REPS=3 NICE_N1_RPOOL=1071229 NICE_N1_BPOOL=4194304
run() { NICE_N1_CFGS="$(python3 cfgs.py $2)" NICE_N1_LGAP=$3 timeout 1200 bash tile.sh $1 T2
  echo "$(date -u +%T) $1 $(grep -c '^N1 round' $L/$1.log 2>/dev/null) rows $(grep -o 'regs=[0-9]*' $L/$1_jit.txt | tr '\n' ' ')"; }
echo BASE_START $(date -u +%T)
for p in 1 2; do for g in 5 1; do run tbase_L${g}_p$p base $g; done; done
echo BASE_DONE $(date -u +%T) | tee $L/base.done
