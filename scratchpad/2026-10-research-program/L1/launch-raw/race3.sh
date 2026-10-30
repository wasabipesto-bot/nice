#!/bin/bash
# The flush-decision race at 1e16 in main's layouts (survivor-bound, 4-8
# partitions per launch, one cube per work item): the experiment binary
# without the barrier, counting the planes per flush. 2 fields per base,
# the 10 GB card's budget.
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH
until [ -f /root/logs/chain.done ]; do sleep 15; done
/root/run.sh /root/bin/exp race_e16_sync0_r1 1e16 2 NICE_TEST_JOIN_MAX_BUFFER=2684354560 NICE_EXP_SLOTS=16 NICE_EXP_FLUSH_SYNC=0
/root/summ.sh /root/logs/race_e16_sync0_r1.log
echo RACE3_DONE $(date -u +%T)
