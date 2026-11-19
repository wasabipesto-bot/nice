#!/bin/bash
# box: toolchain (pinned 1.100.0), lavapipe, spirv-tools, just
set -x
export DEBIAN_FRONTEND=noninteractive
apt-get update -q && apt-get install -yq mesa-vulkan-drivers vulkan-tools spirv-tools libvulkan1 git curl build-essential pkg-config libssl-dev just python3 > /root/apt.log 2>&1; echo apt rc=$?
curl -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain 1.100.0 --profile minimal -c clippy,rustfmt > /root/rustup.log 2>&1; echo rustup rc=$?
source ~/.cargo/env; rustc -V; cargo -V; just --version; vulkaninfo --summary 2>&1 | grep -i 'deviceName\|driverName'
echo done > /root/setup.done
