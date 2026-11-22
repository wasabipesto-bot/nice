#!/bin/bash
# box: build the dump/count example (CPU)
source ~/.cargo/env; export CARGO_TARGET_DIR=/root/tgt; cd /root/nice
date -u
cargo build --release -p nice_common --example mo_width_dump 2>&1 | grep -E '^(error|warning)|-->|Finished' ; echo dump rc=${PIPESTATUS[0]}
date -u
