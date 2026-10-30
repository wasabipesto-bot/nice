#!/bin/sh
. "$HOME/claude-exp-2026-10-30-fd/env.sh"
cd "$D/src-pr" || exit 10
cp "$D/cubecl_detailed_fd.rs" common/src/cubecl_detailed_fd.rs || exit 11
git diff --stat
cargo clean --release --offline -p nice_common
s=$(date +%s)
cargo test --release --offline -p nice_common --features cubecl --no-run 2> "$D/logs/testbuild-prdiag.err"; rc=$?
tail -5 "$D/logs/testbuild-prdiag.err"
echo "TEST_BUILD_SECS $(( $(date +%s)-s )) rc $rc"
[ $rc -eq 0 ] || { cat "$D/logs/testbuild-prdiag.err"; exit 12; }
exe=$(sed -n 's/.*Executable unittests src\/lib.rs (\(.*\))$/\1/p' "$D/logs/testbuild-prdiag.err" | head -1)
case "$exe" in /*) ;; *) exe="$D/src-pr/$exe";; esac
cp "$exe" "$D/bin/nice_common-test-prdiag" || exit 14
cd common
"$D/bin/nice_common-test-prdiag" --list --ignored 2>&1 | grep zz_metal
for w in default 1; do
  s=$(date +%s)
  echo "=== DIAG wide=$w"
  if [ $w = 1 ]; then export NICE_CUBECL_WIDE=1; fi
  RUST_LOG=warn "$D/bin/nice_common-test-prdiag" zz_metal_diag --ignored --test-threads=1 --nocapture
  echo "=== RESULT wide=$w rc=$? secs=$(( $(date +%s)-s ))"
done
echo DIAG_DONE
