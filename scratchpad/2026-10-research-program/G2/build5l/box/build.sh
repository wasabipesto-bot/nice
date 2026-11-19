#!/bin/bash
# box: build the test binary (CUDA + SPIR-V) and the benches of /root/m5 into /root/t/m5; $1 = log dir; copies to /root/m5bin/$2
source ~/.cargo/env; cd /root/m5; export CARGO_TARGET_DIR=/root/t/m5; L=$1; T=$2; mkdir -p $L /root/m5bin/$T
git log --oneline -1 > $L/head.txt; git status --short >> $L/head.txt; git diff HEAD | md5sum >> $L/head.txt
cargo test --release -p nice_common --features cubecl-cuda,cubecl-spirv --lib --no-run > $L/build_tests.log 2>&1; echo rc=$? >> $L/build_tests.log
X=$(grep -o "/root/t/m5/release/[^)]*nice_common-[0-9a-f]*" $L/build_tests.log | tail -1); cp $X /root/m5bin/$T/tests
cargo build --release -p nice_common --features cubecl-cuda --example midout_bench --example midout_wide_bench > $L/build_ex.log 2>&1; echo rc=$? >> $L/build_ex.log
cp /root/t/m5/release/examples/midout_bench /root/t/m5/release/examples/midout_wide_bench /root/m5bin/$T/
md5sum /root/m5bin/$T/* > $L/bins.txt
echo done > $L/done
