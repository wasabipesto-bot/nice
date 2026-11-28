#!/bin/bash
# build.sh NAME: the SPIR-V dump test binary of the mo-aco worktree as it stands -> bins/t_NAME (own target dir, -j 2, nice 19, no LTO: host code only)
cd /home/claude/projects/nice/.worktrees/mo-aco
CARGO_TARGET_DIR=$PWD/target CARGO_PROFILE_RELEASE_LTO=false CARGO_PROFILE_RELEASE_CODEGEN_UNITS=16 nice -n 19 cargo test --offline --release -j 2 -p nice_common --features cubecl-spirv,cubecl/spirv-dump,midout-box-tests --lib --no-run > aco-out/build_$1.log 2>&1 || { echo BUILD FAIL; grep -m5 -A5 '^error' aco-out/build_$1.log; exit 1; }
cp $(ls -t target/release/build/nice_common/*/out/nice_common-* | head -1) bins/t_$1; echo built $1
