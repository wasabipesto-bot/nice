#!/bin/bash
# box: pre.sh — a current `just` (apt's cannot parse the justfile), then the reference head 5a048669's binaries:
# its midout_bench (repository release profile, cubecl-cuda,midout-bench) and its lib test binary (bt.sh, sc only) for the kernel dump
source ~/.cargo/env; L=/root/logs/pre; mkdir -p $L /root/bin/base5a
curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to /usr/local/bin > $L/just.log 2>&1; echo "just rc=$? $(/usr/local/bin/just --version)" >> $L/rc.txt
cd /root/base5a; git log --oneline -1 > $L/head.txt
CARGO_TARGET_DIR=/root/t/base5ab cargo build --release -p nice_common --features cubecl-cuda,midout-bench --example midout_bench > $L/b_bench.log 2>&1; echo "bench rc=$?" >> $L/rc.txt
cp /root/t/base5ab/release/examples/midout_bench /root/bin/base5a/
BT_SETS=sc:cubecl-cuda,cubecl-spirv bash /root/bt.sh base5a base5a; echo "bt rc=$?" >> $L/rc.txt
md5sum /root/bin/base5a/* >> $L/rc.txt; echo done > $L/done
