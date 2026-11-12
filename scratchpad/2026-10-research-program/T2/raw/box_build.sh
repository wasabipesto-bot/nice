#!/bin/bash
# usage on box: box_build.sh SHA  -> /root/bin/nice-<sha8>
set -e
source ~/.cargo/env
S=$1; S8=${S:0:8}
mkdir -p /root/w /root/t /root/bin /root/logs
cd /root/nice
[ -d /root/w/$S8 ] || git worktree add -f --detach /root/w/$S8 $S
cd /root/w/$S8
export CARGO_TARGET_DIR=/root/t/$S8
cargo build --release -p nice_client --features gpu,cubecl-cuda > /root/logs/build-$S8.log 2>&1
cp $CARGO_TARGET_DIR/release/nice_client /root/bin/nice-$S8
echo built $S8
