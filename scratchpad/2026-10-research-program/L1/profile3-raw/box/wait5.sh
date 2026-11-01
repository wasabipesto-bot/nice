#!/bin/bash
until grep -q CHAIN4_DONE /root/p3/chain4.log; do sleep 10; done
/root/chain5.sh
