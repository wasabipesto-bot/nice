#!/bin/bash
# Cross-tree fingerprints, every base 10-64: main (division) vs fd.
source /root/.cargo/env
export NICE_API_BASE=http://127.0.0.1:9
for t in main fd; do
  cd /root/$t
  cargo build --release -p nice_common --features gpu --example fdcheck > /root/logs/build_fdcheck_$t.log 2>&1
done
for t in main fd; do
  cd /root/$t
  s=$(date +%s); ./target/release/examples/fdcheck > /root/logs/fdcheck_$t.txt 2>&1; echo "secs $(( $(date +%s) - s ))" >> /root/logs/fdcheck_$t.txt
done
echo FDCHECK_DONE >> /root/logs/fdcheck_fd.txt
