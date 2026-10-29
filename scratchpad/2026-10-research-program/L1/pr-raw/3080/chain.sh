#!/bin/bash
# After the A/B: profile, NiceMark, then the exactness tests (run under nohup).
until grep -q AB_DONE /root/ab/ab.log; do sleep 15; done
FLUSH=512 /root/prof.sh > /root/ab/prof.log 2>&1
FLUSH=512 /root/nicemark.sh > /root/ab/nm.log 2>&1
/root/tests.sh > /root/ab/tests.log 2>&1
echo CHAIN_DONE $(date -u +%T) >> /root/ab/tests.log
