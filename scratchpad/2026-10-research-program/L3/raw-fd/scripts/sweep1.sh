#!/bin/bash
T=/root/tfast/release/deps/nice_common-3897133ca1aa3ced
O=/root/runs/fd
for B in 50000000 200000000; do
  FD_TIMING_BATCH=$B FD_TIMING_REPS=25 FD_TIMING_RUNS=32,64,128,256,512,1024,2048 $T fd_timing --ignored --nocapture --test-threads 1 > $O/sweep1_batch$B.log 2>&1
done
echo done > $O/sweep1.done
