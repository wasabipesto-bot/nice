#!/bin/bash
# Build trees on the 4090 box (run under nohup). Usage: setup.sh <tree>... where tree is one of
#   main  = upstream main 2709d3f + the two test-only harness commits 71a085e, 2d740d3 cherry-picked (A)
#   ept   = rp/field-cert-prune-ept 6e4e895 (85b5b4e + prune + NICE_EXP_JOIN_EPT override)
#   prune = origin/pr/field-cert-prune (the prune rebased on 2709d3f) (B); harness commits added if missing
#   base / oldprune = the old pair 2d740d3 / 4670ffe (fallback)
source ~/.cargo/env
mkdir -p /root/ab
cd /root/nice
G="git -c user.name=box -c user.email=box@localhost"
git fetch -q origin rp/field-cert-prune rp/field-cert-prune-base rp/field-cert-prune-ept
git fetch -q https://github.com/wasabipesto/nice.git main && git tag -f upstream-main FETCH_HEAD > /dev/null
echo "upstream main: $(git rev-parse --short upstream-main)"
has_harness() { grep -q NICE_TEST_JOIN_STARTS /root/$1/common/src/cubecl_join.rs; }
mk() {
  t=$1
  [ -d /root/$t ] && return 0
  case $t in
    main) git worktree add -q --detach /root/main 2709d3f && (cd /root/main && $G cherry-pick 71a085e 2d740d3 > /root/ab/cherry_main.log 2>&1) || { echo "[main] cherry-pick FAILED"; return 1; } ;;
    ept) git worktree add -q --detach /root/ept 6e4e895 ;;
    prune) git fetch -q origin pr/field-cert-prune && git worktree add -q --detach /root/prune FETCH_HEAD || return 1
           if ! has_harness prune; then (cd /root/prune && $G cherry-pick 71a085e 2d740d3 > /root/ab/cherry_prune.log 2>&1) || { echo "[prune] cherry-pick FAILED"; return 1; }; fi ;;
    base) git worktree add -q --detach /root/base 2d740d3 ;;
    oldprune) git worktree add -q --detach /root/oldprune 4670ffe ;;
  esac
}
J=${J:-$(( $(nproc) / $# ))}
build() {
  mk $1 || return 1
  cd /root/$1
  echo "[$1] $(git log --oneline -3 | tr '\n' ';') -j $J $(date -u +%T)"
  has_harness $1 || echo "[$1] WARNING: harness lacks NICE_TEST_JOIN_STARTS"
  cargo test --release -j $J -p nice_common --features gpu --no-run > /root/ab/testbuild_$1.log 2>&1 || { echo "[$1] test build FAILED"; return 1; }
  grep -o "target/release/deps/nice_common-[0-9a-f]*" /root/ab/testbuild_$1.log | head -1 | sed "s|^|/root/$1/|" > /root/ab/bin_$1
  echo "[$1] test binary $(cat /root/ab/bin_$1) $(date -u +%T)"
  cargo build --release -j $J -p nice_client --features gpu > /root/ab/build_$1.log 2>&1 || { echo "[$1] client build FAILED"; return 1; }
  echo "[$1] client built $(date -u +%T); target $(du -sh /root/$1/target | cut -f1)"
}
for t in "$@"; do build $t & done; wait
echo "SETUP_DONE $* $(date -u +%T)"
