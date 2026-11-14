#!/bin/bash
# Task 1: the CPU join's top phase at production shapes, by ablation modes
# (cpu2_prof). 3 fields per base (10 %, 50 %, 90 % of the base range), the
# first, middle and last slice of each, the first 3 partitions of
# NiceMark's bit-reversed sample order in each. Two streams at once, nice 19.
R=/home/claude/projects/nice/scratchpad/2026-10-research-program/CPU2/raw
B=$R/cpu2_prof_bin
run() { for f in 0.1 0.5 0.9; do nice -n 19 $B $1 f$f $2 3 spread; done > $R/profile_b$1.txt 2>&1; }
(run 60 1e16; run 64 1e17) &
run 62 1e17
wait
