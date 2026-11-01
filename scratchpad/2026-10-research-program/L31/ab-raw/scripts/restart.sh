#!/bin/bash
cd /root/l31b
for p in $(pgrep -x cargo); do kill $p; done
sleep 3
cp bin/B bin/B_pre
rm -rf src/B && mkdir -p src/B && tar xzf B.tgz -C src/B && md5sum src/B/common/src/cubecl_join.rs
rm -f logs/b.done logs/testbins.done logs/builds.done
mv logs/chain_build.out logs/chain_build_pre.out; mv logs/build_B.log logs/build_B_pre.log; rm -f logs/build_A.log
nohup ./chain_build.sh > logs/chain_build.out 2>&1 < /dev/null &
nohup ./test.sh smoke_cert B_pre cubecl_join::tests::cubecl_cuda_top_certificates_match_the_lockstep_scan_and_the_cpu > /dev/null 2>&1 < /dev/null &
nohup ./master.sh > logs/master.out 2>&1 < /dev/null &
sleep 2
ps aux | grep -E "chain_build|master|test.sh|B_pre" | grep -v grep | cut -c1-120
