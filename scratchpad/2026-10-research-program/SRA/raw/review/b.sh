#!/bin/bash
# Reviewer's mutants, scratch clone /root/rev/b, own target dir /root/rev/tb.
source ~/.cargo/env
cd /root/rev/b
export CARGO_TARGET_DIR=/root/rev/tb
L=/root/rev/logs/b; mkdir -p $L
F=common/src/cubecl_backend.rs
step() { local n=$1; shift; echo "$(date -u +%FT%TZ) start $n: $*" >> $L/steps.log; "$@" > $L/$n.log 2>&1; local rc=$?; echo "$(date -u +%FT%TZ) end $n rc=$rc" >> $L/steps.log; }
LVP=/usr/share/vulkan/icd.d/lvp_icd.json
git checkout -q -- $F
# probes added (all stages)
perl -0pi -e 'BEGIN{local $/; open my $h, "<", "/root/rev/revtest.rs"; $::t = <$h>;} s/(    #\[test\]\n    fn ran_complete_wants_every_launched_cube)/$::t$1/' $F
grep -c "fn rev_" $F >> $L/steps.log
cp $F $L/probe.rs
# M0: branch + probes
step m0_cuda cargo test --release --features cubecl-cuda -p nice_common --lib -- --ignored --nocapture --test-threads=1 rev_multicube_cuda
step m0_lvp_wgsl env VK_ICD_FILENAMES=$LVP cargo test --release --features cubecl -p nice_common --lib -- --ignored --nocapture rev_multicube_wgpu
step m0_lvp_spirv env VK_ICD_FILENAMES=$LVP cargo test --release --features cubecl-spirv -p nice_common --lib -- --ignored --nocapture --test-threads=1 rev_
# M1: host check removed
perl -0pi -e 's/\n    ran_complete\(base, counts, cubes\)\?;//' $F
git diff --stat >> $L/steps.log; git diff > $L/m1.diff
step m1_cuda cargo test --release --features cubecl-cuda -p nice_common --lib -- --ignored --nocapture cubecl_cuda_dropped_launches_fail_the_field
step m1_lvp_wgsl env VK_ICD_FILENAMES=$LVP cargo test --release --features cubecl -p nice_common --lib -- --ignored --nocapture cubecl_dropped_launches_fail_the_field
step m1_lvp_spirv env VK_ICD_FILENAMES=$LVP cargo test --release --features cubecl-spirv -p nice_common --lib -- --ignored --nocapture cubecl_dropped_launches_fail_the_field
# M2: host check back; kernel counts once per launch (only the grid's first unit)
cp $L/probe.rs $F
perl -0pi -e 's/if UNIT_POS_X == 0u32 \{\n        nice_count\[3\]/if ABSOLUTE_POS_X == 0u32 {\n        nice_count[3]/' $F
git diff > $L/m2.diff
step m2_cuda cargo test --release --features cubecl-cuda -p nice_common --lib -- --ignored --nocapture --test-threads=1 cubecl_backend::tests::
step m2_lvp_wgsl env VK_ICD_FILENAMES=$LVP cargo test --release --features cubecl -p nice_common --lib -- --ignored --nocapture cubecl_backend::tests::
cp $L/probe.rs $F
echo done > $L/done
