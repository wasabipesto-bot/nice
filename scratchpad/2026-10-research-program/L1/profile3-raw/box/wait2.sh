#!/bin/bash
until grep -q CHAIN_DONE /root/p3/chain.log; do sleep 10; done
/root/chain2.sh
