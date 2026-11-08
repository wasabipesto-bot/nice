#!/bin/bash
# On the rented AVX-512 box (Vast, nice-research-l52-avx512): the branch's
# cpu_join tests with AVX-512 detected, the opt-in references, and the
# b60 1e14 field with the AVX-512 path against the AVX2 path forced (a local,
# uncommitted one-line edit) and against #248's head. CPU only; no GPU use.
export PATH=$HOME/.cargo/bin:$PATH
O=/root/l52
mkdir -p $O; cd $O
L=$O/box.log
h() { echo "### $(date -u +%H:%M:%S) $*"; }
{ h "host"; grep -m1 "model name" /proc/cpuinfo; nproc; grep -m1 flags /proc/cpuinfo | tr ' ' '\n' | grep -E "^(avx2|avx512.*)$" | tr '\n' ' '; echo; } > $L 2>&1
{ h "clone"; git clone -q --depth 3 -b pr/cpu-join-two-pass-scan https://github.com/wasabipesto-bot/nice.git nice && cd nice && git log --oneline -3; } >> $L 2>&1
cd $O/nice
export CARGO_TARGET_DIR=$O/target
{ h "toolchain"; rustup show active-toolchain 2>&1; rustc --version; cargo --version; } >> $L 2>&1
mkdir -p common/examples && cp $O/l52_ab.rs common/examples/
{ h "cargo test --release -p nice_common --lib cpu_join -- --nocapture (head $(git rev-parse --short HEAD))"
  cargo test --release -p nice_common --lib cpu_join -- --nocapture 2>&1 | grep -v "^   Compiling\|^  Downloaded\|^ Downloading"; echo "exit ${PIPESTATUS[0]}"; } > $O/tests-cpu_join.txt 2>&1
h "tests-cpu_join done" >> $L
{ h "NICE_TEST_CPU_JOIN_REF=3"
  NICE_TEST_CPU_JOIN_REF=3 cargo test --release -p nice_common --lib cpu_join_matches_the_reference_on_production_fields -- --ignored --nocapture 2>&1; echo "exit $?"; } > $O/tests-prodref.txt 2>&1
h "prodref done" >> $L
{ h "NICE_TEST_JOIN_FULL_FIELD=1"
  NICE_TEST_JOIN_FULL_FIELD=1 cargo test --release -p nice_common --lib cpu_join_matches_the_reference_on_a_whole_field -- --ignored --nocapture 2>&1; echo "exit $?"; } > $O/tests-fullfield.txt 2>&1
h "fullfield done" >> $L
{ h "cargo test --release -p nice_common -p nice_client"
  cargo test --release -p nice_common -p nice_client 2>&1 | grep -E "^test result|FAILED|panicked|^exit"; echo "exit ${PIPESTATUS[0]}"; } > $O/tests-all.txt 2>&1
h "tests-all done" >> $L
mkdir -p $O/bin
cargo build -q --release -p nice_common --example l52_ab >> $L 2>&1 && cp $O/target/release/examples/l52_ab $O/bin/pr
sed -i 's/avx512: std::arch::is_x86_feature_detected!("avx512f")/avx512: false \&\& std::arch::is_x86_feature_detected!("avx512f")/' common/src/cpu_join.rs
git diff --stat >> $L
cargo build -q --release -p nice_common --example l52_ab >> $L 2>&1 && cp $O/target/release/examples/l52_ab $O/bin/pr-avx2
git checkout -q common/src/cpu_join.rs
git checkout -q 7f5260ba8b3f27788ab5faec8c4f8bdd489f73ce
cargo build -q --release -p nice_common --example l52_ab >> $L 2>&1 && cp $O/target/release/examples/l52_ab $O/bin/base
git checkout -q pr/cpu-join-two-pass-scan
md5sum $O/bin/* >> $L
h "binaries built" >> $L
R=$O/runs.txt
for r in 1 2 3; do
  if (( r % 2 == 1 )); then ORDER="base pr pr-avx2"; else ORDER="pr-avx2 pr base"; fi
  for c in "b60e14_16t|60 1157209632114824200908 1e14 16 0" "b60e16_1t|60 1157209632114824200908 1e16 1 4" "b62e17s0_1t|62 4473066762334864396992 1e17 1 4 0" "b60e16_16t|60 1157209632114824200908 1e16 16 64" "b62e17s0_16t|62 4473066762334864396992 1e17 16 64 0"; do
    name=${c%%|*}; args=${c#*|}
    for bin in $ORDER; do
      echo "### r$r $name $bin $(date -u +%H:%M:%S) load $(cut -d' ' -f1 /proc/loadavg)" >> $R
      $O/bin/$bin $args >> $R 2>&1
    done
  done
done
h "runs done" >> $L
touch $O/DONE
