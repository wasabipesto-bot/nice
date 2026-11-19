#!/bin/bash
# step 3A verification chain at the head: CUDA acceptance, reproductions, timing, sweep subset, lavapipe
cd /root/midout/common; source ~/.cargo/env
L=/root/b3/final; mkdir -p $L
grep -q "127.0.0.1 api.nicenumbers.net" /etc/hosts || { echo "ABORT: hosts block missing" > $L/ABORT; exit 1; }
grep -E "nicenumbers" /etc/hosts > $L/hosts_block.txt
git -C /root/midout log --oneline -1 > $L/head.txt; git -C /root/midout status --short >> $L/head.txt
export CARGO_TARGET_DIR=/root/t/mo
cargo build --offline --release -p nice_common --features cubecl-cuda,cubecl-spirv --example midout_bench > $L/build_bench.log 2>&1
cp /root/t/mo/release/examples/midout_bench /root/b3/mo_bench_final
cargo test --offline --release -p nice_common --features cubecl-cuda,cubecl-spirv --lib --no-run > $L/build_tests.log 2>&1
T=$(grep -o "/root/t/mo/release/build/nice_common/[^)]*" $L/build_tests.log | tail -1)
md5sum $T /root/b3/mo_bench_final /root/mo/mo_bench_head > $L/bins.txt
run() { n=$1; shift; echo "$(date -u +%FT%TZ) start $n" >> $L/runs.log; env "$@" RUST_LOG=warn timeout 3000 $T --ignored --exact --nocapture ${TEST} > $L/$n.log 2>&1; echo "$(date -u +%FT%TZ) end $n rc=$?" >> $L/runs.log; }
TEST=midout::gpu::audit::accounts_faults_are_loud run faults_cuda MIDOUT_CUDA=1
TEST=midout::gpu::audit::accounts_faults_are_loud run faults_cuda_b MIDOUT_CUDA=1 AUDIT_SLICES=806726610,712012851,1073741823
TEST=midout::gpu::tests::gpu_slices_equal_cpu run parity_cuda MIDOUT_CUDA=1 MIDOUT_GPU_SLICES=712012851,318575442,391856203,1,1073741823
TEST=midout::gpu::tests::gpu_slices_equal_cpu run parity_cuda_hosttops MIDOUT_CUDA=1 MIDOUT_HOST_TOPS=1 MIDOUT_GPU_SLICES=712012851
TEST=midout::gpu::tests::gpu_slices_equal_cpu run parity_cuda_part MIDOUT_CUDA=1 MIDOUT_CLASSES=4 MIDOUT_BATCHES=3 MIDOUT_GPU_SLICES=712012851
TEST=midout::gpu::tests::gpu_check_rebuilds_the_survivors run probe_cuda MIDOUT_CUDA=1
TEST=midout::gpu::audit::audit_stop_env_is_loud run stop_env MIDOUT_CUDA=1
TEST=midout::gpu::audit::audit_oom_is_loud run oom_inproc_9216 MIDOUT_CUDA=1 AUDIT_FILL_MB=9216
(MIDOUT_CUDA=1 AUDIT_FILL_MB=7680 AUDIT_HOLD_S=45 RUST_LOG=warn timeout 120 $T --ignored --exact --nocapture midout::gpu::audit::audit_oom_is_loud > $L/oom_holder_7680.log 2>&1 &)
sleep 12; nvidia-smi --query-gpu=memory.used --format=csv,noheader > $L/oom_helper_mem.txt
TEST=midout::gpu::audit::audit_oom_is_loud run oom_helper_7680 MIDOUT_CUDA=1
sleep 40
# timing: the 10 fields, before (91ac0761) and after (head), cpu check on and off
F10=13107,39321,65536,91750,117964,144179,170393,196607,222822,249036
nvidia-smi --query-gpu=timestamp,power.draw,clocks.sm,utilization.gpu,temperature.gpu --format=csv,noheader -l 5 > $L/smi_ten.csv &
MP=$!
echo "$(date -u +%FT%TZ) start ten_before" >> $L/runs.log; /root/mo/mo_bench_head --cuda --group 16 --fields $F10 > $L/ten_before.log 2>&1
echo "$(date -u +%FT%TZ) start ten_after_check" >> $L/runs.log; /root/b3/mo_bench_final --cuda --group 16 --fields $F10 > $L/ten_after_check.log 2>&1
echo "$(date -u +%FT%TZ) start ten_after_nocheck" >> $L/runs.log; /root/b3/mo_bench_final --cuda --group 16 --fields $F10 --no-cpu-check > $L/ten_after_nocheck.log 2>&1
echo "$(date -u +%FT%TZ) end ten" >> $L/runs.log
kill $MP
# the sweep, 100 slices (the first 100 of the audit list: 72 extremes and range ends, 28 seeded)
S100=$(tr "," "\n" < /root/audit/sweep_slices.txt | head -100 | paste -sd,)
TEST=midout::gpu::audit::audit_sweep run sweep100 MIDOUT_CUDA=1 AUDIT_SLICES=$S100 AUDIT_THREADS=5 AUDIT_OUT=$L/sweep100.jsonl
# lavapipe W 8 through SPIR-V, 4 classes per batch
export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/lvp_icd.json
vulkaninfo --summary 2>&1 | grep -iE "deviceName|driverName|driverInfo|subgroup" > $L/vulkan.txt
TEST=midout::gpu::audit::accounts_faults_are_loud run lvp_faults MIDOUT_CLASSES=4 AUDIT_SLICES=712012851 AUDIT_AGAIN=0
TEST=midout::gpu::tests::gpu_slices_equal_cpu run lvp_parity MIDOUT_CLASSES=4 MIDOUT_GPU_SLICES=712012851,318575442
unset VK_ICD_FILENAMES
echo done > $L/chain_done
