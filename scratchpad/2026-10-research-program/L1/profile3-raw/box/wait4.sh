#!/bin/bash
until grep -q CHAIN3_DONE /root/p3/chain3.log; do sleep 10; done
/root/chain4.sh
