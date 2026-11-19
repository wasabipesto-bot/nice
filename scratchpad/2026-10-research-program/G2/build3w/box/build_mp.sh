#!/bin/bash
# build test binary + both benches for the tree in /root/mp; $1 = log dir
cd /root/mp/common; source ~/.cargo/env
L=$1; mkdir -p $L
export CARGO_TARGET_DIR=/root/t/mp
git -C /root/mp log --oneline -1 > $L/head.txt; git -C /root/mp status --short >> $L/head.txt
cargo build --offline --release -p nice_common --features cubecl-cuda,cubecl-spirv --example midout_bench --example midout_wide_bench > $L/build_bench.log 2>&1; echo "rc=$?" >> $L/build_bench.log
cargo test --offline --release -p nice_common --features cubecl-cuda,cubecl-spirv --lib --no-run > $L/build_tests.log 2>&1; echo "rc=$?" >> $L/build_tests.log
T=$(grep -o "/root/t/mp/release/deps/nice_common-[0-9a-f]*" $L/build_tests.log | tail -1)
[ -z "$T" ] && T=$(grep -o "/root/t/mp/release/[^)]*nice_common[^)]*" $L/build_tests.log | tail -1)
echo "$T" > $L/testbin.txt
md5sum $T /root/t/mp/release/examples/midout_bench /root/t/mp/release/examples/midout_wide_bench > $L/bins.txt
echo done > $L/build_done
