#!/bin/bash
until grep -q "CHAIN3_DONE" /root/p2/chain3.log 2>/dev/null || grep -q FAILED /root/p2/chain2.log; do sleep 5; done
grep -q CHAIN3_DONE /root/p2/chain3.log && bash /root/chain4.sh
