#!/bin/bash
# gate_ab.sh: once tests_b.sh is done and nothing else runs (no cargo, no test binary, no lavapipe), the timed CUDA
# A/B: binary X3, NICE_EXP_N22 modes 0 2 10 16 32, b62 1e17 and b64 1e17, three rounds, order rotated, every run
# started at <= 50 C. Output out/ab.out.
W=/root/n22
until [ -e $W/logs/t/tests_b.done ]; do sleep 15; done
while pgrep -f 'cargo|rustc|/root/bin/X|bin/X2|bin/X3|spvdump' > /dev/null; do sleep 15; done
echo "GATE_OPEN $(date -u +%T) load=$(cut -d' ' -f1 /proc/loadavg) $(nvidia-smi --query-gpu=power.limit,temperature.gpu --format=csv,noheader)"
COOL_C=50 BIN=X3 MODES="0 2 10 16 32" ROUNDS="1 2 3" bash $W/scripts/ab.sh
