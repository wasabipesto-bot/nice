#!/bin/sh
# go13.sh (director, 2026-11-13 demoux window, max 60 min from 15:40 UTC): (1) build C = fork pr/check-d 1f41d649
# (PR #251's fixed head) and run its wgpu device tests on this card while E (fork exp/n21-walk-loop 2d3e10d3) and
# M (main a7a59c11) build in the background; (2) time the walk-loop variants (binary E, NICE_EXP_N21 = 0 / 9 / 8) at
# b62 1e17 in three rotated rounds and at b64 1e17 once; (3) time C against M at b62, b60 (two rounds) and b64.
# END_AT (epoch): no run starts after it. Touch $W/stop to end before the next run.
. "$W/scripts/env.sh"
S=$W/scripts
: "${END_AT:?set END_AT}"
echo "GO_START $(date -u +%T) END_AT $(date -u -d @$END_AT +%T)"
bld() { # TREE LABEL JOBS
  cd "$W/wt/$1" || return 1
  t0=$(date +%s)
  CARGO_TARGET_DIR=$W/target-$1 nice -n 19 cargo test --release -j "$3" -p nice_common --features gpu,cubecl-spirv --no-run > "$OUT/build_$2.log" 2>&1 ||
    { echo "BUILD FAILED $2"; tail -30 "$OUT/build_$2.log"; return 1; }
  bin=$(grep -o "$W/target-$1/release/deps/nice_common-[0-9a-f]*" "$OUT/build_$2.log" | head -1)
  cp "$bin" "$BIN/$2" && echo "built $2 ($(git log --oneline -1 | cut -c1-12)) in $(( $(date +%s) - t0 )) s md5 $(md5sum "$BIN/$2" | cut -c1-8)"
}
bld C C 10 || exit 1
( bld E E 5; bld M M 5 ) > "$OUT/builds_bg.out" 2>&1 &
BG=$!
echo "TESTS_START $(date -u +%T)"
NICE_BUILD_SHA=test "$BIN/C" --ignored cubecl_join::tests:: --skip cuda --nocapture --test-threads 1 > "$OUT/tests_C.log" 2>&1
echo "TESTS_DONE $(date -u +%T) rc=$? $(grep -E '^test result' "$OUT/tests_C.log" | tail -1)"
wait $BG; cat "$OUT/builds_bg.out"
[ -x "$BIN/E" ] && [ -x "$BIN/M" ] || { echo "a background build failed"; exit 1; }
strings "$BIN/E" | grep -q NICE_EXP_N21 || { echo "E lacks the N21 switches"; exit 1; }
one() { # NAME BINLABEL N21MODE BASE SIZE START
  [ -e "$W/stop" ] && { echo "stopped by $W/stop"; exit 0; }
  [ "$(date +%s)" -ge "$END_AT" ] && { echo "stopped at END_AT $(date -u +%T)"; exit 0; }
  BL=$2 sh "$S/wrunb.sh" "$1" "$3" "$4" "$5" "$6"
  echo "$(date -u +%T) $1 $(grep -h 'JOIN THROUGHPUT' "$OUT/$1.log" | grep -o 'secs=[0-9.]*\|batches=[0-9]*\|survivors=[0-9]*\|checked=[0-9]*' | tr '\n' ' ') $(grep -h '^END' "$OUT/$1.log" | grep -o 'rc=[0-9]*')"
}
echo "N21_START $(date -u +%T)"
r=0
for O in "0 9 8" "9 8 0" "8 0 9"; do r=$((r+1)); for m in $O; do one m${m}_b62_r$r E $m 62 $SZ62 $F62; done; done
for m in 0 9 8; do one m${m}_b64_r1 E $m 64 $SZ64 $F64; done
echo "AB_START $(date -u +%T)"
one ab-M_b62_r1 M 0 62 $SZ62 $F62; one ab-C_b62_r1 C 0 62 $SZ62 $F62
one ab-M_b60_r1 M 0 60 $SZ60 $F60; one ab-C_b60_r1 C 0 60 $SZ60 $F60
one ab-C_b62_r2 C 0 62 $SZ62 $F62; one ab-M_b62_r2 M 0 62 $SZ62 $F62
one ab-C_b60_r2 C 0 60 $SZ60 $F60; one ab-M_b60_r2 M 0 60 $SZ60 $F60
one ab-M_b64_r1 M 0 64 $SZ64 $F64; one ab-C_b64_r1 C 0 64 $SZ64 $F64
echo "SPARE_START $(date -u +%T)"
one m9_b64_r2 E 9 64 $SZ64 $F64; one m0_b64_r2 E 0 64 $SZ64 $F64
echo "GO_DONE $(date -u +%T)"
