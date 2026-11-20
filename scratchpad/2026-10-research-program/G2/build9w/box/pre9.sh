#!/bin/bash
# box: pre9.sh — a current `just` (apt's cannot parse the justfile), then the reference head c2152084's binaries in
# /root/bin/base: midout_bench (repository release profile, cubecl-cuda,midout-bench) and the card-tier test binary
# t_box (cubecl-cuda,cubecl-spirv,midout-box-tests; LTO off). Target dir /root/t/base.
source ~/.cargo/env; L=/root/logs/pre; mkdir -p $L /root/bin/base; rm -f $L/done
curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to /usr/local/bin > $L/just.log 2>&1; echo "just rc=$? $(/usr/local/bin/just --version)" >> $L/rc.txt
cd /root/base; git log --oneline -1 > $L/head.txt
CARGO_TARGET_DIR=/root/t/base cargo build --release -p nice_common --features cubecl-cuda,midout-bench --example midout_bench > $L/b_bench.log 2>&1; echo "bench rc=$?" >> $L/rc.txt
cp /root/t/base/release/examples/midout_bench /root/bin/base/
CARGO_TARGET_DIR=/root/t/base CARGO_PROFILE_RELEASE_LTO=false CARGO_PROFILE_RELEASE_CODEGEN_UNITS=16 cargo test --release -p nice_common --features cubecl-cuda,cubecl-spirv,midout-box-tests --lib --no-run > $L/b_tbox.log 2>&1; echo "t_box rc=$?" >> $L/rc.txt
cp $(grep -oP "Executable unittests src/lib.rs \(\K[^)]*" $L/b_tbox.log | tail -1) /root/bin/base/t_box
md5sum /root/bin/base/* >> $L/rc.txt; echo done > $L/done
