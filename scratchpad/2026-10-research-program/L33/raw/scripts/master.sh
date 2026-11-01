#!/bin/bash
# After exactness and the client builds: the A/B, then NiceMark.
L=/root/l33/logs
while [ ! -f $L/chainX.done ] || [ ! -f $L/clients.done ]; do sleep 10; done
echo "MASTER start AB $(date -u +%T)" > $L/master.log
/root/l33/scripts/chain_ab.sh >> $L/master.log 2>&1
echo "MASTER start NM $(date -u +%T)" >> $L/master.log
/root/l33/scripts/chain_nm.sh 2 6 >> $L/master.log 2>&1
echo "MASTER done $(date -u +%T)" >> $L/master.log
