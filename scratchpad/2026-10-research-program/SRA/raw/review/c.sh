#!/bin/bash
# Reviewer's plane-scoped probe on lavapipe SPIR-V: variants, with module dumps. Scratch clone /root/rev/c, target /root/rev/tc.
source ~/.cargo/env
cd /root/rev
[ -d c ] || git clone -q /root/sra/nice c
git -C c checkout -q --detach 3940f8a96766ac3b65eae59aa638a1772a88bada
[ -d tc ] || cp -a /root/sra/target tc
cd c
export CARGO_TARGET_DIR=/root/rev/tc
L=/root/rev/logs/c; mkdir -p $L
F=common/src/cubecl_backend.rs
step() { local n=$1; shift; echo "$(date -u +%FT%TZ) start $n: $*" >> $L/steps.log; "$@" > $L/$n.log 2>&1; local rc=$?; echo "$(date -u +%FT%TZ) end $n rc=$rc" >> $L/steps.log; }
export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/lvp_icd.json
git checkout -q -- $F
perl -0pi -e 'BEGIN{local $/; open my $h, "<", "/root/rev/revtest.rs"; $::t = <$h>;} s/(    #\[test\]\n    fn ran_complete_wants_every_launched_cube)/$::t$1/' $F
perl -0pi -e 's/(    let counts = u32::from_bytes\(&bytes\);\n)/$1    eprintln!("REVCOUNTS {:?} cubes {cubes}", &counts[..]);\n/' $F
cp $F $L/v1.rs
run() { local v=$1; rm -rf $L/spv_$v; mkdir -p $L/spv_$v; step $v env CUBECL_DEBUG_SPIRV=$L/spv_$v cargo test --release --features cubecl-spirv,cubecl/spirv-dump -p nice_common --lib -- --ignored --nocapture --test-threads=1 rev_plane_scoped_forced; }
# V1: branch as is
run v1
# V2: no barrier in cube_ran
cp $L/v1.rs $F
perl -0pi -e 's/fn cube_ran\(nice_count: &mut Array<Atomic<u32>>\) \{\n    sync_cube\(\);/fn cube_ran(nice_count: &mut Array<Atomic<u32>>) {/' $F
git diff | grep "^[-+]" | grep -v REV | head -20 > $L/v2.diff
run v2
# V3: main's kernel (no cube_ran call), host check off: what the plane path gives on llvmpipe without the change
cp $L/v1.rs $F
perl -0pi -e 's/\n    cube_ran\(nice_count\);\n\}/\n}/; s/\n    ran_complete\(base, counts, cubes\)\?;//' $F
git diff | grep "^[-+]" | grep -v REV | head -20 > $L/v3.diff
run v3
cp $L/v1.rs $F
echo done > $L/done
