#!/bin/sh
# setup_box.sh (the rented box, as root): toolchain, Vulkan loader + lavapipe, a clone of the fork, and the worktrees
# $W/wt/N16 (exp/n16-join-base), $W/wt/M (upstream main 5b1d627) and $W/wt/D (exp/n14-wgpu-dense-plan). If
# /root/nice is missing it is cloned from $W/n16.bundle (copied from ivory) instead of GitHub.
set -e
W=${W:-/root/n16}; mkdir -p $W/out $W/bin $W/wt
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq > $W/out/apt.log 2>&1
apt-get install -y -qq git curl build-essential pkg-config libssl-dev clang mesa-vulkan-drivers libvulkan1 \
  vulkan-tools rsync >> $W/out/apt.log 2>&1
[ -x /root/.cargo/bin/cargo ] || curl -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal > $W/out/rustup.log 2>&1
. /root/.cargo/env
rustup toolchain install 1.99.1 --profile minimal -c rustfmt,clippy > $W/out/rustup2.log 2>&1 || true
rustup default 1.99.1 >> $W/out/rustup2.log 2>&1 || true
if [ ! -d /root/nice/.git ]; then
  git clone -q $W/n16.bundle /root/nice
fi
cd /root/nice
git fetch -q $W/n16.bundle 'refs/heads/*:refs/remotes/b/*' 2>/dev/null || true
for x in "N16 b/exp/n16-join-base" "M 5b1d627"; do
  set -- $x
  [ -d $W/wt/$1 ] || git worktree add -q --detach $W/wt/$1 $2
done
echo "SETUP_DONE $(date -u +%T) $(rustc --version) $(nvidia-smi --query-gpu=name,power.limit --format=csv,noheader) $(vulkaninfo --summary 2>/dev/null | grep -c deviceName) vulkan devices"
