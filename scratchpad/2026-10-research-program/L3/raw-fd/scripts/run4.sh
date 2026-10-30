#!/bin/bash
T=/root/tfast/release/deps/nice_common-3897133ca1aa3ced
O=/root/runs/fd
export NICE_API_BASE=http://127.0.0.1:9
cp /root/tfast/release/nice_client /root/bin/nice_client.v3
# 1. source dump + registers for v3 (default options)
cd $O && rm -rf src cubecl_src.log cubecl_src_old.log
CUBECL_DEBUG_LOG=$O/cubecl_src.log timeout 100 /root/bin/nice_client.v3 detailed --gpu --benchmark --benchmark-secs 2 < /dev/null > /dev/null 2>&1
NICE_DETAILED_FD=0 CUBECL_DEBUG_LOG=$O/cubecl_src_old.log timeout 100 /root/bin/nice_client.v3 detailed --gpu --benchmark --benchmark-secs 2 < /dev/null > /dev/null 2>&1
python3 /root/regs.py > $O/regs_v3.txt 2>&1
(cd $O/src && python3 /root/loop.py fd_detailed_fd_kernel_b50.sass fd_detailed_fd_kernel_b40.sass old_detailed_kernel_b50.sass old_detailed_kernel_b40.sass) > $O/loops_v3.txt 2>&1
# 2. big window (2e9) timing: kernel-dominated
FD_TIMING_WINDOW=2000000000 FD_TIMING_VARIANTS=p,s,m FD_TIMING_REPS=3 FD_TIMING_RUNS=64,128,256 $T fd_timing --ignored --nocapture --test-threads 1 > $O/sweep_bigwin.log 2>&1
# 3. final harness A/B
A=$O/ab2; mkdir -p $A
nvidia-smi dmon -s pucm -d 2 -o T > $A/dmon.log 2>&1 &
DM=$!
for round in 1 2 3; do
  for arm in old fd1 fd2 fd3; do
    unset NICE_DETAILED_FD NICE_FD_STATIC NICE_FD_RUN NICE_FD_MERGED
    case $arm in
      old) export NICE_DETAILED_FD=0 ;;
      fd1) export NICE_FD_STATIC=0 NICE_FD_RUN=256 ;;
      fd2) export NICE_FD_MERGED=0 NICE_FD_RUN=128 ;;
      fd3) export NICE_FD_RUN=128 ;;
    esac
    echo "# $(date -u +%FT%TZ) round $round arm $arm" > $A/r${round}_$arm.log
    /root/bin/nice_client.v3 detailed --gpu --benchmark --benchmark-secs 40 < /dev/null >> $A/r${round}_$arm.log 2>&1
  done
done
kill $DM
echo done > $O/run4.done
