#!/bin/bash
# box: finbuild.sh — the binaries for the head's verification. /root/bin/fin: the head's card-tier test binary
# t_box (cubecl-cuda,cubecl-spirv,midout-box-tests; tests' profile, LTO off), its midout_bench (cubecl-cuda,
# midout-bench; the repository's release profile) and its client (default features, for --help).
# /root/bin/base5a/t_box: the same test binary of 5a048669 (for the kernel-source comparison).
source ~/.cargo/env; L=/root/logs/fin; mkdir -p $L /root/bin/fin; rm -f $L/done $L/rc.txt
cd /root/mc; git log --oneline -1 > $L/head.txt; git status --short >> $L/head.txt
bt() { (cd /root/$1; CARGO_TARGET_DIR=/root/t/$1 CARGO_PROFILE_RELEASE_LTO=false CARGO_PROFILE_RELEASE_CODEGEN_UNITS=16 cargo test --release -p nice_common --features cubecl-cuda,cubecl-spirv,midout-box-tests --lib --no-run > $L/b_tbox_$1.log 2>&1; echo "t_box $1 rc=$?" >> $L/rc.txt
  cp $(grep -oP "Executable unittests src/lib.rs \(\K[^)]*" $L/b_tbox_$1.log | tail -1) /root/bin/$2/t_box); }
bt mc fin
CARGO_TARGET_DIR=/root/t/mcb cargo build --release -p nice_common --features cubecl-cuda,midout-bench --example midout_bench > $L/b_bench.log 2>&1; echo "bench rc=$?" >> $L/rc.txt
cp /root/t/mcb/release/examples/midout_bench /root/bin/fin/
CARGO_TARGET_DIR=/root/t/mcb cargo build --release -p nice_client > $L/b_client.log 2>&1; echo "client rc=$?" >> $L/rc.txt
cp /root/t/mcb/release/nice_client /root/bin/fin/
bt base5a base5a
md5sum /root/bin/fin/* /root/bin/base5a/* > $L/bins.txt; echo done > $L/done
