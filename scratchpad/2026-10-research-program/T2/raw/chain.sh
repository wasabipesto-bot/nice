#!/bin/sh
# on the box: the audit's run order (one GPU, one client at a time)
cd /root/t2
./run_queue.sh c0c357ae Q1_c0c.json 8111 Q1_c0c --threads 8
./run_queue.sh c0c357ae Q2_oracle_b58.json 8112 Q2_oracle_b58 --threads 8
./run_queue.sh 6f060a94 Q3_6f06.json 8113 Q3_6f06 --threads 8
./run_queue.sh 9a4f7406 Q5a_9a4f_own.json 8115 Q5a_9a4f_own --threads 8
[ -x /root/bin/nice-8bd154bc ] && ./run_queue.sh 8bd154bc Q5b_8bd1_own.json 8116 Q5b_8bd1_own --threads 8
./run_queue.sh c0c357ae Q4_oracle_b60.json 8114 Q4_oracle_b60 --threads 8
