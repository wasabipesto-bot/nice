#!/bin/bash
# box: bbench.sh SRC TAG — tree /root/SRC benches (cubecl-cuda,midout-bench; the repository release profile) into /root/bin/TAG, target /root/t/SRCb
source ~/.cargo/env; L=/root/logs/bb_$2; mkdir -p $L /root/bin/$2; rm -f $L/done $L/rc.txt; cd /root/$1; git log --oneline -1 > $L/head.txt; git status --short >> $L/head.txt; md5sum common/src/midout/*.rs >> $L/head.txt
CARGO_TARGET_DIR=/root/t/$1b cargo build --release -p nice_common --features cubecl-cuda,midout-bench --example midout_bench --example midout_wide_bench > $L/b.log 2>&1; echo "bench rc=$?" >> $L/rc.txt
cp /root/t/$1b/release/examples/midout_bench /root/t/$1b/release/examples/midout_wide_bench /root/bin/$2/; md5sum /root/bin/$2/midout_* >> $L/rc.txt; echo done > $L/done
