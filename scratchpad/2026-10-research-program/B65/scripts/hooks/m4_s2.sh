#!/bin/bash
# m4_s2.sh TAG BASE PATCH: step 2 (not pushed) on this Mac: worktree src/TAG at BASE (fetched from the fork's
# dev/mo-hooks) with PATCH applied; the lib tests (cubecl,midout-box-tests) and the wide bench (cubecl,midout-bench);
# the wide device tests through Metal, the shared b65 slice, the brute-force test, a b65 field with the sampled check,
# the WGSL dump and CI's lint. Out: $R/runs/TAG/.
. "$(dirname "$0")/env.sh"
T=$1; BASE=$2; P=$3; O=$R/runs/$T; W=$R/src/$T; mkdir -p $O $R/bin/$T; rm -f $O/done
cd $R/src/nice || exit 1; git fetch -q origin dev/mo-hooks 2> $O/fetch.log
if [ -d $W ]; then git -C $W checkout -q -f --detach $BASE; git -C $W clean -qfd; else git worktree add -q --detach $W $BASE; fi
cd $W && git apply $P > $O/apply.log 2>&1 || { echo "apply failed" >> $O/rc.txt; echo done > $O/done; exit 1; }
git log --oneline -1 > $O/head.txt; git status --short >> $O/head.txt
export CARGO_TARGET_DIR=$R/t/$T NICE_BUILD_SHA=test RUST_LOG=warn
s=$(date +%s); CARGO_PROFILE_RELEASE_LTO=false CARGO_PROFILE_RELEASE_CODEGEN_UNITS=16 cargo test --release -p nice_common --features cubecl,midout-box-tests --lib --no-run > $O/b_tests.log 2>&1; echo "tests build rc=$? $(( $(date +%s) - s )) s" >> $O/rc.txt
X=$(sed -n 's/.*Executable unittests src\/lib.rs (\(.*\))/\1/p' $O/b_tests.log | tail -1); cp $X $R/bin/$T/t_box
s=$(date +%s); CARGO_TARGET_DIR=$R/t/$T-rel cargo build --release -p nice_common --features cubecl,midout-bench --example midout_wide_bench > $O/b_bench.log 2>&1; echo "bench build rc=$? $(( $(date +%s) - s )) s" >> $O/rc.txt
cp $R/t/$T-rel/release/examples/midout_wide_bench $R/bin/$T/
X=$R/bin/$T/t_box
g() { n=$1; shift; s0=$(date +%s); env "$@" > $O/$n.txt 2>&1; rc=$?
  echo "$n rc=$rc $(( $(date +%s) - s0 )) s $(grep -h -o "test result: [a-zA-Z]*\. [0-9]* passed; [0-9]* failed" $O/$n.txt | tail -1)" >> $O/rc.txt; }
TT="--nocapture --test-threads 1"
g tier_b $X --ignored cubecl_midout $TT
g wide_slices $X --ignored --exact midout::gpu_wide::tests::wide_slices_equal_cpu $TT
g wide_slices_sh MIDOUT_WIDE_SHARE=1 $X --ignored --exact midout::gpu_wide::tests::wide_slices_equal_cpu $TT
g wide_faults $X --ignored --exact midout::gpu_wide::tests::wide_faults_are_loud $TT
g wide_share $X --ignored --exact midout::gpu_wide::tests::wide_field_parent_sharing_is_exact_and_loud $TT
g b65_field $R/bin/$T/midout_wide_bench --base 65 --fields 77777 --group 16 --cpu-check
g dump CUBECL_DEBUG_LOG=$O/wgsl.log $X --ignored wgsl_dump_for_lint $TT
REQ=$(sed -n '/wgsl-lint.py "\$CUBECL_DEBUG_LOG"/,/WdoneKernel/p' $W/.github/workflows/gpu-parity.yml | sed 's/python3 scripts\/wgsl-lint.py "\$CUBECL_DEBUG_LOG"//; s/\\$//' | tr '\n' ' ')
python3 $W/scripts/wgsl-lint.py $O/wgsl.log $REQ > $O/lint.txt 2>&1; echo "lint rc=$?" >> $O/rc.txt
g wide_brute $X --ignored --exact midout::gpu_wide::tests::wide_whole_small_bases_vs_brute_force $TT
echo "END $(date -u +%FT%T)" >> $O/rc.txt; echo done > $O/done
