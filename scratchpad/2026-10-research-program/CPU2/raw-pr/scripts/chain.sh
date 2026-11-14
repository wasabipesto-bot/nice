#!/bin/bash
# After the b62 42-thread block: b60 42 threads, the 8-thread blocks (first
# 1024 partitions of the slice), b64 42 threads (1 round), the release tests
# and mutants, then NiceMark (4 rounds).
until grep -q '^done' /root/out/ab.log 2>/dev/null; do sleep 10; done
mv /root/out/ab.log /root/out/ab-b62-42.log
/root/ab.sh 3 1 b60-42:60:1157209632114824200908:10000000000000000:0:0:
mv /root/out/ab.log /root/out/ab-b60-42.log
/root/ab.sh 3 1 b62s0-8:62:4473066762334864396992:100000000000000000:8:0:1024 b60-8:60:1157209632114824200908:10000000000000000:8:0:1024
mv /root/out/ab.log /root/out/ab-8.log
/root/ab.sh 1 1 b64s0-42:64:71779931862957161709568:100000000000000000:0:0:
mv /root/out/ab.log /root/out/ab-b64-42.log
bash /root/tests.sh
/root/nicemark.sh 4 1
echo chain-done > /root/out/chain.done
