#!/bin/bash
# chain_prcpu.sh M: CPU-only checks of the PR tree P$M at nice 19 (beside the gate screen): lavapipe binaries (naga,
# direct SPIR-V), cargo fmt --check, clippy default and --features nice_client/gpu (-D warnings).
M=$1; P=P$M; L=/root/l34/logs; S=/root/l34
until [ -e $L/pb2.done ]; do sleep 10; done
J=4 nice -n 19 $S/build.sh $P ${P}_naga cubecl || exit 1
J=4 nice -n 19 $S/build.sh $P ${P}_spv cubecl-spirv || exit 1
echo LB_DONE $(date -u +%T) > $L/prlb_$M.done
cd /root/l34/src/$P && source ~/.cargo/env && export CARGO_TARGET_DIR=/root/tgt-clippy NICE_BUILD_SHA=test
( cargo fmt --all --check; echo "fmt rc=$?" ) > $L/pr${M}_fmt.log 2>&1
( nice -n 19 cargo clippy -j 4 -p "*" --all-targets -- -D warnings; echo "clippy default rc=$?" ) > $L/pr${M}_clippy_default.log 2>&1
( nice -n 19 cargo clippy -j 4 -p "*" --all-targets --features nice_client/gpu -- -D warnings; echo "clippy gpu rc=$?" ) > $L/pr${M}_clippy_gpu.log 2>&1
echo LINT_DONE $(date -u +%T) > $L/prlint_$M.done
