#!/bin/bash
R=/home/claude/projects/nice/scratchpad/2026-10-research-program/L49/raw
until grep -q "^### perf done" $R/perf-runs-v2.txt 2>/dev/null; do sleep 5; done
exec $R/scripts/run_ab_v2b.sh
