#!/bin/sh
# on the box, second run order (after finding that 9a4f7406's counters differ in meaning from c0c357ae's)
cd /root/t2
./run_queue.sh 9a4f7406 QA_9a4f_first.json 8121 QA_9a4f_first --threads 8
./run_queue.sh 9a4f7406 QB_9a4f_b58.json 8122 QB_9a4f_b58 --threads 8
