#!/bin/bash
# chain_tile.sh: the tile harness (binary T). Memory layouts (process-level): L53 = production-like register-side gather
# (increasing list indices, mean gap 53, over a 1,071,229-entry pool = one slot's bpre at today's b62 shape), L5, L1 =
# contiguous (the transversal design's materialised lists). Batch-side records: contiguous runs in a 4 Mi-record pool.
cd /root/n1; L=/root/n1/logs
export NICE_N1_ROUNDS=${ROUNDS:-5} NICE_N1_REPS=${REPS:-3} NICE_N1_RPOOL=1071229 NICE_N1_BPOOL=4194304
run() { # NAME SET GAP
  NICE_N1_CFGS="$(python3 cfgs.py $2)" NICE_N1_LGAP=$3 timeout 1200 bash tile.sh $1 T
  echo "$(date -u +%T) $1 $(grep -c '^N1 round' $L/$1.log 2>/dev/null) rows $(grep -m1 -o 'regs=[0-9]*' $L/$1_jit.txt)"
}
echo TILE_START $(date -u +%T)
for g in 53 5 1; do run tcal_L$g cal $g; done
for rep in 1 2; do
  for g in 53 1; do
    run tgrid17_L${g}_p$rep grid_17 $g
    run tgrid15_L${g}_p$rep grid_15 $g
  done
done
for g in 53 1; do run twalk_L$g walk $g; done
echo TILE_DONE $(date -u +%T) | tee $L/tile.done
