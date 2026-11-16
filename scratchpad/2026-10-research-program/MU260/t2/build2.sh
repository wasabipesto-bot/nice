#!/bin/bash
# build2.sh SHA: release client --features gpu,cubecl-cuda from the exact commit (own worktree + target dir) -> /root/mu/t2/bin/nice-<sha8>
S=$1; S8=${S:0:8}; . /root/.cargo/env
mkdir -p /root/mu/t2/bin /root/mu/t2/logs
cd /root/nice; [ -d /root/mu/t2/wt-$S8 ] || git worktree add -q -f --detach /root/mu/t2/wt-$S8 $S
cd /root/mu/t2/wt-$S8; export CARGO_TARGET_DIR=/root/mu/t2/target-$S8
t0=$(date +%s)
cargo build --release -j ${J:-12} -p nice_client --features gpu,cubecl-cuda > /root/mu/t2/logs/build-$S8.log 2>&1 || { echo "BUILD FAILED $S8"; tail -20 /root/mu/t2/logs/build-$S8.log; exit 1; }
cp $CARGO_TARGET_DIR/release/nice_client /root/mu/t2/bin/nice-$S8
echo "$(date -u +%FT%TZ) built $S8 ($(git log --oneline -1 | cut -c1-50), dirty:$(git status --porcelain | wc -l), $(rustc --version)) in $(( $(date +%s) - t0 )) s md5 $(md5sum /root/mu/t2/bin/nice-$S8 | cut -c1-8)" | tee -a /root/mu/t2/builds.txt
