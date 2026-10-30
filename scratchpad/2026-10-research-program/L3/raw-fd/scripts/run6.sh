#!/bin/bash
T=/root/tfast/release/deps/nice_common-3897133ca1aa3ced
O=/root/runs/fd
export NICE_API_BASE=http://127.0.0.1:9
cp /root/tfast/release/nice_client /root/bin/nice_client.v5
A=$O/ab3; mkdir -p $A
nvidia-smi dmon -s pucm -d 2 -o T > $A/dmon.log 2>&1 &
DM=$!
for round in 1 2 3; do
  for arm in old_full old_trim fd3_full fd3_trim; do
    unset NICE_DETAILED_FD NICE_FD_RUN NICE_MISS_READ_ALL
    export NICE_FD_RUN=128
    case $arm in
      old_full) export NICE_DETAILED_FD=0 NICE_MISS_READ_ALL=1 ;;
      old_trim) export NICE_DETAILED_FD=0 ;;
      fd3_full) export NICE_MISS_READ_ALL=1 ;;
      fd3_trim) ;;
    esac
    echo "# $(date -u +%FT%TZ) round $round arm $arm" > $A/r${round}_$arm.log
    /root/bin/nice_client.v5 detailed --gpu --benchmark --benchmark-secs 40 < /dev/null >> $A/r${round}_$arm.log 2>&1
  done
done
kill $DM
echo done > $O/ab3.done
$T cubecl_cuda_fd_matches_cpu_detailed --ignored --nocapture --test-threads 1 > $O/exact5.log 2>&1
echo done > $O/exact5.done
