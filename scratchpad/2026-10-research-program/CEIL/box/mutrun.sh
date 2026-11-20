#!/bin/bash
# box: mutrun.sh — wait for setup, baseline test on the unmutated head, then mut3.py (27 mutants).
until grep -q SETUP_DONE /w/setup.log; do sleep 10; done
source /root/.cargo/env
mkdir -p /w/raw/mut
cd /w/mut && git log --oneline -1 > /w/raw/mut/head.txt
export CARGO_TARGET_DIR=/w/tmut CARGO_BUILD_JOBS=6
date -u > /w/raw/mut/baseline.log
cargo test -q --release -p nice_common --lib midout:: >> /w/raw/mut/baseline.log 2>&1; echo "baseline rc=$?" >> /w/raw/mut/baseline.log
date -u >> /w/raw/mut/baseline.log
CARGO_BUILD_JOBS=6 python3 /w/box/mut3.py
date -u >> /w/raw/mut/table.txt
