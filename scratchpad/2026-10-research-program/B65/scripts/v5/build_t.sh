#!/bin/bash
# build_t.sh TREE REV FEATS TAG: nice_common's lib test binary (LTO off, as build_mo.sh) at REV in worktree TREE
# with FEATS, copied to $R/bin/TAG/t_box. Target dir $R/t/TREE (shared by the tree's test builds).
. "$HOME/research/scripts/env.sh"
TREE=$1; REV=$2; FEATS=$3; TAG=$4
L=$R/logs/reads; mkdir -p "$L" "$R/bin/$TAG"; W=$SRC/.worktrees/$TREE
cd "$SRC" || exit 1
if [ -d "$W" ]; then git -C "$W" checkout -q --detach "$REV" || exit 1; else git worktree add -q --detach "$W" "$REV" || exit 1; fi
cd "$W" || exit 1; H=$(git rev-parse --short=8 HEAD)
export CARGO_TARGET_DIR=$R/t/$TREE
s=$(date +%s)
CARGO_PROFILE_RELEASE_LTO=false CARGO_PROFILE_RELEASE_CODEGEN_UNITS=16 cargo test --release -p nice_common --features "$FEATS" --lib --no-run > "$L/$TAG.log" 2>&1; rc=$?
X=$(grep -oP "Executable unittests src/lib.rs \(\K[^)]*" "$L/$TAG.log" | tail -1); [ -n "$X" ] && cp "$X" "$R/bin/$TAG/t_box"
echo "$(date -u +%T) $TAG tree=$TREE head=$H feats=$FEATS rc=$rc $(( $(date +%s) - s )) s $(md5sum $R/bin/$TAG/t_box 2>/dev/null | cut -c1-8)" >> "$L/rc.txt"
exit $rc
