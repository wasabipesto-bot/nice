#!/bin/sh
# setup_window.sh: worktree $W/wt/E = $COMMIT of the fork's exp/n21-walk-loop, in the clone $W/src/nice (remote
# origin = the fork). Run as: $W/run.sh sh $W/scripts/setup_window.sh
. "${SCRIPTS:-$(dirname "$0")}/env.sh"
cd "$W/src/nice" || exit 1
git fetch -q origin exp/n21-walk-loop || exit 1
mkdir -p "$W/wt"
[ -d "$W/wt/E" ] || git worktree add -q --detach "$W/wt/E" "$COMMIT" || exit 1
(cd "$W/wt/E" && echo "E $(git log --oneline -1 | cut -c1-70)") | tee "$OUT/trees.txt"
