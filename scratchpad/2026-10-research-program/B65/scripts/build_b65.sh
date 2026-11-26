#!/bin/bash
# build_b65.sh TREE REV FEATS EXAMPLES TAG: check out REV (already fetched from the fork) detached in worktree
# $SRC/.worktrees/TREE, build the EXAMPLES (comma list) of nice_common with FEATS into $R/bin/TAG.
# One release target directory per tree ($R/t/TREE-rel), so a rebuild with other features only rebuilds what differs.
. "$HOME/research/scripts/env.sh"
TREE=$1; REV=$2; FEATS=$3; EXS=$4; TAG=$5
L=$R/logs/b65; mkdir -p "$L" "$R/bin/$TAG"; W=$SRC/.worktrees/$TREE
cd "$SRC" || exit 1
if [ -d "$W" ]; then git -C "$W" checkout -q --detach "$REV" || exit 1; else git worktree add -q --detach "$W" "$REV" || exit 1; fi
cd "$W" || exit 1
H=$(git rev-parse --short=8 HEAD); D=$(git status --short | wc -l)
export CARGO_TARGET_DIR=$R/t/$TREE-rel
A=""; for e in ${EXS//,/ }; do A="$A --example $e"; done
s=$(date +%s)
cargo build --release -p nice_common --features "$FEATS" $A > "$L/$TAG.log" 2>&1; rc=$?
for e in ${EXS//,/ }; do cp "$CARGO_TARGET_DIR/release/examples/$e" "$R/bin/$TAG/" 2>/dev/null; done
echo "$(date -u +%T) $TAG tree=$TREE head=$H dirty=$D feats=$FEATS rc=$rc $(( $(date +%s) - s )) s $(cd $R/bin/$TAG && md5sum * | cut -c1-8 | tr '\n' ' ')" >> "$L/rc.txt"
exit $rc
