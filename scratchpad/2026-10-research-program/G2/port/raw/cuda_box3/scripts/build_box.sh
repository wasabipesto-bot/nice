#!/bin/bash
# on box (Vast 61250912): build v10 (nvcc), the tuned port 4170a781 (T), the pre-tuning port 9ff100e6 (P), and
# upstream main 7e0113fc's client, all with CUDA. Code from GitHub (upstream main) + the bundle; nothing pushed.
set -x
cd /root
[ -f ~/.cargo/env ] || curl -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal
source ~/.cargo/env
export PATH=/usr/local/cuda/bin:$PATH
[ -d nice ] || git clone -q https://github.com/wasabipesto/nice.git
cd /root/nice
git checkout -q --detach 7e0113fc
git log --oneline -1
git fetch -q /root/g2/g2-cubecl-local.bundle g2-cubecl-local:g2-cubecl-local
git log --oneline -1 g2-cubecl-local
[ -d /root/g2/wtT ] || git worktree add -f --detach /root/g2/wtT 4170a781
[ -d /root/g2/wtP ] || git worktree add -f --detach /root/g2/wtP 9ff100e6
export CARGO_TARGET_DIR=/root/t/g2 NICE_BUILD_SHA=test
cd /root/g2
nvcc -O3 -arch=sm_86 -std=c++17 -lineinfo -Xptxas -v -DKVER=10 -DMINB=3 -o bin/v10 g2bench.cu > build_v10.log 2>&1; echo "v10 rc=$?"
cd /root/g2/wtT && git log --oneline -1 && cargo build --release -j 14 -p nice_common --example g2_cubecl --features cubecl-cuda > /root/g2/build_T.log 2>&1; echo "T rc=$?"
cp $CARGO_TARGET_DIR/release/examples/g2_cubecl /root/g2/bin/g2_T
cd /root/g2/wtP && git log --oneline -1 && cargo build --release -j 14 -p nice_common --example g2_cubecl --features cubecl-cuda > /root/g2/build_P.log 2>&1; echo "P rc=$?"
cp $CARGO_TARGET_DIR/release/examples/g2_cubecl /root/g2/bin/g2_P
cd /root/nice && git log --oneline -1 && cargo build --release -j 14 -p nice_client --features gpu,cubecl-cuda > /root/g2/build_client.log 2>&1; echo "client rc=$?"
cp $CARGO_TARGET_DIR/release/nice_client /root/g2/nice-main
git -C /root/nice rev-parse HEAD > /root/g2/main_sha.txt
md5sum /root/g2/bin/* /root/g2/nice-main
echo BUILD_DONE
