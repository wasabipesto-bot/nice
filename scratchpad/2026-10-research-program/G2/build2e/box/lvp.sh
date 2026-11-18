#!/bin/bash
# lavapipe (SPIR-V through wgpu), W 8: the wide path against the CPU reference
cd /root/mo/nice/common
T=/root/mo/t-spirv/release/build/nice_common/394c88e9c300f4f8/out/nice_common-394c88e9c300f4f8
L=/root/mo/logs/lvp
mkdir -p $L
md5sum $T > $L/bin_md5.txt
vulkaninfo --summary 2>&1 | grep -iE "deviceName|driverName|driverInfo" > $L/vulkan.txt
run() { # name classes cases
  echo "$(date -u +%FT%TZ) start $1" >> $L/runs.log
  MIDOUT_CLASSES=$2 MIDOUT_WIDE_CASES=$3 RUST_LOG=warn $T --ignored --nocapture midout::gpu_wide::tests::wide_slices_equal_cpu > $L/$1.log 2>&1
  echo "$(date -u +%FT%TZ) end $1 rc=$?" >> $L/runs.log
}
run small 8 30:2:5:100,30:1:5:5000,40:3:6:1234,40:2:6:7
run b50 8 50:4:8:77777
run b64 4 64:4:10:712012851
run b65 2 65:4:10:717171717
run b65s 2 65:4:10:532260419
