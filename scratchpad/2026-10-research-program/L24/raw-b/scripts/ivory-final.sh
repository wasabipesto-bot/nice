#!/bin/bash
# SwiftShader on ivory, final build (5d4ce8a): e2e run.sh, then the harness.
export PATH=$HOME/l24b-work/bin:$PATH
O=$HOME/l24b-work/out
cd /home/claude/projects/nice/.worktrees/pr-web-fd
s=$SECONDS; nice -n 19 bash wasm-client/e2e/run.sh > $O/e2e-run-sh.log 2>&1; echo "rc=$? wall=$((SECONDS-s))s" >> $O/e2e-run-sh.log
s=$SECONDS; nice -n 19 podman --cgroup-manager=cgroupfs run --rm -v $HOME/l24b-work:/w --ipc=host mcr.microsoft.com/playwright:v1.62.0-noble bash -c '
cd /w/harness; npm i --no-save --no-audit --no-fund playwright@1.62.0 >/dev/null 2>&1
export NICE_E2E_ROOT=/w/site-new
node hw/parity.mjs --software --subset ci --out /w/out/final-parity-ci-swiftshader.jsonl > /w/out/final-parity-ci-swiftshader.log 2>&1; echo "rc=$?" >> /w/out/final-parity-ci-swiftshader.log
node seedprobe.mjs --software --out /w/out/final-seedprobe-swiftshader.json > /w/out/final-seedprobe-swiftshader.log 2>&1; echo "rc=$?" >> /w/out/final-seedprobe-swiftshader.log
node shapes.mjs --software --subset ci --shapes 0,1,61,64,128,1000:333333 --out /w/out/final-shapes-ci-swiftshader.jsonl > /w/out/final-shapes-ci-swiftshader.log 2>&1; echo "rc=$?" >> /w/out/final-shapes-ci-swiftshader.log
node hw/parity.mjs --software --subset hw --out /w/out/final-parity-hw-swiftshader.jsonl > /w/out/final-parity-hw-swiftshader.log 2>&1; echo "rc=$?" >> /w/out/final-parity-hw-swiftshader.log
NICE_E2E_ROOT=/w/site-old node hw/parity.mjs --software --subset ci --out /w/out/old-parity-ci-swiftshader.jsonl > /w/out/old-parity-ci-swiftshader.log 2>&1; echo "rc=$?" >> /w/out/old-parity-ci-swiftshader.log
' > $O/ivory-harness.out 2>&1; echo "harness wall=$((SECONDS-s))s" >> $O/ivory-harness.out
echo done > $O/ivory-final.done
