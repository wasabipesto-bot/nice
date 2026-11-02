#!/bin/bash
# The chosen gate (TRANSPOSE_MIN = 192): unpack P192, build its test binary, then (CPU) its client, lavapipe
# binaries, fmt and clippy beside the GPU checks (chain_prx.sh 192), then the A/B (chain_prab.sh 192).
L=/root/l34/logs; S=/root/l34
rm -rf /root/l34/src/P192; mkdir -p /root/l34/src/P192; tar xzf /root/l34/PR192.tgz -C /root/l34/src/P192
J=10 $S/build.sh P192 P192 gpu || exit 1
echo P192_DONE $(date -u +%T) > $L/p192.done
nohup $S/chain_prx.sh 192 > $L/chain_prx.out 2>&1 < /dev/null &
$S/buildclient.sh P192 client_P192 || exit 1
J=10 $S/build.sh P192 P192_naga cubecl || exit 1
J=10 $S/build.sh P192 P192_spv cubecl-spirv || exit 1
echo LB_DONE $(date -u +%T) > $L/prlb_192.done
cd /root/l34/src/P192 && source ~/.cargo/env && export CARGO_TARGET_DIR=/root/tgt-clippy NICE_BUILD_SHA=test
( cargo fmt --all --check; echo "fmt rc=$?" ) > $L/pr192_fmt.log 2>&1
( cargo clippy -p "*" --all-targets -- -D warnings; echo "clippy default rc=$?" ) > $L/pr192_clippy_default.log 2>&1
( cargo clippy -p "*" --all-targets --features nice_client/gpu -- -D warnings; echo "clippy gpu rc=$?" ) > $L/pr192_clippy_gpu.log 2>&1
echo LINT_DONE $(date -u +%T) > $L/prlint_192.done
$S/chain_prab.sh 192 > $L/chain_prab.out 2>&1 < /dev/null
