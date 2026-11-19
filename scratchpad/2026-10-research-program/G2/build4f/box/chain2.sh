#!/bin/bash
# round 2 (the explicit coordinate id): coordinator rules, e2e, library, negatives; then the default routes vs the trunk; lint and suites
cd /root/mo
bash coordtest.sh r2 > /root/mo/runs_coordtest2.log 2>&1
bash e2e.sh e2e2
bash lib.sh lib2
bash neg.sh neg2 > /root/mo/runs_neg2.log 2>&1
# the trunk's client at this branch's base, own checkout and target dir
source ~/.cargo/env
[ -d /root/mt ] || git clone -q /root/mo/b0.bundle /root/mt
(cd /root/mt && git checkout -q 4abfab5 && CARGO_TARGET_DIR=/root/t/mt cargo build --release -p nice_client --features cubecl-cuda > /root/mo/logs/b_trunk.log 2>&1; echo rc=$? >> /root/mo/logs/b_trunk.log; cp /root/t/mt/release/nice_client /root/mo/bin/nice_trunk)
bash default.sh def2 > /root/mo/runs_def2.log 2>&1
bash lint.sh /root/mo/logs/lint2
echo CHAIN2-DONE > /root/mo/chain2.done
