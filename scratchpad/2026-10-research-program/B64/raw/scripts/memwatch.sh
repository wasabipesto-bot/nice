#!/bin/bash
# memwatch.sh: every 10 s, the card's total used memory against this container's processes' (a foreign tenant's work on
# the GPU shows as the difference), plus clocks and power.
while true; do
  t=$(nvidia-smi --query-gpu=timestamp,memory.used,clocks.sm,power.draw,utilization.gpu --format=csv,noheader)
  a=$(nvidia-smi --query-compute-apps=used_memory --format=csv,noheader,nounits | awk '{s+=$1} END {print s+0}')
  echo "$t, ours=$a MiB"
  sleep 10
done
