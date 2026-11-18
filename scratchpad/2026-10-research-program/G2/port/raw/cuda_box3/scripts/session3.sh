#!/bin/bash
# on box: the one timing session. Rounds 1-2, main m1 (block re-proven first), rounds 3-6, main m2.
cd /root/g2
grep -q BUILD_DONE build_box.out || { echo "build not done"; exit 1; }
pgrep -x cargo && { echo "cargo running"; exit 1; }
echo "SESSION_START $(date -u +%T)"; nvidia-smi -q -d POWER,CLOCK > out/smi_q_start.txt
bash round3.sh 1 "v10 P A D"
bash round3.sh 2 "P A D v10"
mainrun() { sh hosts_block.sh > out/proof_block_before_$1.txt 2>&1; grep -c "exit=7" out/proof_block_before_$1.txt
  [ "$(grep -c 'exit=7' out/proof_block_before_$1.txt)" -eq 4 ] || { echo "BLOCK NOT PROVEN, no main"; return 1; }
  echo "MAIN $1 start $(date -u +%T)"; bash run_main.sh $1; echo "MAIN $1 end $(date -u +%T)"
  python3 main_summ.py client_$1.log; }
mainrun m1
bash round3.sh 3 "A D v10 P"
bash round3.sh 4 "D v10 P A"
bash round3.sh 5 "v10 P A D"
bash round3.sh 6 "P A D v10"
mainrun m2
nvidia-smi -q -d POWER,CLOCK > out/smi_q_end.txt
echo "SESSION_DONE $(date -u +%T)"
