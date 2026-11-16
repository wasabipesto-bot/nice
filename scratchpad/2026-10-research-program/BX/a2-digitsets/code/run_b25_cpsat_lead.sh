#!/bin/bash
cd /home/claude/projects/nice/scratchpad/2026-10-research-program/BX/a2-digitsets/code
export REALSPLITS=1
REALSPLITS=1 nice -n 19 timeout 590 uv run --with ortools python3 solver_fixed.py 18,24 alt 280
for v in $(seq 8 24); do echo -n "$v "; LEAD=$v nice -n 19 timeout 590 uv run --with ortools python3 solver_scaling.py 25 550; done
