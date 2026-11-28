#!/bin/bash
# m4_hk.sh TAG: the head of dev/mo-hooks on this Mac (Metal through wgpu): build (build_mo.sh; a new TAG per head),
# the wide tests (wide_tests.sh), the shared b65 slice, the narrow fault and sharing tests, then the WGSL dump at the
# head and CI's lint with the workflow's own requirement list. Out: $R/runs/TAG-tests, $R/runs/TAG-dump.
. "$(dirname "$0")/env.sh"
S=$R/scripts; T=$1
bash $S/build_mo.sh dev/mo-hooks $T
bash $S/wide_tests.sh $T $T-tests
O=$R/runs/$T-tests; X=$R/bin/$T/t_box; export NICE_BUILD_SHA=test RUST_LOG=warn
g() { n=$1; shift; s0=$(date +%s); env "$@" --nocapture --test-threads 1 > $O/$n.txt 2>&1; rc=$?
  echo "$n rc=$rc $(( $(date +%s) - s0 )) s $(grep -h -o "test result: [a-zA-Z]*\. [0-9]* passed; [0-9]* failed" $O/$n.txt | tail -1)" >> $O/rc2.txt; }
g wide_slices_sh MIDOUT_WIDE_SHARE=1 $X --ignored --exact midout::gpu_wide::tests::wide_slices_equal_cpu
g nfaults $X --ignored --exact midout::gpu::audit::accounts_faults_are_loud
g nshare $X --ignored --exact midout::gpu::tests::field_parent_sharing_is_exact_and_loud
H=$(git -C $R/src/$T rev-parse HEAD)
FETCH=dev/mo-hooks NOTIER=1 bash $S/lint_dump.sh $T-dump $H ""
D=$R/runs/$T-dump
REQ=$(sed -n '/wgsl-lint.py "\$CUBECL_DEBUG_LOG"/,/WdoneKernel/p' $R/src/$T-dump/.github/workflows/gpu-parity.yml | sed 's/python3 scripts\/wgsl-lint.py "\$CUBECL_DEBUG_LOG"//; s/\\$//' | tr '\n' ' ')
echo "$REQ" > $D/require.txt
python3 $R/src/$T-dump/scripts/wgsl-lint.py $D/wgsl.log $REQ > $D/lint.txt 2>&1; echo "lint rc=$?" >> $D/rc.txt
echo done > $R/runs/$T.done
