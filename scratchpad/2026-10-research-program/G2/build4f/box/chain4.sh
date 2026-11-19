#!/bin/bash
cd /root/mo
bash trunk.sh /root/mo/logs/trunk4
source ~/.cargo/env
(cd /root/mt && git fetch -q /root/mc HEAD:refs/remotes/mc/head && git checkout -q 9b790647 && git log --oneline -1 > /root/mo/logs/trunk_head4.txt && CARGO_TARGET_DIR=/root/t/mt cargo build --release -p nice_client --features cubecl-cuda > /root/mo/logs/b_trunk4.log 2>&1; echo rc=$? >> /root/mo/logs/b_trunk4.log; cp /root/t/mt/release/nice_client /root/mo/bin/nice_trunk)
bash default.sh def4 > /root/mo/runs_def4.log 2>&1
echo CHAIN4-DONE > /root/mo/chain4.done
