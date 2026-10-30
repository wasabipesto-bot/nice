#!/bin/bash
# Lever experiments at 1e14 on the knob commit (455d4c0): SLOTS 32 / 8 and EPT 1 against a control, two
# interleaved rounds, unprofiled; then EPT 1 profiled. Builds the knob binary first.
source ~/.cargo/env
cd /root/nice
git fetch -q origin rp/gpu-profile-2 && git checkout -q --detach FETCH_HEAD && echo "tree: $(git log --oneline -1)"
t0=$(date +%s)
cargo test --release -j 10 -p nice_common --features gpu --no-run > /root/p2/testbuild_x.log 2>&1 || { echo "x build FAILED"; tail -40 /root/p2/testbuild_x.log; exit 1; }
bin=$(grep -o "target/release/deps/nice_common-[0-9a-f]*" /root/p2/testbuild_x.log | head -1)
cp /root/nice/$bin /root/nice_common_test_x; md5sum /root/nice_common_test_x
echo "x built in $(( $(date +%s) - t0 )) s commit=$(git rev-parse --short HEAD)"
export BIN=/root/nice_common_test_x
R=/root/run2.sh
for r in 1 2; do
  $R x14_ctl_r$r 20 1e14 0
  NICE_EXP_SLOTS=32 $R x14_slots32_r$r 20 1e14 0
  NICE_EXP_SLOTS=8 $R x14_slots8_r$r 20 1e14 0
  NICE_EXP_JOIN_EPT=1 $R x14_ept1_r$r 20 1e14 0
done
NICE_EXP_JOIN_EPT=1 $R x14_ept1_prof_r1 20 1e14 1
echo CHAIN2_DONE $(date -u +%T)
