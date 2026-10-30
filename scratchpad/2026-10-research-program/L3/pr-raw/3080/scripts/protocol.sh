#!/bin/bash
# Same box, interleaved trees. P1 NiceMark detailed GPU (150 s), P2 fixed
# 2e9-number windows, P4 1e10-number windows (the server's detailed field cap).
# nvidia-smi dmon (power, clocks) alongside every run; killed by PID.
export NICE_API_BASE=http://127.0.0.1:9
L=/root/logs/proto
mkdir -p $L
TREES="main rb fd"
mon() { nvidia-smi dmon -s pc -d 1 -o T > "$1" 2>&1 & echo $!; }
{ date -u; for t in $TREES; do (cd /root/$t && echo "$t $(git log --oneline -1)"); done; } > $L/trees.txt
nvidia-smi -q -d POWER,CLOCK,PERFORMANCE > $L/smi_before.txt 2>&1

for round in 1 2 3; do
  for t in $TREES; do
    M=$(mon $L/p1_dmon_${t}_r$round.txt)
    /root/$t/target/release/nice_client detailed --gpu --benchmark --benchmark-secs 150 \
      < /dev/null > $L/p1_${t}_r$round.txt 2>&1
    kill $M
    sleep 5
  done
done
echo P1_DONE >> $L/trees.txt

for round in 1 2 3; do
  for base in 40 50; do
    for t in $TREES; do
      M=$(mon $L/p2_dmon_${t}_b${base}_r$round.txt)
      /root/$t/target/release/examples/fdbench $base 2e9 5 > $L/p2_${t}_b${base}_r$round.txt 2>&1
      kill $M
      sleep 2
    done
  done
done
echo P2_DONE >> $L/trees.txt

for round in 1 2 3; do
  for base in 50 52; do
    for t in $TREES; do
      M=$(mon $L/p4_dmon_${t}_b${base}_r$round.txt)
      /root/$t/target/release/examples/fdbench $base 1e10 2 > $L/p4_${t}_b${base}_r$round.txt 2>&1
      kill $M
      sleep 2
    done
  done
done
nvidia-smi -q -d POWER,CLOCK,PERFORMANCE > $L/smi_after.txt 2>&1
date -u >> $L/trees.txt
echo PROTOCOL_DONE >> $L/trees.txt
