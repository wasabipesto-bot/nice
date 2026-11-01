#!/bin/bash
# After the A/B and NiceMark: the whole-field check on B (minutes of CPU, so after the timed runs).
L=/root/l31b/logs
until [ -e $L/chainNM.done ]; do sleep 10; done
/root/l31b/test.sh x_whole B cubecl_join::tests::cubecl_cuda_join_matches_the_reference_on_a_whole_field X=1
echo POST_DONE $(date -u +%T) > $L/post.done
