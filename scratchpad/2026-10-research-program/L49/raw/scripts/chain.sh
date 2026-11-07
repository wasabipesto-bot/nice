#!/bin/bash
# Start the NiceMark rounds once the A/B rounds are done.
R=/home/claude/projects/nice/scratchpad/2026-10-research-program/L49/raw
until grep -q "^#### done" $R/ab-runs.txt 2>/dev/null; do sleep 20; done
exec $R/scripts/run_nicemark.sh
