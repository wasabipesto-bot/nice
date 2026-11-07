#!/bin/bash
# chain_rider2.sh: after the rider A/B (rider.done), the rest of the exactness list on R: the whole b42 field, the
# FD-vs-top-kernel and certificate device tests, lavapipe (naga + SPIR-V builds and every wgpu cubecl_join test),
# the WGSL lint, fmt and clippy x3.
L=/root/l46/logs; S=/root/l46/scripts; T=$S/test.sh
until [ -e $L/rider.done ]; do sleep 10; done
echo R2_START $(date -u +%T)
export SRCD=R
$T x_R_whole R cubecl_join::tests::cubecl_cuda_join_matches_the_reference_on_a_whole_field NICE_TEST_JOIN_FULL_FIELD=1
$T x_R_cert R cubecl_join::tests::cubecl_cuda_top_certificates_match_the_lockstep_scan_and_the_cpu X=1
$T x_R_topfd R cubecl_join::tests::cubecl_cuda_top_fd_matches_the_top_kernel X=1
for f in whole cert topfd; do echo "$f: $(grep -h 'test result' $L/x_R_$f.log | head -1) $(grep -h '^END' $L/x_R_$f.log)"; done
rm -f $L/lvp_go; touch $L/lvp_go
$S/chain_lvp.sh R > /root/l46/chain_lvp_R.out 2>&1
$S/chain_lint.sh R > /root/l46/chain_lint_R.out 2>&1
echo R2_DONE $(date -u +%T) > $L/rider2.done
