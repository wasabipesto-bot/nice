#!/bin/bash
# per-stage cost: cumulative stops on field 77777, before (91ac0761) and after (the head), interleaved, twice
cd /root/midout; source ~/.cargo/env
L=/root/b3/final; grep -q "127.0.0.1 api.nicenumbers.net" /etc/hosts || exit 1
export CARGO_TARGET_DIR=/root/t/mo
cargo build --offline --release -p nice_common --features cubecl-cuda,cubecl-spirv --example midout_bench > $L/build_bench_head.log 2>&1
cp /root/t/mo/release/examples/midout_bench /root/b3/mo_bench_c0ad
git log --oneline -1 > $L/stops_head.txt; md5sum /root/mo/mo_bench_head /root/b3/mo_bench_c0ad >> $L/stops_head.txt
OLD=/root/mo/mo_bench_head; NEW=/root/b3/mo_bench_c0ad
for r in 1 2; do
for st in 1 2 3 5; do
  echo "== before stop $st $(date -u +%T)"; MIDOUT_STOP=$st $OLD --cuda --fields 77777 2>&1 | grep -E "^FIELD|rror" | cut -c1-200
  echo "== after stop $st $(date -u +%T)"; MIDOUT_STOP=$st $NEW --cuda --fields 77777 --no-cpu-check 2>&1 | grep -E "^FIELD|rror" | cut -c1-200
done
echo "== before full $(date -u +%T)"; $OLD --cuda --fields 77777 2>&1 | grep -E "^FIELD|rror" | cut -c1-200
echo "== after full, no check $(date -u +%T)"; $NEW --cuda --fields 77777 --no-cpu-check 2>&1 | grep -E "^FIELD|rror" | cut -c1-200
echo "== after full, check $(date -u +%T)"; $NEW --cuda --fields 77777 2>&1 | grep -E "^FIELD|SAMPLE|rror" | cut -c1-200
done > $L/stops.log 2>&1
echo done > $L/stops_done
