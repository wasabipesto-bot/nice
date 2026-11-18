#!/bin/bash
# lavapipe W 8, the small bases again with 2 classes per batch (wgpu's 128 MiB binding limit)
cd /root/mo/nice/common
T=/root/mo/t-spirv/release/build/nice_common/394c88e9c300f4f8/out/nice_common-394c88e9c300f4f8
L=/root/mo/logs/lvp
while pgrep -x lvp.sh > /dev/null || pgrep -f "bash lvp.s[h]" > /dev/null; do sleep 10; done
run() {
  echo "$(date -u +%FT%TZ) start $1" >> $L/runs.log
  MIDOUT_CLASSES=$2 MIDOUT_WIDE_CASES=$3 RUST_LOG=warn $T --ignored --nocapture midout::gpu_wide::tests::wide_slices_equal_cpu > $L/$1.log 2>&1
  echo "$(date -u +%FT%TZ) end $1 rc=$?" >> $L/runs.log
}
run small2 2 30:2:5:100,30:1:5:5000,40:3:6:1234,40:2:6:7
run b50c2 2 50:4:8:77777
