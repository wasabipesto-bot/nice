#!/bin/sh
# usage: bench.sh <secs> <tag> <tree>...   e.g. bench.sh 90 r main pr main pr
. "$HOME/claude-exp-2026-10-30-fd/env.sh"
secs=$1; tag=$2; shift 2
cd "$D" || exit 10
i=0
for t in "$@"; do
  i=$((i+1))
  s=$(date +%s)
  echo "=== RUN $tag$i $t start $s"
  NICE_API_BASE=http://127.0.0.1:9 RUST_LOG=info "$D/bin/nice_client-$t" detailed --gpu --benchmark --benchmark-secs "$secs" > "$D/logs/bench-$tag$i-$t.log" 2>&1 < /dev/null
  rc=$?
  e=$(date +%s)
  echo "=== RUN $tag$i $t rc=$rc secs=$((e-s))"
done
echo BENCH_DONE
