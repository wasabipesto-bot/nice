#!/bin/bash
# box: pieces 2 (parent sharing) and 3 (wide prefilter in base b^2): exactness on CUDA and lavapipe W 8; $1 bin tag, $2 log dir
set -u
T=/root/m5wbin/$1/tests; L=$2; mkdir -p $L; source /root/mo/guard.sh $L || exit 1
md5sum $T > $L/bin.txt
run() { n=$1; shift; echo "$(date -u +%FT%TZ) start $n" >> $L/runs.log; env "$@" RUST_LOG=warn timeout 3000 $T --ignored --exact --nocapture $TEST > $L/$n.log 2>&1; rc=$?; echo "$(date -u +%FT%TZ) end $n rc=$rc" >> $L/runs.log; }
G=midout::gpu::tests; A=midout::gpu::audit; W=midout::gpu_wide::tests
TEST=$G::field_parent_sharing_is_exact_and_loud run share_faults_cuda MIDOUT_CUDA=1
TEST=$G::gpu_slices_equal_cpu run share_parity_cuda MIDOUT_CUDA=1 MIDOUT_SHARE8=1 MIDOUT_GPU_SLICES=712012851,318575442,4977728,1073741823
TEST=$W::wide_slices_equal_cpu run wide_slices_cuda MIDOUT_CUDA=1 MIDOUT_WIDE_CASES=30:2:5:100,40:3:6:1234,50:4:8:77777,64:4:10:712012851,65:4:10:717171717,65:4:10:532260419,65:4:10:1160290624
TEST=$W::wide_whole_small_bases_vs_brute_force run wide_brute_cuda MIDOUT_CUDA=1
TEST=$G::gpu_slices_equal_cpu run share_parity_lvp MIDOUT_SHARE8=1 MIDOUT_CLASSES=4 MIDOUT_GPU_SLICES=712012851
TEST=$W::wide_slices_equal_cpu run wide_slices_lvp MIDOUT_CLASSES=4 MIDOUT_WIDE_CASES=40:3:6:1234,65:4:10:717171717
TEST=$W::wide_faults_are_loud run wide_faults_cuda MIDOUT_CUDA=1
TEST=$A::accounts_faults_are_loud run faults_cuda MIDOUT_CUDA=1
echo done > $L/done
