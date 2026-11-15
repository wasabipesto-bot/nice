#!/bin/bash
# after chain.sh: the extension queue with main
cd /root/t28
until grep -q "chain done" runs.log; do sleep 10; done
./run_queue.sh 54d0aac4 queue_ext.json 8400 X_main --threads 8
echo "$(date -u +%FT%TZ) chain2 done" >> runs.log
