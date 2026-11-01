#!/bin/bash
# L30 round 1 on the box: stats, P2 exactness, profiled ablations, A/B. Sequential.
R=/root/l30run.sh
export BIN=/root/l30/l30
cd /root
$R st_e16_b62 62 2 1e16 0 1
$R pf_e16_b62_r1 62 2 1e16 0 256
$R c0_e16_b62_r1 62 2 1e16 0 0
# CPU comparison of the walk prefilter on 4 partitions of the b62 field
( export NICE_EXP_L30=256 NICE_TEST_JOIN_DENSE=4 NICE_TEST_JOIN_DENSE_FIELD=62:7997740455941656911841:1e16
  echo "START dense_pf $(date -u +%T)"; $BIN --ignored --exact cubecl_join::tests::cubecl_cuda_join_matches_the_cpu_join_on_a_dense_field --nocapture --test-threads 1; echo "END dense_pf rc=$?" ) > /root/l30/dense_pf.log 2>&1
for xm in 0 2 4 8 16 32 64 256; do $R ab${xm}_e16_b62_p1 62 2 1e16 1 $xm; done
$R st_e16_b60 60 2 1e16 0 1
for r in 2 3; do $R c0_e16_b62_r$r 62 2 1e16 0 0; $R pf_e16_b62_r$r 62 2 1e16 0 256; done
echo CHAIN1_DONE $(date -u +%T) > /root/l30/chain1.done
