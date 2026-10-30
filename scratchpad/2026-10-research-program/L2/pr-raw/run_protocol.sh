#!/bin/bash
# Interleaved A/B detailed benchmark protocol. A = /root/main, B = /root/pr.
set -u
OUT=/root/out
mkdir -p $OUT
sample() { # tag
  local mhz
  mhz=$(awk '/cpu MHz/ {s+=$4; n++; if ($4>2000) h++} END {printf "avg %.0f MHz, %d of %d cpus above 2 GHz", s/n, h, n}' /proc/cpuinfo)
  echo "$(date -u +%H:%M:%S) $1 | $mhz | load $(cut -d' ' -f1-3 /proc/loadavg) | $(grep -E 'nr_throttled|throttled_usec' /sys/fs/cgroup/cpu.stat | tr '\n' ' ')" >> $OUT/clock.log
}
( while true; do sample tick; sleep 15; done ) &
SAMPLER=$!
run() { # tag tree threads
  local tag=$1 tree=$2 t=$3
  sample "start $tag"
  /root/$tree/target/release/nice_client detailed --benchmark --benchmark-secs 150 --threads $t --benchmark-json \
    > $OUT/$tag.json 2> $OUT/$tag.err < /dev/null
  echo "$(date -u +%H:%M:%S) done $tag exit $?" >> $OUT/progress.log
  sample "end $tag"
}
for T in 15 64; do
  for r in 1 2 3; do
    run t${T}-r${r}-A main $T
    run t${T}-r${r}-B pr $T
  done
done
run t1-A main 1
run t1-B pr 1
kill $SAMPLER
echo ALLDONE >> $OUT/progress.log
