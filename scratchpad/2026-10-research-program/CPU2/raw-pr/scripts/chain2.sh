#!/bin/bash
# After the main chain: the reviewed commit e0bf513e ("rev") against the
# branch head ("br"), b62 slice 0, 42 threads, 2 rounds: does L1/M1 cost speed?
until test -e /root/out/chain.done; do sleep 10; done
/root/ab_rev.sh 2 1 b62s0-42rev:62:4473066762334864396992:100000000000000000:0:0:
echo done > /root/out/chain2.done
