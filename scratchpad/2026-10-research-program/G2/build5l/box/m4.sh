#!/bin/bash
# box: the head's base 64 (parent sharing on, the default) and base 65 (pf_w2, the default) in one session, §11.4's
# fields, t 4095 first as warm-up, b64 before and after; $1 log dir
set -u
L=$1; mkdir -p $L; source /root/mo/guard.sh $L || exit 1
source ~/.cargo/env; cd /root/m5w; export CARGO_TARGET_DIR=/root/t/m5w
git log --oneline -1 > $L/head.txt; git status --short >> $L/head.txt
cargo build --release -p nice_common --features cubecl-cuda --example midout_bench --example midout_wide_bench > $L/build.log 2>&1; echo rc=$? >> $L/build.log
cp /root/t/m5w/release/examples/midout_bench /root/t/m5w/release/examples/midout_wide_bench /root/m5wbin/final/
BN=/root/m5wbin/final/midout_bench; BW=/root/m5wbin/final/midout_wide_bench; md5sum $BN $BW > $L/bins.txt
nvidia-smi --query-gpu=timestamp,power.draw,clocks.sm,temperature.gpu,utilization.gpu,memory.used --format=csv,noheader -lms 1000 > $L/smi.csv & MP=$!
r() { n=$1; shift; echo "$(date -u +%FT%TZ) start $n" >> $L/runs.log; env "$@" > $L/$n.log 2>&1; rc=$?; echo "$(date -u +%FT%TZ) end $n rc=$rc" >> $L/runs.log; }
r b64_a X=1 $BN --cuda --fields 4095,13107,131072,249036,65536,196608 --no-cpu-check
r b65 X=1 $BW --cuda --base 65 --fields 4095,13731,77777,137312,200000,260893
r b64_b X=1 $BN --cuda --fields 4095,13107,131072,249036,65536,196608 --no-cpu-check
kill $MP; echo done > $L/done
