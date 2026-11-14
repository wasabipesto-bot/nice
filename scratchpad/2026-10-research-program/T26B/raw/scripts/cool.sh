#!/bin/bash
# cool.sh [MAXTEMP]: wait (at most 5 min) until the GPU is at or below MAXTEMP and idle. This 3080 idles at 41-45 C
# (it never reached 42 within 5 min after a run), so the threshold is at least 46 C: back at idle temperature.
T=${1:-40}; [ "$T" -lt 46 ] && T=46
for i in $(seq 1 150); do
  t=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader); [ "$t" -le "$T" ] && break; sleep 2; done
echo "cool: $(nvidia-smi --query-gpu=temperature.gpu,power.draw,clocks.sm --format=csv,noheader) after $((i*2)) s (threshold $T C)"
