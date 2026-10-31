#!/bin/bash
source /root/.cargo/env
cd /root/nice
L=/root/logs
run() { local tag=$1; shift; local s=$SECONDS; "$@" > $L/$tag.log 2>&1; echo "rc=$? wall=$((SECONDS-s))s" >> $L/$tag.log; }
run t4-fmt cargo fmt --all --check
run t4-clippy-default cargo clippy -p nice_common --all-targets -- -D warnings
run t4-clippy-gpu cargo clippy -p nice_common --all-targets --features gpu -- -D warnings
run t4-clippy-gpu-spirv cargo clippy -p nice_common --all-targets --features gpu,cubecl-spirv -- -D warnings
run t4-clippy-wasm-client cargo clippy -p nice-wasm-client --all-targets -- -D warnings
echo done > $L/t4.done
