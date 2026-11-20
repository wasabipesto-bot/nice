#!/bin/bash
# box: bb2.sh SRC TAG — tree /root/SRC's card-tier test binary t_box (cubecl-cuda,cubecl-spirv,midout-box-tests; LTO
# off) and its wide bench (cubecl-cuda,midout-bench; the repository's release profile; NOBENCH skips it) into
# /root/bin/TAG. Target dirs /root/t/SRC and /root/t/SRCb.
source ~/.cargo/env; S=$1; L=/root/logs/$2; mkdir -p $L /root/bin/$2; rm -f $L/done $L/rc.txt
cd /root/$S; git log --oneline -1 > $L/head.txt; git status --short >> $L/head.txt; git diff | md5sum >> $L/head.txt
CARGO_TARGET_DIR=/root/t/$S CARGO_PROFILE_RELEASE_LTO=false CARGO_PROFILE_RELEASE_CODEGEN_UNITS=16 cargo test --release -p nice_common --features cubecl-cuda,cubecl-spirv,midout-box-tests --lib --no-run > $L/b_tbox.log 2>&1; echo "t_box rc=$?" >> $L/rc.txt
cp $(grep -oP "Executable unittests src/lib.rs \(\K[^)]*" $L/b_tbox.log | tail -1) /root/bin/$2/t_box
if [ -z "$NOBENCH" ]; then
CARGO_TARGET_DIR=/root/t/${S}b cargo build --release -p nice_common --features cubecl-cuda,midout-bench --example midout_bench --example midout_wide_bench > $L/b_bench.log 2>&1; echo "bench rc=$?" >> $L/rc.txt
cp /root/t/${S}b/release/examples/midout_bench /root/t/${S}b/release/examples/midout_wide_bench /root/bin/$2/
fi
md5sum /root/bin/$2/* >> $L/rc.txt; echo done > $L/done
