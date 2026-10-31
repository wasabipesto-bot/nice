#!/bin/sh
# Device record and the Metal compiler control: the half-shift reproducer must still fail here.
. "$HOME/claude-exp-2026-10-31-seed/scripts/env.sh"
system_profiler SPDisplaysDataType 2>/dev/null | grep -E 'Chipset Model|Type|Bus|Total Number of Cores|Vendor|Metal'
sw_vers
cd "$D/src/common" || exit 10
s=$(date +%s)
NICE_METAL_DIV_REPRO=1 RUST_LOG=warn "$D/bin/nice_common-test" cubecl_detailed_fd::tests::metal_half_shift_div_repro --ignored --exact --test-threads=1 --nocapture > "$D/logs/test-repro.log" 2>&1
echo "repro rc=$? secs=$(( $(date +%s)-s )) (expected: fails on Apple silicon)"
grep -E '^variant|test result' "$D/logs/test-repro.log"
