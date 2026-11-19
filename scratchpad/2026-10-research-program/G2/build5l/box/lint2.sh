#!/bin/bash
# box: after m4, fast-forward /root/m5w to the head and rerun fmt and the clippy sets; $1 log dir
set -u
until test -f /root/l5/m4/done; do sleep 5; done
L=$1; mkdir -p $L; source ~/.cargo/env; cd /root/m5w; export CARGO_TARGET_DIR=/root/t/m5w
git fetch -q /root/head2.bundle dev/middle-out-join && git checkout -q -B w FETCH_HEAD
git log --oneline -1 > $L/head.txt; git status --short >> $L/head.txt
s() { n=$1; shift; echo "$(date -u +%FT%TZ) start $n" >> $L/runs.log; "$@" > $L/$n.log 2>&1; rc=$?; echo "$(date -u +%FT%TZ) end $n rc=$rc" >> $L/runs.log; }
s fmt cargo fmt --all --check
s clippy_def cargo clippy -p nice_common -p nice_client --all-targets -- -D warnings
s clippy_gpu cargo clippy -p nice_common --all-targets --features cubecl-cuda,cubecl-spirv -- -D warnings
s clippy_cl cargo clippy -p nice_common -p nice_client --all-targets --features nice_client/gpu,nice_client/cubecl-spirv -- -D warnings
s clippy_clf cargo clippy -p nice_common -p nice_client --all-targets --features nice_client/cubecl-cuda,nice_client/midout-fault -- -D warnings
echo done > $L/done
