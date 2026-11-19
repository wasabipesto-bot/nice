#!/bin/bash
# box, diagnostic only (uncommitted: set_fault made pub, XWIDE_FAULT read by the wide bench): split the b65 expansion
# by timing it with the prefilter off (F_NOPF = 1); $1 log dir
set -u
L=$1; mkdir -p $L; source /root/mo/guard.sh $L || exit 1
source ~/.cargo/env; cd /root/m5w; export CARGO_TARGET_DIR=/root/t/m5w
git log --oneline -1 > $L/head.txt; git diff > $L/diag.patch
cargo build --release -p nice_common --features cubecl-cuda --example midout_wide_bench > $L/build.log 2>&1; echo rc=$? >> $L/build.log
mkdir -p /root/m5wbin/xnopf; cp /root/t/m5w/release/examples/midout_wide_bench /root/m5wbin/xnopf/; BW=/root/m5wbin/xnopf/midout_wide_bench
r() { n=$1; shift; echo "$(date -u +%FT%TZ) start $n" >> $L/runs.log; env "$@" > $L/$n.log 2>&1; rc=$?; echo "$(date -u +%FT%TZ) end $n rc=$rc" >> $L/runs.log; }
r s3 MIDOUT_STOP=3 $BW --cuda --base 65 --fields 77777
r s5 MIDOUT_STOP=5 $BW --cuda --base 65 --fields 77777
r s5_nopf MIDOUT_STOP=5 XWIDE_FAULT=1 $BW --cuda --base 65 --fields 77777
r s3b MIDOUT_STOP=3 $BW --cuda --base 65 --fields 77777
echo done > $L/done
