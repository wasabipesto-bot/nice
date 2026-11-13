#!/bin/bash
# cool.sh [MAXTEMP]: wait (at most 5 min) until the GPU is at or below MAXTEMP (default 40 C) and idle
T=${1:-40}; for i in $(seq 1 150); do
  t=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader); [ "$t" -le "$T" ] && break; sleep 2; done
echo "cool: $(nvidia-smi --query-gpu=temperature.gpu,power.draw,clocks.sm --format=csv,noheader)"
