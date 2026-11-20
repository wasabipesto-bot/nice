#!/bin/bash
# box: bdp.sh SRC TAG — tree /root/SRC test binary for SPIR-V dumps (cubecl-spirv,cubecl/spirv-dump,midout-box-tests;
# LTO off) into /root/bin/TAG/t_dp, target /root/t/SRCdp
source ~/.cargo/env; L=/root/logs/dp_$2; mkdir -p $L /root/bin/$2; cd /root/$1; git log --oneline -1 > $L/head.txt; git status --short >> $L/head.txt
CARGO_TARGET_DIR=/root/t/$1dp CARGO_PROFILE_RELEASE_LTO=false CARGO_PROFILE_RELEASE_CODEGEN_UNITS=16 cargo test --release -p nice_common --features cubecl-spirv,cubecl/spirv-dump,midout-box-tests --lib --no-run > $L/b.log 2>&1; echo "rc=$?" >> $L/rc.txt
cp $(grep -oP "Executable unittests src/lib.rs \(\K[^)]*" $L/b.log | tail -1) /root/bin/$2/t_dp; md5sum /root/bin/$2/t_dp >> $L/rc.txt; echo done > $L/done
