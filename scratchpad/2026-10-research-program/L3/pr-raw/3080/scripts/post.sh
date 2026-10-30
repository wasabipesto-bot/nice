#!/bin/bash
# After the protocol: what limits the clock under each kernel; lavapipe (naga
# WGSL and CubeCL SPIR-V) for the FD tree; WGSL dump for an offline MSL check.
source /root/.cargo/env
export NICE_API_BASE=http://127.0.0.1:9
L=/root/logs/post; mkdir -p $L
T=target/release/deps/nice_common-c0034331d0049e16
LVP=/usr/share/vulkan/icd.d/lvp_icd.json

# 1. Clock-event reasons mid-run, b50 1e10 windows.
for t in main rb fd; do
  cd /root/$t
  nvidia-smi dmon -s pc -d 1 -o T > $L/perf_dmon_$t.txt 2>&1 &
  M=$!
  ./target/release/examples/fdbench 50 1e10 40 > $L/perf_run_$t.txt 2>&1 &
  P=$!
  sleep 8
  nvidia-smi -q -d PERFORMANCE,POWER,CLOCK > $L/perf_$t.txt 2>&1
  wait $P
  kill $M
done
echo PERF_DONE > $L/status

# 2. lavapipe, naga/WGSL path (the gpu test binary's default wgpu runtime).
cd /root/fd
/root/lvp.sh fd $T cubecl_detailed_fd::tests::cubecl_fd_matches_cpu_detailed cubecl_backend::tests::cubecl_reads_back_every_near_miss
/root/lvp.sh rb $T cubecl_backend::tests::cubecl_reads_back_every_near_miss
echo LVP_DONE >> $L/status

# 3. WGSL dump of the FD kernels (b10, b40, b62) for the MSL translation check.
cd /root/fd
VK_ICD_FILENAMES=$LVP CUBECL_DEBUG_LOG=$L/cubecl_wgsl_fd.log $T --ignored --nocapture --test-threads 1 cubecl_backend::tests::cubecl_matches_cpu_detailed > $L/wgsl_dump_run.txt 2>&1
echo DUMP_DONE >> $L/status

# 4. CubeCL's SPIR-V compiler (the -gpu docker image's Vulkan path).
cd /root/fd
{ date -u; cargo test --release -p nice_common --features cubecl-spirv --no-run 2>&1 | grep -E "Executable|error|Finished"; date -u; } > $L/spirv_build.txt 2>&1
TS=$(grep "unittests src/lib.rs" $L/spirv_build.txt | sed "s/.*(\(.*\))/\1/")
echo "TS=$TS" >> $L/spirv_build.txt
{ date -u; VK_ICD_FILENAMES=$LVP $TS --ignored --nocapture --test-threads 1 cubecl_detailed_fd::tests::cubecl_fd_matches_cpu_detailed cubecl_backend::tests::cubecl_reads_back_every_near_miss cubecl_backend::tests::cubecl_matches_cpu_detailed cubecl_backend::tests::cubecl_finds_69_in_base_10 cubecl_web::tests::web_kernel_near_miss_matches_cpu_at_base_49 2>&1
  date -u; echo "== NICE_CUBECL_WIDE=1 (u64 seed division on SPIR-V)"
  NICE_CUBECL_WIDE=1 VK_ICD_FILENAMES=$LVP $TS --ignored --nocapture --test-threads 1 cubecl_detailed_fd::tests::cubecl_fd_matches_cpu_detailed cubecl_backend::tests::cubecl_matches_cpu_detailed 2>&1
  date -u; } > $L/lvp_spirv_fd.txt 2>&1
echo SPIRV_DONE >> $L/status
