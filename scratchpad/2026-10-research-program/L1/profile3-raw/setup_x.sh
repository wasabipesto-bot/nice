#!/bin/bash
# Build the knob binary (rp/gpu-profile-3 with SLOTS/EPT/SURV_PER_PREFIX/SLICE_MULT knobs) beside the chain, niced, -j4.
source ~/.cargo/env
cd /root/nice
git fetch -q origin rp/gpu-profile-3
rm -rf /root/nice-x; git worktree prune; git worktree add -q --detach /root/nice-x FETCH_HEAD
cd /root/nice-x && echo "tree: $(git log --oneline -1)"
t0=$(date +%s)
CARGO_TARGET_DIR=/root/nice/target nice -n 19 cargo test --release -j 4 -p nice_common --features gpu --no-run > /root/p3/testbuild_x.log 2>&1 || { echo "build FAILED"; tail -40 /root/p3/testbuild_x.log; exit 1; }
bin=$(grep -o "target/release/deps/nice_common-[0-9a-f]*" /root/p3/testbuild_x.log | head -1)
cp /root/nice/$bin /root/nice_common_x
md5sum /root/nice_common_x
grep -c NICE_EXP_SLICE_MULT /root/nice_common_x
echo "built in $(( $(date +%s) - t0 )) s from $bin commit=$(git rev-parse --short HEAD)"
echo SETUP_X_DONE $(date -u +%T)
