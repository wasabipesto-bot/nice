#!/bin/bash
cd /w/harness
npm i --no-save --no-audit --no-fund playwright@1.62.0 >/dev/null 2>&1
export NICE_E2E_ROOT=/w/site-new
node seedprobe.mjs --software --out /w/out/seedprobe-swiftshader.json > /w/out/seedprobe-swiftshader.log 2>&1; echo "rc=$?" >> /w/out/seedprobe-swiftshader.log
node shapes.mjs --software --subset ci --shapes 0,1,61,64,128,1000:333333 --out /w/out/shapes-ci-swiftshader.jsonl > /w/out/shapes-ci-swiftshader.log 2>&1; echo "rc=$?" >> /w/out/shapes-ci-swiftshader.log
node hw/parity.mjs --software --subset hw --out /w/out/parity-hw-swiftshader.jsonl > /w/out/parity-hw-swiftshader.log 2>&1; echo "rc=$?" >> /w/out/parity-hw-swiftshader.log
