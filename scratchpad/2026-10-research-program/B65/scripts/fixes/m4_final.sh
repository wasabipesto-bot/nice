#!/bin/bash
# m4_final.sh: the final head of dev/mo-wide-b65b on this Mac: build (build_mo.sh), the wide tests through Metal
# (wide_tests.sh), the WGSL dump + lint requirements and tier (lint_dump.sh at the head), the justfile lint.
. "$(dirname "$0")/env.sh"
S=$R/scripts; T=$1  # TAG: a new one per head (build_mo.sh checks out the worktree's own FETCH_HEAD, stale in an old worktree)
bash $S/build_mo.sh dev/mo-wide-b65b $T
bash $S/wide_tests.sh $T $T-tests
# also the shared b65 slice and the brute-force test (with its shared and field-path parts)
O=$R/runs/$T-tests; X=$R/bin/$T/t_box; export NICE_BUILD_SHA=test RUST_LOG=warn
for n in wide_slices_sh wide_brute; do
  s0=$(date +%s)
  if [ $n = wide_slices_sh ]; then MIDOUT_WIDE_SHARE=1 $X --ignored --exact midout::gpu_wide::tests::wide_slices_equal_cpu --nocapture --test-threads 1 > $O/$n.txt 2>&1
  else $X --ignored --exact midout::gpu_wide::tests::wide_whole_small_bases_vs_brute_force --nocapture --test-threads 1 > $O/$n.txt 2>&1; fi
  echo "$n rc=$? $(( $(date +%s) - s0 )) s $(grep -h -o "test result: [a-zA-Z]*\. [0-9]* passed; [0-9]* failed" $O/$n.txt | tail -1)" >> $O/rc2.txt
done
H=$(git -C $R/src/$T rev-parse HEAD)
FETCH=dev/mo-wide-b65b NOTIER=1 bash $S/lint_dump.sh $T-dump $H ""
bash $S/lint_full.sh $T
echo done > $R/runs/$T.done
