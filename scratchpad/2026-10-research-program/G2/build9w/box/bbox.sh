#!/bin/bash
# box: bbox.sh TAG — /root/mc's card-tier test binary t_box (cubecl-cuda,cubecl-spirv,midout-box-tests; LTO off)
# and its two benches (cubecl-cuda,midout-bench; the repository's release profile) into /root/bin/TAG. Target dirs
# /root/t/mc (tests) and /root/t/mcb (benches).
source ~/.cargo/env; L=/root/logs/$1; mkdir -p $L /root/bin/$1; rm -f $L/done $L/rc.txt
cd /root/mc; git log --oneline -1 > $L/head.txt; git status --short >> $L/head.txt; git diff | md5sum >> $L/head.txt
CARGO_TARGET_DIR=/root/t/mc CARGO_PROFILE_RELEASE_LTO=false CARGO_PROFILE_RELEASE_CODEGEN_UNITS=16 cargo test --release -p nice_common --features cubecl-cuda,cubecl-spirv,midout-box-tests --lib --no-run > $L/b_tbox.log 2>&1; echo "t_box rc=$?" >> $L/rc.txt
cp $(grep -oP "Executable unittests src/lib.rs \(\K[^)]*" $L/b_tbox.log | tail -1) /root/bin/$1/t_box
if [ -z "$NOBENCH" ]; then
CARGO_TARGET_DIR=/root/t/mcb cargo build --release -p nice_common --features cubecl-cuda,midout-bench --example midout_bench --example midout_wide_bench > $L/b_bench.log 2>&1; echo "bench rc=$?" >> $L/rc.txt
cp /root/t/mcb/release/examples/midout_bench /root/t/mcb/release/examples/midout_wide_bench /root/bin/$1/
fi
md5sum /root/bin/$1/* >> $L/rc.txt; echo done > $L/done
