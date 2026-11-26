#!/bin/bash
# build_mo.sh BRANCH TAG: fetch BRANCH from the fork and build, for this Mac's Metal device through wgpu,
#   t_box   nice_common's lib tests with the card tier (cubecl,midout-box-tests), LTO off
#   midout_bench, midout_wide_bench, midout_fields (cubecl,midout-bench)
# into $R/bin/TAG. Log: $R/logs/TAG/.
. "$(dirname "$0")/env.sh"
B=$1; TAG=$2; L=$R/logs/$TAG; W=$R/src/$TAG; mkdir -p "$L" "$R/bin/$TAG" "$R/t" "$R/src"; rm -f "$L/done"
if [ ! -d "$R/src/nice/.git" ]; then git clone -q https://github.com/wasabipesto-bot/nice.git "$R/src/nice" 2> "$L/clone.log" || { echo "clone failed" >> "$L/rc.txt"; exit 1; }; fi
cd "$R/src/nice" || exit 1
git fetch -q origin "$B" 2> "$L/fetch.log" || { echo "fetch failed" >> "$L/rc.txt"; exit 1; }
if [ -d "$W" ]; then git -C "$W" checkout -q --detach FETCH_HEAD; else git worktree add -q --detach "$W" FETCH_HEAD; fi
cd "$W" || exit 1; git log --oneline -1 > "$L/head.txt"; git status --short >> "$L/head.txt"
export CARGO_TARGET_DIR=$R/t/$TAG
s=$(date +%s)
CARGO_PROFILE_RELEASE_LTO=false CARGO_PROFILE_RELEASE_CODEGEN_UNITS=16 cargo test --release -p nice_common --features cubecl,midout-box-tests --lib --no-run > "$L/b_tests.log" 2>&1; echo "tests rc=$? $(( $(date +%s) - s )) s" >> "$L/rc.txt"
X=$(sed -n 's/.*Executable unittests src\/lib.rs (\(.*\))/\1/p' "$L/b_tests.log" | tail -1); [ -n "$X" ] && cp "$X" "$R/bin/$TAG/t_box"
s=$(date +%s)
export CARGO_TARGET_DIR=$R/t/${TAG}-rel
cargo build --release -p nice_common --features cubecl,midout-bench --example midout_bench --example midout_wide_bench --example midout_fields > "$L/b_bench.log" 2>&1; echo "bench rc=$? $(( $(date +%s) - s )) s" >> "$L/rc.txt"
cp "$CARGO_TARGET_DIR"/release/examples/midout_bench "$CARGO_TARGET_DIR"/release/examples/midout_wide_bench "$CARGO_TARGET_DIR"/release/examples/midout_fields "$R/bin/$TAG/" 2>/dev/null
md5 -r "$R/bin/$TAG"/* > "$L/bins.txt"; echo done > "$L/done"
