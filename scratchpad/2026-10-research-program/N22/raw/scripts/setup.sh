#!/bin/bash
# setup.sh (box, root): toolchain 1.100.0 (repo pin), spirv-tools + vulkan headers, worktree $W/wt/I = fork exp/integration-1114.
set -e
W=/root/n22; mkdir -p $W/out $W/bin $W/wt $W/logs $W/spv
export DEBIAN_FRONTEND=noninteractive
apt-get install -y -qq spirv-tools libvulkan-dev rsync zstd > $W/out/apt2.log 2>&1
. /root/.cargo/env
cd /root/nice
git fetch -q origin exp/integration-1114
[ -d $W/wt/I ] || git worktree add -q --detach $W/wt/I origin/exp/integration-1114
cd $W/wt/I; rustup show active-toolchain > $W/out/rustup2.log 2>&1 || rustup toolchain install $(sed -n 's/^channel *= *"\(.*\)"/\1/p' rust-toolchain.toml) --profile minimal -c rustfmt,clippy >> $W/out/rustup2.log 2>&1
echo "I $(git -C $W/wt/I log --oneline -1)"
echo "SETUP_DONE $(date -u +%T) $(cd $W/wt/I && rustc --version) $(nvidia-smi --query-gpu=name,power.limit,driver_version --format=csv,noheader)"
