#!/bin/sh
. "$HOME/claude-exp-2026-10-30-fd/env.sh"
cd "$D/src-pr" || exit 10
cp "$D/cubecl_detailed_fd.rs" common/src/cubecl_detailed_fd.rs || exit 11
git diff --stat
cargo clean --release --offline -p nice_common
s=$(date +%s)
cargo test --release --offline -p nice_common --features cubecl --no-run 2> "$D/logs/testbuild-prdiag3.err"; rc=$?
tail -5 "$D/logs/testbuild-prdiag3.err"
echo "TEST_BUILD_SECS $(( $(date +%s)-s )) rc $rc"
[ $rc -eq 0 ] || { cat "$D/logs/testbuild-prdiag3.err"; exit 12; }
exe=$(sed -n 's/.*Executable unittests src\/lib.rs (\(.*\))$/\1/p' "$D/logs/testbuild-prdiag3.err" | head -1)
case "$exe" in /*) ;; *) exe="$D/src-pr/$exe";; esac
cp "$exe" "$D/bin/nice_common-test-prdiag3" || exit 14
cd common
"$D/bin/nice_common-test-prdiag3" --list --ignored 2>&1 | grep zz_metal_wrong_n

s=$(date +%s)
RUST_LOG=warn "$D/bin/nice_common-test-prdiag3" zz_metal_wrong_n --ignored --test-threads=1 --nocapture
echo "=== RESULT sweep rc=$? secs=$(( $(date +%s)-s ))"
echo DIAG3_DONE
