#!/bin/bash
# box: suite.sh — production's CI test commands on the head (/root/mx, a copy of /root/mc at its HEAD): the
# workspace's `cargo test --locked --release --no-fail-fast`, its `--features gpu --lib` run of nice_common, and the
# client's tests with CubeCL (the route's tests); target dir /root/t/mx
source ~/.cargo/env; [ -d /root/mx ] || git clone -q /root/mc /root/mx; cd /root/mx; git fetch -q /root/mc HEAD && git checkout -q . && git checkout -q FETCH_HEAD
export CARGO_TARGET_DIR=/root/t/mx; O=/root/runs/suite_head; mkdir -p $O; rm -f $O/done $O/rc.txt
git log --oneline -1 > $O/head.txt; git status --short >> $O/head.txt
cargo test --locked --release --no-fail-fast > $O/workspace.txt 2>&1; echo "workspace rc=$?" >> $O/rc.txt
cargo test --locked --release -p nice_common --features gpu --lib > $O/common_gpu.txt 2>&1; echo "common gpu lib rc=$?" >> $O/rc.txt
cargo test --locked --release -p nice_client --features cubecl-cuda > $O/client_cubecl.txt 2>&1; echo "client cubecl-cuda rc=$?" >> $O/rc.txt
echo done > $O/done
