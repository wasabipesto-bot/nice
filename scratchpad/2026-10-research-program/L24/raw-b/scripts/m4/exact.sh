#!/bin/sh
# Exactness on the M4 (new build): adapter + hardware assertion, seed probe,
# full parity list with the 2e8 windows, run shapes, a seeded sweep.
. "$HOME/claude-exp-2026-11-01-webfd/scripts/env.sh"
cd "$D/harness"
export NICE_E2E_ROOT="$D/site-new"
O="$D/out"
pmset -g therm > "$O/therm-exact-before.txt" 2>&1
node hw/adapter.mjs --expect-vendor apple --out "$O/adapter-new.json" > "$O/adapter-new.log" 2>&1; echo "rc=$?" >> "$O/adapter-new.log"
node hw/adapter.mjs --expect-vendor apple --chromium-arg=--enable-webgpu-developer-features --out "$O/adapter-new-devfeatures.json" > "$O/adapter-new-devfeatures.log" 2>&1; echo "rc=$?" >> "$O/adapter-new-devfeatures.log"
node seedprobe.mjs --out "$O/seedprobe-m4.json" > "$O/seedprobe-m4.log" 2>&1; echo "rc=$?" >> "$O/seedprobe-m4.log"
node hw/parity.mjs --subset hw --extra --expect-vendor apple --out "$O/parity-hw-m4.jsonl" > "$O/parity-hw-m4.log" 2>&1; echo "rc=$?" >> "$O/parity-hw-m4.log"
node shapes.mjs --subset hw --set partial,boundary,nearmiss,gain,fallback --shapes 0,1,61,64,128,1000:333333 --out "$O/shapes-hw-m4.jsonl" > "$O/shapes-hw-m4.log" 2>&1; echo "rc=$?" >> "$O/shapes-hw-m4.log"
node hw/parity.mjs --subset hw --set random --random 10 --expect-vendor apple --out "$O/parity-random-m4.jsonl" > "$O/parity-random-m4.log" 2>&1; echo "rc=$?" >> "$O/parity-random-m4.log"
pmset -g therm > "$O/therm-exact-after.txt" 2>&1
echo EXACT_DONE
