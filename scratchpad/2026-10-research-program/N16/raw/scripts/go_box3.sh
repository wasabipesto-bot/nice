#!/bin/sh
# go_box3.sh (the box, after go_box2.sh): Task D's chain again on CUDA (fixed lib.sh), then the lavapipe end-to-end
# run of the window's chains (go_lavapipe.sh), then Task D's lavapipe device tests.
S=${SCRIPTS:-/root/n16/scripts}; O=${OUT:-/root/n16/out}
{
echo "BOX3_START $(date -u +%T)"
DEV=cuda PFX0=b3. sh $S/chain_D.sh
sh $S/go_lavapipe.sh
echo "LAVAPIPE_CHAINS_DONE $(date -u +%T)"
for b in D M; do
  /root/n16/bin/$b --ignored --test-threads 1 cubecl_join::tests::cubecl_join_matches_the_cpu_reference \
    cubecl_join::tests::cubecl_niceonly_keeps_join_and_stride_apart_by_ticket cubecl_join::tests::fx_digits_are_exact_everywhere \
    cubecl_join::tests::join_matches_the_reference_on_a_whole_field cubecl_join::tests::join_sample_runs_partitions_of_a_production_field \
    cubecl_join::tests::top_certificates_match_the_lockstep_scan_and_the_cpu cubecl_join::tests::top_fd_matches_the_top_kernel \
    > $O/lavapipe_tests_$b.log 2>&1
  echo "$b lavapipe device tests: $(grep -o 'test result: .*' $O/lavapipe_tests_$b.log)"
done
echo "BOX3_DONE $(date -u +%T)"
} > $O/go_box3.out 2>&1
