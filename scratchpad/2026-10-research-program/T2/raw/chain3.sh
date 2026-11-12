#!/bin/sh
# on the box: after chain2 (9a4f7406 on b58). QE (9a4f7406 on b60, ~37 s a field) runs until stopped at the deadline.
cd /root/t2
while pgrep -f "^/bin/sh ./chain2.sh" > /dev/null; do sleep 10; done
./run_queue.sh c0c357ae QC1_oracle_8bd1_9bde.json 8123 QC1_oracle_8bd1_9bde --threads 8
for b in 8c088a28 c72e2c6f 18cba8bc cb38b917; do
  [ -x /root/bin/nice-$b ] && ./run_queue.sh $b QD_$b.json 8130 QD_$b --threads 8
done
./run_queue.sh 6f060a94 Q3s_6f06.json 8113 Q3s_6f06 --threads 8
./run_queue.sh 9a4f7406 QE_9a4f_b60.json 8125 QE_9a4f_b60 --threads 8
