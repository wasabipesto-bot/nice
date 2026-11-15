#!/bin/bash
# dumps3.sh: Ed3 (switch 32, the fixed-trip AND) and the combination, two dumps each.
W=/root/n22; export DB=${1:-Ed3} TMO=${TMO:-60}
run() { $W/scripts/spvdump.sh $1 $2 $3 > $W/out/dump_$1.out 2>&1; python3 -I $W/scripts/loops.py $W/spv/$1/*.aco.txt > $W/spv/$1/loops.txt; }
run a62_33 33 62 & run a64_33 33 64 & run a62_1 1 62 & run a64_59 59 64 & wait
run a62_33b 33 62 & run a64_33b 33 64 & run a62_51 51 62 & run a64_1 1 64 & wait
echo DUMPS3_DONE $(date -u +%T)
