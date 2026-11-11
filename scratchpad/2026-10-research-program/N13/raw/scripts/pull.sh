#!/bin/sh
# pull.sh: copy demoux's $W/out (logs) and scripts to ../demoux on ivory.
cd "$(dirname "$0")"; mkdir -p ../demoux
rsync -a justin@demoux:/tmp/claude-exp-2026-11-11-amd/out/ ../demoux/
