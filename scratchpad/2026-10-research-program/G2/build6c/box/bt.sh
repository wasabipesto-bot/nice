#!/bin/bash
# box: bt.sh SRC TAG — build nice_common's lib test binaries of tree /root/SRC into /root/t/SRC (one target dir per tree):
# "sc" = cubecl-cuda,cubecl-spirv (CUDA + direct SPIR-V), "wg" = cubecl (WGSL via naga), copied to /root/bin/TAG/.
# Host-side LTO off (kernels are compiled at run time from CubeCL IR, so the device code does not depend on it).
source ~/.cargo/env; cd /root/$1; export CARGO_TARGET_DIR=/root/t/$1 CARGO_PROFILE_RELEASE_LTO=false CARGO_PROFILE_RELEASE_CODEGEN_UNITS=16
L=/root/logs/$2; mkdir -p $L /root/bin/$2; rm -f $L/done
git log --oneline -1 > $L/head.txt; git status --short >> $L/head.txt
for f in ${BT_SETS:-sc:cubecl-cuda,cubecl-spirv wg:cubecl}; do
  k=${f%%:*}; F=${f#*:}
  cargo test --release -p nice_common --features $F --lib --no-run > $L/build_$k.log 2>&1; echo rc=$? >> $L/build_$k.log
  X=$(grep -oP "Executable unittests src/lib.rs \(\K[^)]*" $L/build_$k.log | tail -1); cp $X /root/bin/$2/t_$k
done
md5sum /root/bin/$2/* >> $L/bins.txt; echo done > $L/done
