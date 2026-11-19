#!/bin/bash
# the whole workspace suite as `just test` runs it (-p "*"), after libpq-dev was installed on the box
source ~/.cargo/env
cd /root/sra/nice
export CARGO_TARGET_DIR=/root/sra/target
L=/root/sra/logs/phase4; mkdir -p $L
while [ ! -f /root/sra/logs/phase3/done ]; do sleep 10; done
echo "$(date -u +%FT%TZ) start workspace_suite" >> $L/steps.log
cargo test --release -p "*" --no-fail-fast > $L/workspace_suite.log 2>&1
echo "$(date -u +%FT%TZ) end workspace_suite rc=$?" >> $L/steps.log
echo done > $L/done
