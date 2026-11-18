#!/bin/bash
# on box: hosts block + proof, card record, toolchain, lavapipe
mkdir -p /root/mo && cd /root/mo
sh /root/mo/hosts_block.sh > /root/mo/proof_hosts_block.txt 2>&1
nvidia-smi > /root/mo/nvidia_smi.txt; nvcc --version >> /root/mo/nvidia_smi.txt 2>&1; nproc >> /root/mo/nvidia_smi.txt
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq > /root/mo/apt.log 2>&1
apt-get install -y -qq mesa-vulkan-drivers vulkan-tools libvulkan-dev git build-essential pkg-config libssl-dev python3 >> /root/mo/apt.log 2>&1
[ -f ~/.cargo/env ] || curl -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal --default-toolchain 1.100.0 -c clippy,rustfmt > /root/mo/rustup.log 2>&1
source ~/.cargo/env; rustup toolchain install 1.100.0 -c clippy,rustfmt >> /root/mo/rustup.log 2>&1
rustc --version > /root/mo/setup_done.txt; vulkaninfo --summary 2>&1 | grep -iE "deviceName|driverName" >> /root/mo/setup_done.txt
date -u >> /root/mo/setup_done.txt
