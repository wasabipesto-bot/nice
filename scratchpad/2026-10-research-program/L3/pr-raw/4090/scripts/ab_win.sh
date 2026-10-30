#!/bin/bash
# ab_win.sh OUTDIR WINDOW REPS ROUNDS TREE... : fixed windows, interleaved by tree.
O=$1; W=$2; N=$3; R=$4; shift 4
mkdir -p $O
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH
nvidia-smi dmon -s pucm -d 1 -o T > $O/dmon.log 2>&1 &
DM=$!
for round in $(seq 1 $R); do
  for t in "$@"; do
    echo "$(date -u +%T) start r$round $t" >> $O/times.log
    L3_TAG=r${round}_$t L3_WINDOW=$W L3_REPS=$N /root/t_$t/release/examples/l3win > $O/r${round}_$t.log 2>&1
    echo "$(date -u +%T) end r$round $t" >> $O/times.log
  done
done
kill $DM
echo done > $O/done
