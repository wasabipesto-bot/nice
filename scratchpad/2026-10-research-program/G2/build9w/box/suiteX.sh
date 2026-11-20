#!/bin/bash
# box: suiteX.sh SRC TAG — production's CI test commands on the working tree /root/SRC (target /root/t/SRCs); output /root/runs/s_TAG
source ~/.cargo/env; S=$1; O=/root/runs/s_$2; mkdir -p $O; rm -f $O/done $O/rc.txt; cd /root/$S; git log --oneline -1 > $O/head.txt; git status --short >> $O/head.txt; md5sum common/src/midout/*.rs >> $O/head.txt
export CARGO_TARGET_DIR=/root/t/${S}s
t() { n=$1; shift; s0=$(date +%s); "$@" > $O/$n.txt 2>&1; echo "$n rc=$? $(( $(date +%s) - s0 )) s" >> $O/rc.txt; }
t suite_workspace cargo test --locked --release --no-fail-fast
t suite_common_gpu cargo test --locked --release -p nice_common --features gpu --lib
t suite_client_cubecl cargo test --locked --release -p nice_client --features cubecl-cuda
echo done > $O/done
