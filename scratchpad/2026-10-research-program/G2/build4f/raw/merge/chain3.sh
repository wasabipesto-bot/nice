#!/bin/bash
# after the trunk merge: binaries and unit tests, lint and suites, a shorter end-to-end + library on the same fields, the negatives
cd /root/mo
bash build1.sh /root/mo/logs/b3
bash lint.sh /root/mo/logs/lint3
N64=6 T65=77777 bash e2e.sh e2e3
N64=6 T65=77777 bash lib.sh lib3
bash neg.sh neg3 > /root/mo/runs_neg3.log 2>&1
source ~/.cargo/env
(cd /root/mt && git fetch -q /root/mo/b2.bundle dev/mo-client:refs/remotes/b/m && git checkout -q 9b790647 && git log --oneline -1 > /root/mo/logs/trunk_head.txt && CARGO_TARGET_DIR=/root/t/mt cargo build --release -p nice_client --features cubecl-cuda > /root/mo/logs/b_trunk3.log 2>&1; echo rc=$? >> /root/mo/logs/b_trunk3.log; cp /root/t/mt/release/nice_client /root/mo/bin/nice_trunk)
bash default.sh def3 > /root/mo/runs_def3.log 2>&1
echo CHAIN3-DONE > /root/mo/chain3.done
