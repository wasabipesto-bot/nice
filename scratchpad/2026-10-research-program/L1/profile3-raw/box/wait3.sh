#!/bin/bash
until grep -q CHAIN2_DONE /root/p3/chain2.log && grep -q "SETUP_X_DONE\|FAILED" /root/p3/setup_x.log; do sleep 10; done
grep -q SETUP_X_DONE /root/p3/setup_x.log && /root/chain3.sh
