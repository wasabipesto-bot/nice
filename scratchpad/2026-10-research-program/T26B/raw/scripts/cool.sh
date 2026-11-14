#!/bin/bash
# cool.sh [MAXTEMP]: wait (at most 5 min) until the GPU is at or below MAXTEMP C (default 40; this 3080 idles at ~35 C)
T=${1:-40}
for i in $(seq 1 150); do
  t=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader); [ "$t" -le "$T" ] && break; sleep 2; done
echo "cool: $(nvidia-smi --query-gpu=temperature.gpu,power.draw,clocks.sm,power.limit --format=csv,noheader) after $((i*2)) s (threshold $T C)"
