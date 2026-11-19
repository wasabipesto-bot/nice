#!/bin/bash
# box: g.sh — production's stride table at bases with no valid residue, in a scratch clone of upstream main
# (/root/up at 974d7194; no branch, nothing pushed): append the probe and the failing test (g_probe.rs) to
# stride_filter.rs's end, run both. Output /root/runs/g.
source ~/.cargo/env; cd /root/up; O=/root/runs/g; mkdir -p $O; rm -f $O/done
git log --oneline -1 > $O/head.txt
grep -q empty_table_probe common/src/stride_filter.rs || cat /root/g_probe.rs >> common/src/stride_filter.rs
git diff > $O/scratch.diff
export CARGO_TARGET_DIR=/root/t/up CARGO_PROFILE_RELEASE_LTO=false
cargo test --release -p nice_common --lib empty_table_probe -- --nocapture --test-threads 1 > $O/probe.txt 2>&1; echo "probe rc=$?" >> $O/rc.txt
echo done > $O/done
