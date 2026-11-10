#!/bin/sh
# Run D: other shapes at b60 (one round, full mode only: phases tops/extend/list/scan),
# then the key-level shape (L-4, 9, 4) at b62 (a 4-digit unit with the last
# partition digit as its key: the bottom extension shared by 62 values).
cd /home/claude/projects/nice/.worktrees/n1-transversal-cpu
date -u
N1_FULL_ONLY=1 N1_BASES=60 N1_SHAPES=today,4-9a,4-9-4a,4-8a,3-9-5 N1_PARTS=4 N1_ROUNDS=2 nice -n 19 target/release/deps/nice_common-6e1598ebcf1d20c7 n1_counts_and_timing --ignored --nocapture --test-threads 1 > ../../scratchpad/2026-10-research-program/N1/cpu/raw/runD60.log 2> ../../scratchpad/2026-10-research-program/N1/cpu/raw/runD60.err
date -u
N1_FULL_ONLY=1 N1_BASES=62 N1_SHAPES=today,4-9a,4-9-4a N1_PARTS=4 N1_ROUNDS=2 nice -n 19 target/release/deps/nice_common-6e1598ebcf1d20c7 n1_counts_and_timing --ignored --nocapture --test-threads 1 > ../../scratchpad/2026-10-research-program/N1/cpu/raw/runD62.log 2> ../../scratchpad/2026-10-research-program/N1/cpu/raw/runD62.err
date -u
