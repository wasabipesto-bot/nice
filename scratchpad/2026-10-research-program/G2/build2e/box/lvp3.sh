#!/bin/bash
# lavapipe (SPIR-V through wgpu) W 8 on the final code: whole small bases vs brute force, slices vs the CPU reference
cd /root/mo/nice/common
T=/root/mo/t-spirv/release/build/nice_common/394c88e9c300f4f8/out/nice_common-394c88e9c300f4f8
L=/root/mo/logs/lvp3
mkdir -p $L
md5sum $T > $L/bin_md5.txt
vulkaninfo --summary 2>&1 | grep -iE "deviceName|driverName|driverInfo" > $L/vulkan.txt
run() { # name test env...
  n=$1; t=$2; shift 2
  echo "$(date -u +%FT%TZ) start $n" >> $L/runs.log
  env "$@" RUST_LOG=warn $T --ignored --nocapture midout::gpu_wide::tests::$t > $L/$n.log 2>&1
  echo "$(date -u +%FT%TZ) end $n rc=$?" >> $L/runs.log
}
run brute wide_whole_small MIDOUT_CLASSES=2 MIDOUT_MAX_SLICES=700
run small wide_slices_equal_cpu MIDOUT_CLASSES=2 MIDOUT_WIDE_CASES=30:2:5:100,30:1:5:5000,40:3:6:1234,40:2:6:7,50:4:8:77777
run b64 wide_slices_equal_cpu MIDOUT_CLASSES=4 MIDOUT_WIDE_CASES=64:4:10:712012851
run b65 wide_slices_equal_cpu MIDOUT_CLASSES=2 MIDOUT_WIDE_CASES=65:4:10:717171717,65:4:10:532260419
