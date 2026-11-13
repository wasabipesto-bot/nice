#!/bin/bash
# gate_ab3.sh: after the b62 A/B (ab2.out), the same protocol at b64 1e17 and b60 1e16: every run starts at <= 50 C,
# modes 0, 9 (P+M), 137 (P+M+D), 73 (P+M+B; at b60 the same code as 9: an A/A pair), 3 rounds.
W=/root/n21
until tr -d '\000' < $W/out/ab2.out | grep -q AB_DONE; do sleep 10; done
echo "GATE3 $(date -u +%T) temp=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader)"
F60=1447429612114824200908; F64=58557331862957161709568
COOL_C=50 BIN=X4 MODES="0 9 137 73" ROUNDS="1 2 3" FIELDS="b64:64:1:1e17:$F64 b60:60:1:1e16:$F60" bash $W/scripts/ab.sh
