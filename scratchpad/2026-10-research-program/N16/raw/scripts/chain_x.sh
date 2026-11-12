#!/bin/sh
# chain_x.sh [MODES]: exactness of the exact modes against the CPU join (the dense compare: device hits and both
# survivor counts equal the CPU join's) on NX partitions of slice 0 of XFIELD (default b62 1e17 at 0.45, 2 partitions;
# the box's lavapipe runs use a 1e14 field). One process per mode.
. "${SCRIPTS:-$(dirname "$0")}/env.sh"
. "$SCRIPTS/modes.sh"
: "${XFIELD:=62:$F62:1e17}" "${NX:=2}" "${NB:=N16}"
for m in ${1:-c d_load d_copy d_and d_walk d_pf d_check d_wave d_bar wsync bal0 bal2 bal1 tc128 wg128 wg64 wg128tc wg128e4 wg64tc vram}; do
  [ -e "$W/stop" ] && exit 0
  setmode $m
  n=${XPFX:-x}_$m
  echo "START $n $(date -u +%T) $XFIELD $NX env=[$(env | grep -E '^NICE_EXP_' | sort | tr '\n' ' ')]" > "$OUT/$n.log"
  NICE_TEST_JOIN_DENSE=$NX NICE_TEST_JOIN_DENSE_FIELD=$XFIELD "$BIN/$NB" --ignored --exact $DENSE --nocapture --test-threads 1 >> "$OUT/$n.log" 2>&1
  echo "$(date -u +%T) $n $(grep -o 'partitions: .*' "$OUT/$n.log" | cut -c1-160) $(grep -o 'test result: [a-z]*' "$OUT/$n.log")"
done
echo "X_DONE $(date -u +%T)"
