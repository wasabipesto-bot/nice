#!/bin/bash
# Build the A/B harness (common/examples/l52_ab.rs, uncommitted) and the
# release client from the worktree's current tree into bin/<side>/.
# usage: build.sh <side>   (base = #248's head 7f5260b before any edit; pr = this branch)
set -e
WT=/home/claude/projects/nice/.worktrees/l52-two-pass-scan
R=/home/claude/projects/nice/scratchpad/2026-10-research-program/L52/raw
side=$1
cd $WT
export CARGO_TARGET_DIR=$WT/target
L=$R/build-$side.log
echo "### $(date -u +%H:%M:%S) build $side at $(git rev-parse --short HEAD) dirty: $(git status --short | tr '\n' ' ')" >> $L
nice -n 19 cargo build --release -p nice_common --example l52_ab >> $L 2>&1
cp target/release/examples/l52_ab bin/$side/l52_ab
nice -n 19 cargo build --release -p nice_client >> $L 2>&1
cp target/release/nice_client bin/$side/nice_client
md5sum bin/$side/* >> $L
echo "### $(date -u +%H:%M:%S) done" >> $L
