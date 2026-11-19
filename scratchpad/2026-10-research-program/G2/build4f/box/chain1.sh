#!/bin/bash
cd /root/mo
bash coordtest.sh r1 > /root/mo/runs_coordtest.log 2>&1
bash e2e.sh e2e1
bash lib.sh lib1
bash neg.sh neg1 > /root/mo/runs_neg1.log 2>&1
echo CHAIN1-DONE > /root/mo/chain1.done
