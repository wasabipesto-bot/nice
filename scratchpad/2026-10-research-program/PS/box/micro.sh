#!/bin/bash
# box: the phase-3b microbenchmark on the dumped slices, every variant interleaved, GPU clock/power logged
TAG=$1; shift; O=/root/raw/micro_$TAG; mkdir -p $O
nvidia-smi --query-gpu=timestamp,clocks.sm,clocks.mem,power.draw,temperature.gpu,utilization.gpu,clocks_throttle_reasons.active --format=csv -lms 20 > $O/smi.csv &
SMI=$!
echo "CMD /root/tgt/release/examples/mo_width_bench --cuda --dump /root/dump $* (exp/mo-word-width $(cd /root/nice && git rev-parse --short HEAD))" > $O/out.txt
date -u >> $O/out.txt
/root/tgt/release/examples/mo_width_bench --cuda --dump /root/dump "$@" >> $O/out.txt 2>&1; echo "rc=$?" >> $O/out.txt; date -u >> $O/out.txt
kill $SMI; touch $O/done
