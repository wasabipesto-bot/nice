#!/bin/bash
T=/root/tfast/release/deps/nice_common-3897133ca1aa3ced
O=/root/runs/fd
FD_TIMING_VARIANTS=m,t FD_TIMING_REPS=25 FD_TIMING_RUNS=64,128,256 $T fd_timing --ignored --nocapture --test-threads 1 > $O/sweep4.log 2>&1
FD_TIMING_WINDOW=2000000000 FD_TIMING_VARIANTS=m,t FD_TIMING_REPS=3 FD_TIMING_RUNS=64,128,256 $T fd_timing --ignored --nocapture --test-threads 1 > $O/sweep4_bigwin.log 2>&1
echo done > $O/sweep4.done
$T cubecl_cuda_fd_matches_cpu_detailed --ignored --nocapture --test-threads 1 > $O/exact4.log 2>&1
echo done > $O/exact4.done
