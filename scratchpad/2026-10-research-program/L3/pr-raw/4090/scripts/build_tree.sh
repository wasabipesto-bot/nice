#!/bin/bash
# build_tree.sh NAME : release nice_client, l3win example, nice_common test binary
source ~/.cargo/env
N=$1
cd /root/$N
export CARGO_TARGET_DIR=/root/t_$N
L=/root/runs/build_$N.log
: > $L
cargo build --release -p nice_client --features gpu >> $L 2>&1; echo "== client exit $?" >> $L
cargo build --release -p nice_common --features gpu --example l3win >> $L 2>&1; echo "== example exit $?" >> $L
cargo test --release -p nice_common --features gpu --no-run >> $L 2>&1; echo "== test exit $?" >> $L
echo done > /root/runs/build_$N.done
