#!/bin/bash
# GPU sampler: every 15 s until /root/ab/STOP_SMI exists.
while [ ! -e /root/ab/STOP_SMI ]; do
  echo "$(date -u +%T) $(nvidia-smi --query-gpu=clocks.sm,clocks.mem,power.draw,temperature.gpu,utilization.gpu,pstate --format=csv,noheader)"
  sleep 15
done
