#!/bin/bash
# build_wip.sh PATCH TAG [spv]: worktree b65w at the merge head 73bc0065 with PATCH applied, the lib test binary
# (CUDA, or SPIR-V with "spv") into bin/TAG/t_box; logs in $R/logs/reads/TAG.log.
. "$HOME/research/scripts/env.sh"
P=$1; TAG=$2; F=cubecl-cuda,midout-box-tests; [ "$3" = spv ] && F=cubecl-spirv,midout-box-tests
W=$SRC/.worktrees/b65w; cd "$SRC" || exit 1
if [ -d "$W" ]; then git -C "$W" checkout -q -f --detach 73bc0065; else git worktree add -q --detach "$W" 73bc0065; fi
cd "$W" && git apply "$P" || { echo "apply failed"; exit 1; }
export CARGO_TARGET_DIR=$R/t/b65w; s=$(date +%s); mkdir -p $R/logs/reads $R/bin/$TAG
CARGO_PROFILE_RELEASE_LTO=false CARGO_PROFILE_RELEASE_CODEGEN_UNITS=16 cargo test --release -p nice_common --features "$F" --lib --no-run > "$R/logs/reads/$TAG.log" 2>&1; rc=$?
X=$(grep -oP "Executable unittests src/lib.rs \(\K[^)]*" "$R/logs/reads/$TAG.log" | tail -1); [ -n "$X" ] && cp "$X" "$R/bin/$TAG/t_box"
echo "$(date -u +%T) $TAG wip feats=$F rc=$rc $(( $(date +%s) - s )) s" >> $R/b65b/wip.rc
