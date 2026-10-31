#!/bin/sh
# usage: pipeline.sh <first_ssh_epoch>
D="$HOME/claude-exp-2026-10-31-top"
T0=$1; DEADLINE=$((T0 + 3480))
step() {
  name=$1; shift
  echo "STEP $name start $(date +%s)"
  sh "$D/run.sh" "$name" "$@"
  st=$(sed -n 's/^EXIT \([0-9]*\) .*/\1/p' "$D/logs/$name.status")
  echo "STEP $name rc=$st end $(date +%s)"
  return "${st:-99}"
}
step build-A "$D/build.sh" A || exit 1
step A-join "$D/test.sh" A A-join cubecl_join_matches_the_cpu_reference --ignored
step A-diag "$D/test.sh" A A-diag zz_l25_windows_each --ignored
step build-B "$D/build.sh" B || exit 2
step B-join "$D/test.sh" B B-join cubecl_join_matches_the_cpu_reference --ignored; brc=$?
step B-diag "$D/test.sh" B B-diag zz_l25_windows_each --ignored
step B-sample "$D/test.sh" B B-sample join_sample_runs_partitions_of_a_production_field --ignored
step A-sample "$D/test.sh" A A-sample join_sample_runs_partitions_of_a_production_field --ignored
if [ "$brc" != 0 ]; then echo "B-join failed: Test 2 skipped"; exit 3; fi
left=$((DEADLINE - $(date +%s)))
echo "SECONDS_LEFT_BEFORE_TEST2 $left"
if [ "$left" -lt 1200 ]; then echo "under 20 min left: Test 2 skipped"; exit 4; fi
step T2-prefilter "$D/test.sh" A T2-prefilter cubecl_prefilter_survivors_match_the_host_mirror --ignored
step T2-niceonly "$D/test.sh" A T2-niceonly cubecl_matches_cpu_niceonly --ignored
step T2-cross "$D/test.sh" A T2-cross cubecl_cross_filter_survivors_match_the_host_mirror --ignored
step T2-69 "$D/test.sh" A T2-69 cubecl_niceonly_finds_69_in_base_10 --ignored
echo PIPELINE_DONE
