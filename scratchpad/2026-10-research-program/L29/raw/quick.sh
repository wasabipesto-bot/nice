#!/bin/bash
# quick.sh: rebuild the pr test binary only (incremental) and copy it.
source /root/.cargo/env
cd /root/src/pr
cargo test --release -p nice_common --features gpu --no-run --message-format=json 2>/root/logs/quick.err > /root/logs/quick.json
BIN=$(grep -o '"executable":"[^"]*nice_common-[^"]*"' /root/logs/quick.json | tail -1 | cut -d'"' -f4)
grep "^error" -A10 /root/logs/quick.err | head -40
cp "$BIN" /root/bin/pr/nice_common_test && echo "copied $BIN"
