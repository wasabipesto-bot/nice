#!/bin/bash
# box: piece 1's tests on the test binary /root/m5bin/$1/tests; logs in $2
set -u
T=/root/m5bin/$1/tests; L=$2; mkdir -p $L
grep -c nicenumbers /etc/hosts > $L/hosts_check.txt; getent hosts api.nicenumbers.net >> $L/hosts_check.txt
md5sum $T > $L/bin.txt
run() { n=$1; shift; echo "$(date -u +%FT%TZ) start $n" >> $L/runs.log; env "$@" RUST_LOG=warn timeout 3000 $T $ARGS > $L/$n.log 2>&1; rc=$?; echo "$(date -u +%FT%TZ) end $n rc=$rc" >> $L/runs.log; }
ARGS="midout::coord midout::cpu::tests::coordinate_485_is_whole_slices midout::cpu::tests::shapes_that_do_not_fit midout::cpu::tests::whole_small_bases_vs_brute_force" run cpu_tests X=1
ARGS="--ignored --exact --nocapture midout::gpu::tests::field_485_equals_496_slice_by_slice" run field485_cuda MIDOUT_CUDA=1
ARGS="--ignored --exact --nocapture midout::gpu::tests::gpu_slices_equal_cpu" run parity485_cuda MIDOUT_CUDA=1 MIDOUT_GPU_SLICES=4977728,1061942399,223081541
ARGS="--ignored --exact --nocapture midout::gpu_wide::tests::wide_field_485_equals_496_slice_by_slice" run wfield485_cuda MIDOUT_CUDA=1
echo done > $L/done
