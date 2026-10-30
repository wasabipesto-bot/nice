#!/bin/bash
# ab_prod.sh OUTDIR NFIELDS ROUNDS TREE... : 1e10 production-path fields via mock API.
O=$1; N=$2; R=$3; shift 3
mkdir -p $O
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH
nvidia-smi dmon -s pucm -d 1 -o T > $O/dmon.log 2>&1 &
DM=$!
for round in $(seq 1 $R); do
  for t in "$@"; do
    for b in 40 50; do
      echo "$(date -u +%T) start r$round $t b$b" >> $O/times.log
      /root/prod1e10.sh r${round}_$t /root/t_$t/release/nice_client $b $O $N
      echo "$(date -u +%T) end r$round $t b$b" >> $O/times.log
    done
  done
done
kill $DM
echo done > $O/done
