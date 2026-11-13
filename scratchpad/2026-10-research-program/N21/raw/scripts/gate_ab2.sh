#!/bin/bash
# gate_ab2.sh: the timed A/B, second protocol (the first, 07:02-07:11, is discarded: its start temperatures drifted
# from 40 to 60 C and one run overlapped untimed tests). Every run starts at <= 50 C; modes 0 (default), 9 (P+M),
# 137 (P+M+D), 41 (P+M+U), 73 (P+M+B); P and W were dropped from timing on CUDA because their SASS instruction mix
# equals mode 0's (RESULTS §4).
W=/root/n21
while pgrep -f "scripts/ab.sh" > /dev/null; do sleep 5; done
rm -f $W/stop; mkdir -p $W/logs/ab1; mv $W/logs/ab_m* $W/logs/ab1/ 2>/dev/null; mv $W/out/ab.out $W/logs/ab1/ 2>/dev/null
echo "GATE2 $(date -u +%T) load=$(cut -d' ' -f1 /proc/loadavg) temp=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader)"
COOL_C=50 BIN=X4 MODES="0 9 137 41 73" ROUNDS="1 2 3 4" bash $W/scripts/ab.sh
