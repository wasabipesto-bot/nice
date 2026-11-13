#!/bin/sh
# build.sh: nice_common's release test binary of $W/wt/E -> $BIN/E, own target dir $W/target-E, niced, -j ${JOBS:-8},
# features gpu,cubecl-spirv (production's build on the RX 9070 XT). Prints time, md5 and whether it has the switches.
. "${SCRIPTS:-$(dirname "$0")}/env.sh"
cd "$W/wt/E" || exit 1
export CARGO_TARGET_DIR=$W/target-E
t0=$(date +%s)
nice -n 19 cargo test --release -j "${JOBS:-8}" -p nice_common --features gpu,cubecl-spirv --no-run > "$OUT/build_E.log" 2>&1 ||
  { echo "BUILD FAILED"; tail -40 "$OUT/build_E.log"; exit 1; }
bin=$(grep -o "$CARGO_TARGET_DIR/release/deps/nice_common-[0-9a-f]*" "$OUT/build_E.log" | head -1)
cp "$bin" "$BIN/E" && echo "built E ($(git log --oneline -1 | cut -c1-12)) in $(( $(date +%s) - t0 )) s: md5 $(md5sum "$BIN/E" | cut -c1-8)"
if strings "$BIN/E" | grep -q NICE_EXP_N21; then echo "  E: has the N21 switches"; else echo "  E: NO N21 SWITCHES"; exit 1; fi
