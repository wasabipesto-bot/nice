#!/bin/bash
# FD branch: wait for the build, rebuild client + harness at the synced source,
# then the CUDA exactness tests and the lib suite.
source /root/.cargo/env
cd /root/fd
while ! grep -q BUILD_DONE /root/logs/build_fd.log; do sleep 10; done
{ date -u; md5sum common/src/cubecl_detailed_fd.rs common/src/cubecl_backend.rs
  cargo build --release -p nice_client --features gpu 2>&1 | tail -n 2
  cargo build --release -p nice_common --features gpu --example fdbench 2>&1 | tail -n 2
  T=$(ls -t target/release/deps/nice_common-* | grep -v "\.d$" | head -n 1); echo "test binary $T"
  cargo test --release -p nice_common --features gpu --no-run 2>&1 | grep Executable
  T=$(cargo test --release -p nice_common --features gpu --no-run 2>&1 | grep "unittests src/lib.rs" | sed "s/.*(\(.*\))/\1/"); echo "T=$T"
  echo "== lib suite"; date -u
  $T 2>&1 | tail -n 5
  echo "== CUDA"; date -u
  NICE_API_BASE=http://127.0.0.1:9 $T --ignored --nocapture --test-threads 1 cubecl_cuda_fd_matches_cpu_detailed cubecl_cuda_matches_cpu_detailed cubecl_cuda_reads_back_every_near_miss 2>&1
  date -u; echo FDTESTS_DONE; } > /root/logs/tests_fd.log 2>&1
