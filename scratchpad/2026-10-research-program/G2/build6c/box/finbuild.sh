#!/bin/bash
# box: finbuild.sh — the final binaries, with the repository's release profile (benches) or the tests' (LTO off):
#   /root/bin/fin: the head's card-tier test binary (cubecl-cuda,cubecl-spirv,midout-box-tests), its midout_bench
#   (cubecl-cuda,midout-bench) and its client (default features, for --help); /root/bin/trunkb: the trunk's midout_bench.
source ~/.cargo/env; L=/root/logs/fin; mkdir -p $L /root/bin/fin /root/bin/trunkb; rm -f $L/done
cd /root/mc; git log --oneline -1 > $L/head.txt; git status --short >> $L/head.txt
CARGO_TARGET_DIR=/root/t/mc CARGO_PROFILE_RELEASE_LTO=false CARGO_PROFILE_RELEASE_CODEGEN_UNITS=16 cargo test --release -p nice_common --features cubecl-cuda,cubecl-spirv,midout-box-tests --lib --no-run > $L/b_tests.log 2>&1; echo "tests rc=$?" >> $L/rc.txt
cp $(grep -oP "Executable unittests src/lib.rs \(\K[^)]*" $L/b_tests.log | tail -1) /root/bin/fin/t_box
CARGO_TARGET_DIR=/root/t/mcb cargo build --release -p nice_common --features cubecl-cuda,midout-bench --example midout_bench > $L/b_bench.log 2>&1; echo "bench rc=$?" >> $L/rc.txt
cp /root/t/mcb/release/examples/midout_bench /root/bin/fin/
CARGO_TARGET_DIR=/root/t/mcb cargo build --release -p nice_client > $L/b_client.log 2>&1; echo "client rc=$?" >> $L/rc.txt
cp /root/t/mcb/release/nice_client /root/bin/fin/
cd /root/trunk; git log --oneline -1 > $L/trunk_head.txt
CARGO_TARGET_DIR=/root/t/trunkb cargo build --release -p nice_common --features cubecl-cuda --example midout_bench > $L/b_trunk.log 2>&1; echo "trunk bench rc=$?" >> $L/rc.txt
cp /root/t/trunkb/release/examples/midout_bench /root/bin/trunkb/
md5sum /root/bin/fin/* /root/bin/trunkb/* > $L/bins.txt; echo done > $L/done
