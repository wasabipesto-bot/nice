#!/bin/bash
# gate_ab4.sh: the CUDA timing of switch Z (with D) and of P alone, b62 1e17 only, binary X5 (exp head 2d93b12e),
# modes 0, 1 (P), 2 (L), 393 (P+M+D+Z), 3 rounds, every run at <= 50 C, once every untimed job has finished.
W=/root/n21
until grep -q G_DONE $W/logs/t/stream_G.out 2>/dev/null && grep -q L_DONE $W/logs/t/stream_L.out 2>/dev/null && \
      grep -q AFTER_AB_DONE $W/out/after_ab.out && grep -q DRYRUNS_DONE $W/out/dryruns.out; do sleep 20; done
sleep 10; echo "GATE4 $(date -u +%T) load=$(cut -d' ' -f1 /proc/loadavg) temp=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader)"
F62=7520566762397899821056
COOL_C=50 BIN=X5 MODES="0 1 2 393" ROUNDS="1 2 3" FIELDS="z62:62:1:1e17:$F62" bash $W/scripts/ab.sh
