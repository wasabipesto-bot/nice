#!/bin/bash
# dumps2.sh: repeat dumps (CubeCL's SPIR-V differs run to run for one kernel id: how much do ACO's counts move?).
W=/root/n22; export DB=${1:-Ed2} TMO=${TMO:-60}
run() { $W/scripts/spvdump.sh $1 $2 $3 > $W/out/dump_$1.out 2>&1; python3 -I $W/scripts/loops.py $W/spv/$1/*.aco.txt > $W/spv/$1/loops.txt; }
for r in b c; do
  run v62_1$r 1 62 & run v62_3$r 3 62 & run v64_1$r 1 64 & run v64_3$r 3 64 & wait
  run v64_15$r 15 64 & run v62_17$r 17 62 & run v64_17$r 17 64 & run v64_9$r 9 64 & wait
done
echo DUMPS2_DONE $(date -u +%T)
