#!/bin/bash
# after review (S1): multi-cube regression test. Build the three device test binaries, start the lavapipe runs from
# those binaries in the background, then lint, suite, CUDA stride tests, and two scratch mutants (not committed).
source ~/.cargo/env
cd /root/sra/nice
export CARGO_TARGET_DIR=/root/sra/target
L=/root/sra/logs/phase7; mkdir -p $L
step() { local n=$1; shift; echo "$(date -u +%FT%TZ) start $n: $*" >> $L/steps.log; "$@" > $L/$n.log 2>&1; local rc=$?; echo "$(date -u +%FT%TZ) end $n rc=$rc" >> $L/steps.log; return $rc; }
bin() { grep "Executable unittests src/lib.rs" $L/$1.log | sed 's/.*(\(.*\))/\1/'; }
git log --oneline -1 > $L/head.txt; git status --short >> $L/head.txt; git diff --stat >> $L/head.txt
step build_wgsl cargo test --release --features cubecl -p nice_common --lib --no-run
step build_spirv cargo test --release --features cubecl-spirv -p nice_common --lib --no-run
step build_cuda cargo test --release --features cubecl-cuda -p nice_common --lib --no-run
BW=$(bin build_wgsl); BS=$(bin build_spirv); BC=$(bin build_cuda)
echo "$BW $BS $BC" >> $L/head.txt
export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/lvp_icd.json
( cd common; step lvp_wgsl $BW --ignored --nocapture ) &
( cd common; step lvp_spirv $BS --ignored --nocapture cubecl_ ) &
unset VK_ICD_FILENAMES
( cd common; step cuda_new $BC --ignored --nocapture --exact cubecl_backend::tests::cubecl_cuda_dropped_launches_fail_the_field )
( cd common; step cuda_stride $BC --ignored --nocapture --test-threads=1 cubecl_backend::tests::cubecl_cuda_ )
step just_lint just lint
step clippy_cuda cargo clippy -p nice_common --all-targets --features cubecl-cuda,cubecl-spirv -- -D warnings
step suite cargo test --locked --release --no-fail-fast
step gpu_lib env NICE_REQUIRE_NVRTC=1 cargo test --locked --release -p nice_common --features gpu --lib
wait
# mutants (scratch, restored after): A = host check deleted, B = count once per launch
cp common/src/cubecl_backend.rs $L/clean.rs
for m in A B; do
  cp $L/clean.rs common/src/cubecl_backend.rs
  if [ $m = A ]; then sed -i '/^    ran_complete(base, counts, cubes)?;$/d' common/src/cubecl_backend.rs
  else
       python3 - <<'PY'
p='common/src/cubecl_backend.rs'; s=open(p).read()
a="    sync_cube();\n    if UNIT_POS_X == 0u32 {\n        nice_count[3].fetch_add(1u32);"
assert s.count(a)==1; open(p,'w').write(s.replace(a,a.replace("UNIT_POS_X","ABSOLUTE_POS_X")))
PY
  fi
  git diff > $L/mutant_$m.diff
  step mut${m}_cuda cargo test --release --features cubecl-cuda -p nice_common --lib -- --ignored --nocapture --exact cubecl_backend::tests::cubecl_cuda_dropped_launches_fail_the_field
  VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/lvp_icd.json step mut${m}_lvp_wgsl cargo test --release --features cubecl -p nice_common --lib -- --ignored --nocapture --exact cubecl_backend::tests::cubecl_dropped_launches_fail_the_field
  VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/lvp_icd.json step mut${m}_lvp_spirv cargo test --release --features cubecl-spirv -p nice_common --lib -- --ignored --nocapture --exact cubecl_backend::tests::cubecl_dropped_launches_fail_the_field
done
cp $L/clean.rs common/src/cubecl_backend.rs
git diff --stat > $L/restored.txt
echo done > $L/done
