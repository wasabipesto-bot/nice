#!/bin/bash
# The stale copy of master.sh (replaced on disk but still running) re-ran x_whole without NICE_TEST_JOIN_FULL_FIELD
# after the A/B, which skipped and overwrote the 11:44 log. Re-run the whole-field check on B2 after the extra rounds.
L=/root/l33p/logs
until [ -e $L/extra.done ]; do sleep 10; done
/root/l33p/test.sh x2_whole B2 cubecl_join::tests::cubecl_cuda_join_matches_the_reference_on_a_whole_field NICE_TEST_JOIN_FULL_FIELD=1
echo POSTWHOLE_DONE $(date -u +%T) > $L/postwhole.done
