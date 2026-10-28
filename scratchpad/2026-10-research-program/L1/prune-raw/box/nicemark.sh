#!/bin/bash
# Usage: nicemark.sh TREE ROUND
T=$1; RD=$2
cd /root/$T
echo "== $(date -u +%FT%TZ) tree=$T round=$RD commit=$(git rev-parse --short HEAD)" >&2
LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH RUST_LOG=info ./target/release/nice_client niceonly --gpu --benchmark --benchmark-secs 150 --benchmark-json < /dev/null
echo "== end $(date -u +%FT%TZ) exit=$?" >&2
