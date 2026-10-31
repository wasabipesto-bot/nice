#!/bin/sh
# usage: test.sh <A|B> <label> <test-binary args...>
. "$HOME/claude-exp-2026-10-31-top/env.sh"
t=$1; shift; label=$1; shift
T="$D/bin/nice_common-test-$t"
cd "$D/src-$t/common" || exit 10
export RUST_BACKTRACE=1
s=$(date +%s)
echo "=== $label: tree $t ($(cat "$D/src-$t/TREE_COMMIT")) $T $*"
"$T" "$@" --test-threads=1 --nocapture
rc=$?
e=$(date +%s)
echo "=== RESULT $label rc=$rc secs=$((e-s))"
exit $rc
