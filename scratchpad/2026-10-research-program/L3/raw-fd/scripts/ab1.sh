#!/bin/bash
# Benchmark-harness A/B: 3 interleaved rounds, arms main (origin/main release build),
# old (this build, NICE_DETAILED_FD=0), fd1 (v1: plain, R=256), fd2 (v2: static mask, R=128).
O=/root/runs/fd/ab1
mkdir -p $O
cp /root/tfast/release/nice_client /root/bin/nice_client.v2
export NICE_API_BASE=http://127.0.0.1:9
nvidia-smi dmon -s pucm -d 2 -o T > $O/dmon.log 2>&1 &
DM=$!
for round in 1 2 3; do
  for arm in main old fd1 fd2; do
    unset NICE_DETAILED_FD NICE_FD_STATIC NICE_FD_RUN
    B=/root/bin/nice_client.v2
    case $arm in
      main) B=/root/bin/nice_client.main ;;
      old) export NICE_DETAILED_FD=0 ;;
      fd1) export NICE_FD_STATIC=0 NICE_FD_RUN=256 ;;
      fd2) export NICE_FD_RUN=128 ;;
    esac
    echo "# $(date -u +%FT%TZ) round $round arm $arm" > $O/r${round}_$arm.log
    $B detailed --gpu --benchmark --benchmark-secs 40 < /dev/null >> $O/r${round}_$arm.log 2>&1
  done
done
kill $DM
echo done > $O/done
