#!/bin/bash
# box: the fixed share test, the b65 lavapipe parity, then the measurements of pieces 2 and 3 (nothing else running)
set -u
T=/root/m5wbin/p23b/tests; L=/root/l5/p23b/tests; mkdir -p $L; source /root/mo/guard.sh $L || exit 1
md5sum $T > $L/bin.txt
run() { n=$1; shift; echo "$(date -u +%FT%TZ) start $n" >> $L/runs.log; env "$@" RUST_LOG=warn timeout 3000 $T --ignored --exact --nocapture $TEST > $L/$n.log 2>&1; rc=$?; echo "$(date -u +%FT%TZ) end $n rc=$rc" >> $L/runs.log; }
TEST=midout::gpu::tests::field_parent_sharing_is_exact_and_loud run share_faults_cuda MIDOUT_CUDA=1
TEST=midout::gpu_wide::tests::wide_slices_equal_cpu run wide_b65_lvp MIDOUT_CLASSES=2 MIDOUT_WIDE_CASES=65:4:10:717171717
/root/m2.sh p23b /root/l5/m2
/root/m3.sh p23b /root/l5/m3
echo done > $L/done
