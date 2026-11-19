#!/bin/bash
# the trunk's device work at the merged head on CUDA: ten-field b64 timing through the library, parity and fault tests; $1 = log dir
set -u
source ~/.cargo/env; cd /root/mc; export CARGO_TARGET_DIR=/root/t/mc; L=$1; mkdir -p $L
source /root/mo/guard.sh $L
git log --oneline -1 > $L/head.txt; git status --short >> $L/head.txt
cargo build --release -p nice_common --features cubecl-cuda --example midout_bench > $L/build_bench.log 2>&1; echo rc=$? >> $L/build_bench.log
cp /root/t/mc/release/examples/midout_bench /root/mo/bin/mo_bench_merged
cargo test --release -p nice_common --features cubecl-cuda --lib --no-run > $L/build_tests.log 2>&1; echo rc=$? >> $L/build_tests.log
T=$(grep -o "/root/t/mc/release/[^)]*nice_common-[0-9a-f]*" $L/build_tests.log | tail -1); cp $T /root/mo/bin/nc_tests_merged; T=/root/mo/bin/nc_tests_merged
md5sum $T /root/mo/bin/mo_bench_merged > $L/bins.txt
F10=13107,39321,65536,91750,117964,144179,170393,196607,222822,249036
nvidia-smi --query-gpu=timestamp,power.draw,clocks.sm,utilization.gpu,temperature.gpu --format=csv,noheader -l 5 > $L/smi_ten.csv & MP=$!
echo "$(date -u +%FT%TZ) start ten_check" >> $L/runs.log; /root/mo/bin/mo_bench_merged --cuda --group 16 --fields $F10 > $L/ten_check.log 2>&1
echo "$(date -u +%FT%TZ) start ten_nocheck" >> $L/runs.log; /root/mo/bin/mo_bench_merged --cuda --group 16 --fields $F10 --no-cpu-check > $L/ten_nocheck.log 2>&1
echo "$(date -u +%FT%TZ) end ten" >> $L/runs.log; kill $MP
A=midout::gpu::audit; G=midout::gpu::tests; W=midout::gpu_wide::tests
run() { n=$1; shift; echo "$(date -u +%FT%TZ) start $n" >> $L/runs.log; env "$@" RUST_LOG=warn timeout 3000 $T --ignored --exact --nocapture ${TEST} > $L/$n.log 2>&1; echo "$(date -u +%FT%TZ) end $n rc=$?" >> $L/runs.log; }
TEST=$G::gpu_slices_equal_cpu run parity_cuda MIDOUT_CUDA=1 MIDOUT_GPU_SLICES=712012851,318575442,391856203,1,1073741823
TEST=$A::accounts_faults_are_loud run faults_cuda MIDOUT_CUDA=1
TEST=$A::accounts_faults_are_loud run faults_cuda_b MIDOUT_CUDA=1 AUDIT_SLICES=806726610,712012851,1073741823
TEST=$W::wide_slices_equal_cpu run wide_slices MIDOUT_CUDA=1 MIDOUT_WIDE_CASES=30:2:5:100,40:3:6:1234,50:4:8:77777,64:4:10:712012851,65:4:10:717171717,65:4:10:532260419,65:4:10:1160290624
TEST=$W::wide_faults_are_loud run wfaults_b65 MIDOUT_CUDA=1
TEST=$G::gpu_check_rebuilds_the_survivors run probe_cuda MIDOUT_CUDA=1
TEST=$A::audit_stop_env_is_loud run stop_env MIDOUT_CUDA=1
TEST=$A::audit_oom_is_loud run oom_inproc_9216 MIDOUT_CUDA=1 AUDIT_FILL_MB=9216
echo done > $L/done
