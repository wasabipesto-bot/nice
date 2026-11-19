#!/bin/bash
# build test binary + both benches for the tree in /root/midout; $1 = log dir
cd /root/midout/common; source ~/.cargo/env
L=$1; mkdir -p $L
export CARGO_TARGET_DIR=/root/t/mo
git -C /root/midout log --oneline -1 > $L/head.txt; git -C /root/midout status --short >> $L/head.txt
cargo build --offline --release -p nice_common --features cubecl-cuda,cubecl-spirv --example midout_bench --example midout_wide_bench > $L/build_bench.log 2>&1; echo "rc=$?" >> $L/build_bench.log
cargo test --offline --release -p nice_common --features cubecl-cuda,cubecl-spirv --lib --no-run > $L/build_tests.log 2>&1; echo "rc=$?" >> $L/build_tests.log
T=$(grep -o "/root/t/mo/release/deps/nice_common-[0-9a-f]*" $L/build_tests.log | tail -1)
[ -z "$T" ] && T=$(grep -o "/root/t/mo/release/[^)]*nice_common[^)]*" $L/build_tests.log | tail -1)
echo "$T" > $L/testbin.txt
md5sum $T /root/t/mo/release/examples/midout_bench /root/t/mo/release/examples/midout_wide_bench > $L/bins.txt
echo done > $L/build_done
