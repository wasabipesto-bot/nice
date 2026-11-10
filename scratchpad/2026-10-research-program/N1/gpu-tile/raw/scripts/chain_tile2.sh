#!/bin/bash
# chain_tile2.sh: replaces chain_tile.sh after its first L53 grids (L53 is memory-bound at ~1.0 ps/pair, ~1.9x the
# production dense cost: not a cost model). Grids at L5 and L1 (2 processes each), walk sets at L5 and L1.
cd /root/n1; L=/root/n1/logs
while pgrep -f "tile.sh" > /dev/null; do sleep 2; done
export NICE_N1_ROUNDS=${ROUNDS:-5} NICE_N1_REPS=${REPS:-3} NICE_N1_RPOOL=1071229 NICE_N1_BPOOL=4194304
run() { # NAME SET GAP
  NICE_N1_CFGS="$(python3 cfgs.py $2)" NICE_N1_LGAP=$3 timeout 1200 bash tile.sh $1 T
  echo "$(date -u +%T) $1 $(grep -c '^N1 round' $L/$1.log 2>/dev/null) rows $(grep -o 'regs=[0-9]*' $L/$1_jit.txt | tr '\n' ' ')"
}
echo TILE2_START $(date -u +%T)
run tgrid15_L1_p1 grid_15 1
run tgrid17_L5_p1 grid_17 5
run tgrid15_L5_p1 grid_15 5
run twalk_L5 walk 5
run twalk_L1 walk 1
run tgrid17_L5_p2 grid_17 5
run tgrid17_L1_p2 grid_17 1
run tgrid15_L5_p2 grid_15 5
run tgrid15_L1_p2 grid_15 1
echo TILE2_DONE $(date -u +%T) | tee $L/tile2.done
