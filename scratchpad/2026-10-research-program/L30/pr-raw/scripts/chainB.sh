#!/bin/bash
# Builds: clients (main, pr), wgpu/naga and spirv test binaries (pr). One at a time in /root/tgt.
source ~/.cargo/env
export CARGO_TARGET_DIR=/root/tgt
L=/root/l30pr
for s in main pr; do
  cd /root/src-$s
  cargo clean --release -p nice_common -p nice_client > /dev/null 2>&1
  t0=$(date +%s)
  nice -n 5 cargo build --release -j 9 -p nice_client --features gpu > $L/build_client_$s.log 2>&1 || { echo "BUILD FAILED client_$s"; tail -30 $L/build_client_$s.log; }
  cp /root/tgt/release/nice_client $L/client_$s && md5sum $L/client_$s
  echo "built client_$s in $(( $(date +%s) - t0 )) s"
done
echo CLIENTS_DONE $(date -u +%T)
/root/build.sh src-pr pr_wgpu cubecl
/root/build.sh src-pr pr_spirv cubecl-spirv
echo CHAIN_B_DONE $(date -u +%T)
