#!/bin/bash
source ~/.cargo/env
cd /root/nice && git fetch -q origin rp/field-cert-prune-ept
[ -d /root/ept ] || git worktree add -q --detach /root/ept 6e4e895
cd /root/ept && git log --oneline -1
cargo test --release -j 16 -p nice_common --features gpu --no-run > /root/ab/testbuild_ept.log 2>&1 || echo "ept test build FAILED"
grep -o "target/release/deps/nice_common-[0-9a-f]*" /root/ab/testbuild_ept.log | head -1 | sed "s|^|/root/ept/|" > /root/ab/bin_ept
echo "EPT_BUILT $(cat /root/ab/bin_ept)"
