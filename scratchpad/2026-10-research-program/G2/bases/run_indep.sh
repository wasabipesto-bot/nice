#!/bin/bash
# independent enumeration (indep.py) vs the prototype's unit dumps, lead windows at both ends of the range
cd $(dirname $0)
D=raw/dumps
j() { nice -n 19 python3 -I indep.py "$@"; }
( j 65 4 10 717171717 $D/unit_65_4_10_717171717.txt 68302 83302; j 65 4 10 1877467342 $D/unit_65_4_10_1877467342.txt 259625 274625; j 70 4 11 77777777777 $D/unit_70_4_11_77777777777.txt 83226 103226 ) > raw/indep_lane1.txt 2>&1 &
( j 68 4 10 727272727 $D/unit_68_4_10_727272727.txt 1283402 1303402; j 68 4 10 2181389495 $D/unit_68_4_10_2181389495.txt 2572873 2592873 ) > raw/indep_lane2.txt 2>&1 &
( j 69 4 10 737373737 $D/unit_69_4_10_737373737.txt 2728800 2753800; j 69 4 10 2301499586 $D/unit_69_4_10_2301499586.txt 5501456 5526456; j 70 4 11 195426557777 $D/unit_70_4_11_195426557777.txt 323000 343000 ) > raw/indep_lane3.txt 2>&1 &
wait; echo INDEP_DONE
