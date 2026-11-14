#!/bin/bash
# NiceMark CPU nice-only sweep (--benchmark, no --gpu), all threads (the
# container's 42), 150 s budget, main and branch interleaved, order
# alternating per round. Offline: no upload without --benchmark-upload.
R=${1:-4}; F=${2:-1}
O=/root/out; LOG=$O/nicemark-runs.txt
for r in $(seq $F $((F + R - 1))); do
  if (( r % 2 == 1 )); then ORDER="main br"; else ORDER="br main"; fi
  for bin in $ORDER; do
    echo "### r$r $bin start $(date -u +%H:%M:%S) load $(cat /proc/loadavg)" >> $LOG
    /root/bin/$bin/nice_client niceonly --benchmark --threads 0 --benchmark-secs 150 --benchmark-json \
      > $O/nicemark-r$r-$bin.json 2> $O/nicemark-r$r-$bin.stderr
    echo "### r$r $bin end $(date -u +%H:%M:%S) exit $? load $(cat /proc/loadavg)" >> $LOG
  done
done
echo "### done $(date -u +%H:%M:%S)" >> $LOG
