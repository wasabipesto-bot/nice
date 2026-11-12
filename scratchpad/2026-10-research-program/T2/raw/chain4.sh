#!/bin/sh
# replacement box 60389955: the base-60 queues in the prepared order; each build's target dir is deleted after its queue.
cd /root/t2
w() { while [ ! -x /root/bin/nice-$1 ]; do sleep 15; done; }
done_b() { rm -rf /root/t/$1; echo "$(date -u +%FT%TZ) removed target $1" >> /root/t2/runs.log; }
w c0c357ae; ./run_queue.sh c0c357ae QC1_oracle_8bd1_9bde.json 8123 QC1_oracle_8bd1_9bde --threads 8; done_b c0c357ae
for b in 8c088a28 c72e2c6f 18cba8bc cb38b917; do w $b; ./run_queue.sh $b QD_$b.json 8130 QD_$b --threads 8; done_b $b; done
w 6f060a94; ./run_queue.sh 6f060a94 Q3s_6f06.json 8113 Q3s_6f06 --threads 8; done_b 6f060a94
w 9a4f7406; ./run_queue.sh 9a4f7406 QE2_9a4f_b60_byshare.json 8125 QE2_9a4f_b60 --threads 8
