#!/bin/sh
# Run B: today vs exact (4-9) vs affine (4-9a) extension, interleaved, one thread.
cd /home/claude/projects/nice/.worktrees/n1-transversal-cpu
date -u
N1_BASES=62,60 N1_SHAPES=today,4-9,4-9a N1_PARTS=12 N1_ROUNDS=3 nice -n 19 target/release/deps/nice_common-6e1598ebcf1d20c7 n1_counts_and_timing --ignored --nocapture --test-threads 1 > ../../scratchpad/2026-10-research-program/N1/cpu/raw/runB.log 2> ../../scratchpad/2026-10-research-program/N1/cpu/raw/runB.err
date -u
N1_BASES=64 N1_SHAPES=today@0.55,4-9,4-9a N1_PARTS=8 N1_ROUNDS=3 nice -n 19 target/release/deps/nice_common-6e1598ebcf1d20c7 n1_counts_and_timing --ignored --nocapture --test-threads 1 > ../../scratchpad/2026-10-research-program/N1/cpu/raw/runB64.log 2> ../../scratchpad/2026-10-research-program/N1/cpu/raw/runB64.err
date -u
