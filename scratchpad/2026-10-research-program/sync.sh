#!/usr/bin/env bash
# Snapshot this directory into the `research-program` branch and push it to the fork,
# without touching the main checkout (scratchpad/ is gitignored there). Files over
# 5 MB and build dirs are left out; raw data that size goes to braize or the fork's
# releases instead.
set -euo pipefail
REPO="$HOME/projects/nice"; DIR="scratchpad/2026-10-research-program"; BRANCH="research-program"
MSG="${1:-sync $(date -u +%F)}"
cd "$REPO"
if ! git show-ref --quiet "refs/heads/$BRANCH"; then
  git fetch -q origin main && git branch "$BRANCH" origin/main
fi
export GIT_INDEX_FILE; GIT_INDEX_FILE="$(mktemp)"
trap 'rm -f "$GIT_INDEX_FILE"' EXIT
git read-tree "refs/heads/$BRANCH"
find "$DIR" -type f -size -5M -not -path '*/target/*' -not -path '*/__pycache__/*' -not -path '*/.worktrees/*' -print0 \
  | xargs -0 git add -f --
tree="$(git write-tree)"
if [ "$tree" = "$(git rev-parse "refs/heads/$BRANCH^{tree}")" ]; then echo "sync: no changes"; exit 0; fi
commit="$(printf '%s\n\nCo-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>\n' "research program: $MSG" | git commit-tree "$tree" -p "refs/heads/$BRANCH")"
git update-ref "refs/heads/$BRANCH" "$commit"
echo "sync: $BRANCH -> $commit"
for i in 1 2 3 4; do git push -q -u fork "$BRANCH" && exit 0; sleep $((2**i)); done
echo "sync: push failed after retries" >&2; exit 1
