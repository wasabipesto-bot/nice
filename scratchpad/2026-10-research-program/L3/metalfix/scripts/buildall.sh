#!/bin/sh
# Builds: sweep test binary (fix + diagnostic sweep), nice_client for fix, pr, main.
. "$HOME/claude-exp-2026-10-31-fd-metal/scripts/env.sh"
cd "$D/src" || exit 10
cp "$D/patch/cubecl_detailed_fd_sweep.rs" common/src/cubecl_detailed_fd.rs || exit 11
s=$(date +%s)
cargo test --release --offline -p nice_common --features cubecl --no-run 2> "$D/logs/testbuild-c5.err"; rc=$?
echo "TEST_BUILD_SECS $(( $(date +%s)-s )) rc $rc"; [ $rc -eq 0 ] || { tail -30 "$D/logs/testbuild-c5.err"; exit 12; }
exe=$(sed -n 's/.*Executable unittests src\/lib.rs (\(.*\))$/\1/p' "$D/logs/testbuild-c5.err" | head -1)
cp "$exe" "$D/bin/nice_common-test-c5" || exit 13
cp "$D/patch/cubecl_detailed_fd_fix.rs" common/src/cubecl_detailed_fd.rs || exit 14
md5 -q common/src/cubecl_detailed_fd.rs
build_client() { # tree target tag
  cd "$1" || exit 20
  git log --oneline -1; git status --short
  s=$(date +%s)
  CARGO_TARGET_DIR="$2" cargo build --release --offline -p nice_client --features cubecl > "$D/logs/clientbuild-$3.log" 2>&1; rc=$?
  echo "CLIENT_BUILD $3 secs $(( $(date +%s)-s )) rc $rc"; [ $rc -eq 0 ] || { tail -30 "$D/logs/clientbuild-$3.log"; exit 21; }
  cp "$2/release/nice_client" "$D/bin/nice_client-$3" || exit 22
}
build_client "$D/src" "$D/target" fix
cd "$D/src"
test -e "$D/src-pr" || git worktree add -q --detach "$D/src-pr" 18cba8b
test -e "$D/src-main" || git worktree add -q --detach "$D/src-main" 946ec15
build_client "$D/src-pr" "$D/target-pr" pr
build_client "$D/src-main" "$D/target-main" main
ls -la "$D/bin"
echo BUILDALL_DONE
