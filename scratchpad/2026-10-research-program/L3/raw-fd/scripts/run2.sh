#!/bin/bash
T=/root/tfast/release/deps/nice_common-3897133ca1aa3ced
O=/root/runs/fd
FD_TIMING_VARIANTS=p,s,h FD_TIMING_REPS=25 FD_TIMING_RUNS=64,128,256,512 $T fd_timing --ignored --nocapture --test-threads 1 > $O/sweep2.log 2>&1
echo done > $O/sweep2.done
$T cubecl_cuda_fd_matches_cpu_detailed --ignored --nocapture --test-threads 1 > $O/exact2.log 2>&1
echo done > $O/exact2.done
