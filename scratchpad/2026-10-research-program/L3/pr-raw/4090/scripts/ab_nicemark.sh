#!/bin/bash
# ab_nicemark.sh OUTDIR SECS ROUNDS TREE... : NiceMark detailed GPU, interleaved.
O=$1; S=$2; R=$3; shift 3
mkdir -p $O
export NICE_API_BASE=http://127.0.0.1:9
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH
nvidia-smi dmon -s pucm -d 2 -o T > $O/dmon.log 2>&1 &
DM=$!
for round in $(seq 1 $R); do
  for t in "$@"; do
    echo "$(date -u +%T) start r$round $t" >> $O/times.log
    echo "# $(date -u +%FT%TZ) round $round tree $t" > $O/r${round}_$t.log
    ( sleep 50; nvidia-smi -q -d PERFORMANCE,CLOCK,POWER,TEMPERATURE > $O/q_r${round}_$t.txt 2>&1 ) &
    /root/t_$t/release/nice_client detailed --gpu --benchmark --benchmark-secs $S < /dev/null >> $O/r${round}_$t.log 2>&1
    echo "$(date -u +%T) end r$round $t" >> $O/times.log
  done
done
kill $DM
echo done > $O/done
