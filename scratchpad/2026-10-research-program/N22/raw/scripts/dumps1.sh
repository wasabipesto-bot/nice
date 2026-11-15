#!/bin/bash
# dumps1.sh BIN: SPIR-V → ACO for the N22 variants (NICE_EXP_N22 bit 1 = the 64-lane scan forms, on in every dump so
# the modules are the card's). Four at a time; each lavapipe run killed after TMO s (only the compile is wanted).
W=/root/n22; export DB=${1:-Ed2} TMO=${TMO:-60}
run() { $W/scripts/spvdump.sh $1 $2 $3 > $W/out/dump_$1.out 2>&1; python3 -I $W/scripts/loops.py $W/spv/$1/*.aco.txt > $W/spv/$1/loops.txt; }
run v62_1 1 62 & run v62_3 3 62 & run v62_5 5 62 & run v62_7 7 62 & wait
run v62_17 17 62 & run v64_1 1 64 & run v64_7 7 64 & run v64_15 15 64 & wait
run v64_9 9 64 & run v64_17 17 64 & run v64_3 3 64 & wait
echo DUMPS1_DONE $(date -u +%T)
