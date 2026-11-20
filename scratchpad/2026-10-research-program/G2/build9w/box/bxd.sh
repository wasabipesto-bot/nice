#!/bin/bash
# box: bxd.sh — the expansion ablation build (c2152084 + xdiag.patch): wide bench, release profile, /root/t/xd
source ~/.cargo/env; L=/root/logs/xd; mkdir -p $L /root/bin/xd; rm -f $L/done
cd /root/xd; git log --oneline -1 > $L/head.txt; git diff | md5sum >> $L/head.txt
CARGO_TARGET_DIR=/root/t/xd cargo build --release -p nice_common --features cubecl-cuda,midout-bench --example midout_wide_bench > $L/b.log 2>&1; echo "rc=$?" >> $L/rc.txt
cp /root/t/xd/release/examples/midout_wide_bench /root/bin/xd/; md5sum /root/bin/xd/* >> $L/rc.txt; echo done > $L/done
