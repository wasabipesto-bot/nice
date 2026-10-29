#!/bin/bash
# Build the A/B trees on the Vast box (run under nohup).
#   /root/main  = rp/pr-prune-a        (upstream main 2709d3f + the PR's test-only harness commit)
#   /root/pr    = pr/field-cert-prune  (the PR branch)
#   /root/xmain = rp/pr-prune-exp-main (A + profile, EPT override, flush knob/overrun counter; throwaway)
#   /root/xpr   = rp/pr-prune-exp-pr   (B + the same; throwaway)
# x-trees build in their sibling's target dir after the sibling's binaries are copied out.
source ~/.cargo/env
mkdir -p /root/ab /root/bins
cd /root/nice
git fetch -q https://github.com/wasabipesto/nice.git main && echo "upstream main: $(git rev-parse --short FETCH_HEAD)"
git fetch -q origin pr/field-cert-prune rp/pr-prune-a rp/pr-prune-exp-main rp/pr-prune-exp-pr
for t in main:rp/pr-prune-a pr:pr/field-cert-prune xmain:rp/pr-prune-exp-main xpr:rp/pr-prune-exp-pr; do
  d=${t%%:*}; b=${t#*:}
  [ -d /root/$d ] || git worktree add -q --detach /root/$d origin/$b
  echo "$d $(git -C /root/$d log --oneline -1)"
done
build() { # tree, target-dir name, jobs
  local tree=$1 tgt=/root/tgt_$2 j=$3
  cd /root/$tree
  CARGO_TARGET_DIR=$tgt cargo build --release -j $j -p nice_client --features gpu > /root/ab/build_$tree.log 2>&1 || { echo "[$tree] client build FAILED"; tail -30 /root/ab/build_$tree.log; return 1; }
  CARGO_TARGET_DIR=$tgt cargo test --release -j $j -p nice_common --features gpu --no-run > /root/ab/testbuild_$tree.log 2>&1 || { echo "[$tree] test build FAILED"; tail -40 /root/ab/testbuild_$tree.log; return 1; }
  local bin=$(grep -o "tgt_$2/release/deps/nice_common-[0-9a-f]*" /root/ab/testbuild_$tree.log | head -1)
  mkdir -p /root/bins/$tree
  cp /root/$bin /root/bins/$tree/nice_common_test && cp $tgt/release/nice_client /root/bins/$tree/nice_client
  echo "[$tree] built $(date -u +%T) commit=$(git rev-parse --short HEAD) from $bin"
}
(build main a 10 && build xmain a 10) &
(build pr b 10 && build xpr b 10) &
wait
df -h /root | tail -1
echo SETUP_DONE $(date -u +%T)
