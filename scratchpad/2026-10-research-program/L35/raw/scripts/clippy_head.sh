#!/bin/bash
# fmt + clippy (default, nice_client/gpu) on the PR head in Cfmt.
source ~/.cargo/env
L=/root/l35/logs
cd /root/l35/src/Cfmt && git checkout -q -- . && git fetch -q origin pr/top-fd && git checkout -q --detach FETCH_HEAD
export CARGO_TARGET_DIR=/root/tgt_clippy NICE_BUILD_SHA=test
echo "head $(git log --oneline -1) $(md5sum common/src/cubecl_join.rs | cut -c1-8)" > $L/p_head_checks.log
( cargo fmt --all --check; echo "fmt rc=$?" ) >> $L/p_head_checks.log 2>&1
nice -n 10 cargo clippy -j 8 -p "*" --all-targets -- -D warnings > $L/p_clippy2_default.log 2>&1; echo "clippy default rc=$?" >> $L/p_head_checks.log
nice -n 10 cargo clippy -j 8 -p "*" --all-targets --features nice_client/gpu -- -D warnings > $L/p_clippy2_gpu.log 2>&1; echo "clippy gpu rc=$?" >> $L/p_head_checks.log
echo CLIPPY_HEAD_DONE $(date -u +%T) > $L/clippy_head.done
