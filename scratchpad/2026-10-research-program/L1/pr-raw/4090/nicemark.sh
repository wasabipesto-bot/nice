#!/bin/bash
# NiceMark nice-only A/B, interleaved A B A B A B. Usage: nicemark.sh <A tree> <B tree>. No upload.
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH
for r in 1 2 3; do
  for t in $1 $2; do
    cd /root/$t
    echo "== $(date -u +%T) round=$r tree=$t commit=$(git rev-parse --short HEAD)"
    RUST_LOG=info ./target/release/nice_client niceonly --gpu --benchmark --benchmark-secs 150 --benchmark-json \
      < /dev/null > /root/ab/nm_r${r}_$t.json 2> /root/ab/nm_r${r}_$t.err
    echo "exit $? $(date -u +%T)"
  done
done
echo "NM_DONE $(date -u +%T)"
