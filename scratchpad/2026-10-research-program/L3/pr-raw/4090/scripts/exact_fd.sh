#!/bin/bash
# FD-tree exactness on the 4090: every test whose path contains "fd" (normal + ignored, CUDA),
# the existing CubeCL CUDA parity test, the readback test, then the wgpu FD test with a timeout.
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH
O=/root/runs/exact_fd; mkdir -p $O
T=/root/t_fd/release/deps/nice_common-c0034331d0049e16
cd /root/fd
git rev-parse HEAD > $O/head.txt; md5sum common/src/cubecl_backend.rs common/src/cubecl_detailed_fd.rs >> $O/head.txt
$T --list 2>/dev/null | grep fd > $O/list_normal.txt
$T --list --ignored 2>/dev/null | grep fd > $O/list_ignored.txt
$T fd --nocapture --test-threads 4 > $O/fd_normal.log 2>&1
$T cubecl_detailed_fd::tests::cubecl_cuda_fd_matches_cpu_detailed --ignored --exact --nocapture --test-threads 1 > $O/fd_cuda.log 2>&1
$T cubecl_backend::tests::cubecl_cuda_matches_cpu_detailed --ignored --exact --nocapture --test-threads 1 > $O/parity_cuda.log 2>&1
$T cubecl_backend::tests::cubecl_cuda_reads_back_every_near_miss --ignored --exact --nocapture --test-threads 1 > $O/readback_cuda.log 2>&1
WGPU_BACKEND=vulkan RUST_LOG=info timeout 900 $T cubecl_detailed_fd::tests::cubecl_fd_matches_cpu_detailed --ignored --exact --nocapture --test-threads 1 > $O/fd_wgpu.log 2>&1
echo "wgpu exit $?" >> $O/fd_wgpu.log
echo done > $O/done
