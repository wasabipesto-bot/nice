#!/bin/bash
# build_mo.sh BRANCH TAG: fetch BRANCH from the fork, check it out as a worktree, and build
#   t_box        nice_common's lib tests with the card tier (cubecl-cuda,midout-box-tests), LTO off as on the rented boxes
#   midout_bench, midout_wide_bench, midout_fields   (cubecl-cuda,midout-bench)
#   nice_client  (--features gpu: the production GPU set, which carries the midout mode's CubeCL backend)
# into $R/bin/TAG, one target directory per tree under $R/t. Log: $R/logs/TAG/.
. "$(dirname "$(readlink -f "$0")")/env.sh"
B=$1; TAG=$2; L=$R/logs/$TAG; W=$SRC/.worktrees/$TAG; mkdir -p "$L" "$R/bin/$TAG" "$R/t"; rm -f "$L/done"
cd "$SRC" || exit 1
git remote get-url fork >/dev/null 2>&1 || git remote add fork https://github.com/wasabipesto-bot/nice.git
git fetch -q fork "$B" 2> "$L/fetch.log" || { echo "fetch failed" >> "$L/rc.txt"; exit 1; }
if [ -d "$W" ]; then git -C "$W" checkout -q --detach FETCH_HEAD; else git worktree add -q --detach "$W" FETCH_HEAD; fi
cd "$W" || exit 1; git log --oneline -1 > "$L/head.txt"; git status --short >> "$L/head.txt"
export CARGO_TARGET_DIR=$R/t/$TAG
s=$(date +%s)
CARGO_PROFILE_RELEASE_LTO=false CARGO_PROFILE_RELEASE_CODEGEN_UNITS=16 cargo test --release -p nice_common --features cubecl-cuda,midout-box-tests --lib --no-run > "$L/b_tests.log" 2>&1; echo "tests rc=$? $(( $(date +%s) - s )) s" >> "$L/rc.txt"
X=$(grep -oP "Executable unittests src/lib.rs \(\K[^)]*" "$L/b_tests.log" | tail -1); [ -n "$X" ] && cp "$X" "$R/bin/$TAG/t_box"
s=$(date +%s)
export CARGO_TARGET_DIR=$R/t/${TAG}-rel
cargo build --release -p nice_common --features cubecl-cuda,midout-bench --example midout_bench --example midout_wide_bench --example midout_fields > "$L/b_bench.log" 2>&1; echo "bench rc=$? $(( $(date +%s) - s )) s" >> "$L/rc.txt"
cp "$CARGO_TARGET_DIR"/release/examples/midout_bench "$CARGO_TARGET_DIR"/release/examples/midout_wide_bench "$CARGO_TARGET_DIR"/release/examples/midout_fields "$R/bin/$TAG/" 2>/dev/null
s=$(date +%s)
cargo build --release -p nice_client --features gpu > "$L/b_client.log" 2>&1; echo "client rc=$? $(( $(date +%s) - s )) s" >> "$L/rc.txt"
cp "$CARGO_TARGET_DIR/release/nice_client" "$R/bin/$TAG/" 2>/dev/null
cp "$W"/scripts/midout_coordinator.py "$W"/scripts/midout_audit.py "$R/bin/$TAG/" 2>/dev/null
md5sum "$R/bin/$TAG"/* > "$L/bins.txt"; echo done > "$L/done"
