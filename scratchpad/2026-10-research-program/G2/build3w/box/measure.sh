#!/bin/bash
# step 3W number: base 64 through the narrow path and base 65 through the wide path, same session; $1 = bench binary, $2 = log dir
B0=$1; M=$2; mkdir -p $M
grep -q "127.0.0.1 api.nicenumbers.net" /etc/hosts || { echo "ABORT: hosts block missing" > $M/ABORT; exit 1; }
grep -E "nicenumbers" /etc/hosts > $M/hosts_block.txt
cp $B0 $M/bench; B=$M/bench; md5sum $B > $M/bin_md5.txt
nvidia-smi --query-gpu=timestamp,power.draw,clocks.sm,temperature.gpu,utilization.gpu,power.limit --format=csv -l 1 > $M/smi.csv 2>&1 &
SMI=$!
r() { n=$1; shift; echo "$(date -u +%FT%TZ) start $n" >> $M/runs.log; "$@" > $M/$n.log 2>&1; echo "$(date -u +%FT%TZ) end $n rc=$?" >> $M/runs.log; }
r b64_narrow $B --cuda --base 64 --narrow-only --fields 4095,13107,131072,249036,65536,196608
r b65 $B --cuda --base 65 --fields 4095,13731,77777,137312,200000,260893
r b64_narrow2 $B --cuda --base 64 --narrow-only --fields 4095,13107,131072,249036,65536,196608
r b65_check $B --cuda --base 65 --cpu-check --fields 4095,77777
kill $SMI
echo done > $M/measure_done
