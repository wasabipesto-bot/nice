#!/bin/bash
# box: quick.sh TAG — per-commit check of /root/mc: `just lint`, clippy of nice_common with the middle-out feature
# sets (in no CI set), tier (a) (nice_common lib, CUDA + SPIR-V features, release, 4 threads) and the client's tests
# with CubeCL (the route's tests). Target dir /root/t/mc. Output /root/runs/TAG.
source ~/.cargo/env; cd /root/mc; export CARGO_TARGET_DIR=/root/t/mc; O=/root/runs/$1; mkdir -p $O; rm -f $O/done $O/rc.txt
git log --oneline -1 > $O/head.txt; git status --short >> $O/head.txt
t() { n=$1; shift; s0=$(date +%s); "$@" > $O/$n.txt 2>&1; echo "$n rc=$? $(( $(date +%s) - s0 )) s" >> $O/rc.txt; }
t just_lint /usr/local/bin/just lint
for f in cubecl-cuda,cubecl-spirv,midout-bench,midout-box-tests cubecl,midout-box-tests cubecl-spirv; do
  t clippy_$f cargo clippy -p nice_common --all-targets --features $f -- -D warnings
done
export CARGO_PROFILE_RELEASE_LTO=false CARGO_PROFILE_RELEASE_CODEGEN_UNITS=16
t tier_a cargo test --release -p nice_common --features cubecl-cuda,cubecl-spirv --lib -- --test-threads 4
t client_cubecl cargo test --release -p nice_client --features cubecl-cuda
echo done > $O/done
