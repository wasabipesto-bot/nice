#!/bin/sh
# go22.sh (director, the RX 9070 XT window, at most 30 minutes): build X = fork exp/n22-rdna4 ($COMMIT) with
# production's features, then time NICE_EXP_N22 modes at full load:
#   0 = exp/integration-1114's kernels; 2 = W (the walk as a per-lane loop); 10 = W + B (b64's low digits as one bit
#   field); 16 = K (the check kernel's limb products in 24-bit multiplies); 32 = A (fixed-trip AND digit loop).
# Order: b64 1e17 three rotated rounds of 0 / 2 / 10 / 16 (the candidates' base), then b62 1e17 one round of
# 0 / 2 / 16 / 32, then spares. END_AT (epoch): no run starts after it. Touch $W/stop to end before the next run.
# Accept a run only if analyze_window.py OUT 3150 300 does not flag it OFF-POINT (median clock >= 97 % of 3150 MHz,
# power >= 90 % of 300 W over its >= 80 % busy samples; N13.2: the card's clock follows its load) and its counts
# equal the mode-0 run's of the same field.
. "$W/scripts/env.sh"
S=$W/scripts
: "${END_AT:?set END_AT}"
echo "GO_START $(date -u +%T) END_AT $(date -u -d @$END_AT +%T)"
if [ ! -x "$BIN/X" ]; then
  cd "$W/wt/X" || exit 1
  t0=$(date +%s)
  CARGO_TARGET_DIR=$W/target-X nice -n 19 cargo test --release -j "${JOBS:-12}" -p nice_common --features gpu,cubecl-spirv --no-run > "$OUT/build_X.log" 2>&1 ||
    { echo "BUILD FAILED"; tail -30 "$OUT/build_X.log"; exit 1; }
  # cargo 1.100 puts test binaries under the build dir: take the path cargo prints (N21's deps/ grep finds nothing).
  bin=$(sed -n 's/.*Executable unittests src\/lib.rs (\(.*\))/\1/p' "$OUT/build_X.log" | head -1)
  cp "$bin" "$BIN/X" && echo "built X ($(git log --oneline -1 | cut -c1-12)) in $(( $(date +%s) - t0 )) s md5 $(md5sum "$BIN/X" | cut -c1-8)"
fi
one() { # NAME N22MODE BASE SIZE START
  [ -e "$W/stop" ] && { echo "stopped by $W/stop"; exit 0; }
  [ "$(date +%s)" -ge "$END_AT" ] && { echo "stopped at END_AT $(date -u +%T)"; exit 0; }
  BL=X sh "$S/wrun.sh" "$1" "$2" "$3" "$4" "$5"
  echo "$(date -u +%T) $1 $(grep -h 'JOIN THROUGHPUT' "$OUT/$1.log" | grep -o 'secs=[0-9.]*\|batches=[0-9]*\|survivors=[0-9]*\|checked=[0-9]*' | tr '\n' ' ') $(grep -h '^END' "$OUT/$1.log" | grep -o 'rc=[0-9]*')"
}
echo "B64_START $(date -u +%T)"
r=0
for O in "0 2 10 16" "2 10 16 0" "10 16 0 2"; do r=$((r+1)); for m in $O; do one m${m}_b64_r$r $m 64 $SZ64 $F64; done; done
echo "B62_START $(date -u +%T)"
for m in 0 2 16 32; do one m${m}_b62_r1 $m 62 $SZ62 $F62; done
echo "SPARE_START $(date -u +%T)"
for m in 16 0 32 2; do one m${m}_b62_r2 $m 62 $SZ62 $F62; done
echo "GO_DONE $(date -u +%T)"
