#!/bin/bash
B=/root/tfast/release/nice_client
export NICE_API_BASE=http://127.0.0.1:9
O=/root/runs/fd
for arm in old fd; do
  if [ $arm = old ]; then export NICE_DETAILED_FD=0; else export NICE_DETAILED_FD=1; fi
  echo "# $(date -u +%FT%TZ) arm $arm" > $O/quick_$arm.log
  $B detailed --gpu --benchmark --benchmark-secs 20 < /dev/null >> $O/quick_$arm.log 2>&1
done
echo done > $O/quick.done
