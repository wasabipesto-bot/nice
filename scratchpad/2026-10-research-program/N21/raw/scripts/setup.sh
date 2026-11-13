#!/bin/bash
# setup.sh (box, root): toolchain 1.99.1, spirv-tools + vulkan headers, worktree $W/wt/E = fork exp/n21-walk-loop.
set -e
W=/root/n21; mkdir -p $W/out $W/bin $W/wt $W/logs
export DEBIAN_FRONTEND=noninteractive
apt-get install -y -qq spirv-tools libvulkan-dev rsync zstd > $W/out/apt2.log 2>&1
. /root/.cargo/env
rustup toolchain install 1.99.1 --profile minimal -c rustfmt,clippy > $W/out/rustup2.log 2>&1
rustup default 1.99.1 >> $W/out/rustup2.log 2>&1
cd /root/nice
git fetch -q origin exp/n21-walk-loop
git fetch -q upstream main
[ -d $W/wt/E ] || git worktree add -q --detach $W/wt/E origin/exp/n21-walk-loop
echo "E $(git -C $W/wt/E log --oneline -1)"
echo "SETUP_DONE $(date -u +%T) $(rustc --version) $(nvidia-smi --query-gpu=name,power.limit,driver_version --format=csv,noheader)"
