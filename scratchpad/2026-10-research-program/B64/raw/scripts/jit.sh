#!/bin/bash
# jit.sh NAME: replay the run's PTX cache through the driver JIT (join kernels) -> logs/NAME_jit.txt
cd /root/b64/scripts && python3 ptxjit.py --only join /root/b64/ptx/$1 > /root/b64/logs/$1_jit.txt 2>&1
