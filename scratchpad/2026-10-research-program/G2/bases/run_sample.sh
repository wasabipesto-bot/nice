#!/bin/bash
# Main count runs: random super-units per (base, shape), tops sampled at q. Three lanes, nice 19.
B=$(dirname $0)/proto/target/release/g2proto
R=$(dirname $0)/raw/sample
mkdir -p $R
lane1() { nice -n 19 $B sample 64 4 10 4 0.25 101 > $R/b64_4_10.txt 2>&1; nice -n 19 $B sample 65 4 10 6 0.1 102 > $R/b65_4_10.txt 2>&1; nice -n 19 $B sample 68 4 11 2 0.05 108 > $R/b68_4_11.txt 2>&1; }
lane2() { nice -n 19 $B sample 68 4 10 6 0.02 103 > $R/b68_4_10.txt 2>&1; nice -n 19 $B sample 69 4 10 6 0.01 104 > $R/b69_4_10.txt 2>&1; nice -n 19 $B sample 69 4 11 2 0.04 109 > $R/b69_4_11.txt 2>&1; }
lane3() { nice -n 19 $B sample 70 4 11 6 0.05 105 > $R/b70_4_11.txt 2>&1; nice -n 19 $B sample 70 4 10 3 0.001 106 > $R/b70_4_10.txt 2>&1; nice -n 19 $B sample 65 5 10 1 0.5 107 > $R/b65_5_10.txt 2>&1; }
lane1 & lane2 & lane3 & wait
echo SAMPLE_DONE
