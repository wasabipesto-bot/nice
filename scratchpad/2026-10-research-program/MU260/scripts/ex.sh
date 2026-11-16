#!/bin/bash
# ex.sh: exactness of the merge. Lavapipe in the 26.04 chroot as CI runs it (W: --features cubecl, every ignored test;
# S: --features cubecl-spirv, filter cubecl_), both with CubeCL's full compilation log (for atomcmp.py), beside the
# CUDA chain: every cubecl_cuda_* test of cubecl_join but timing/throughput/whole-field/dense, each in its own process,
# then the dense compares vs the CPU join at b60 1e16, b62 1e17, b64 1e17 (8 partitions of slice 0).
W=/root/mu
( bash $W/lvp.sh lvp_W W wgsl.log --ignored --nocapture; until grep -q "built S" $W/out/builds.txt; do sleep 10; done; bash $W/lvp.sh lvp_S S spv.log --ignored --nocapture cubecl_ ) > $W/out/ex_lvp.out 2>&1 &
for t in $($W/bin/G --list --ignored 2>/dev/null | grep -o 'cubecl_join::tests::cubecl_cuda_[a-z0-9_]*' | grep -v 'throughput\|timing\|whole_field\|dense'); do
  TMO=2400 bash $W/t.sh G_${t##*::} G $t
done
for f in "60:1447429612114824200908:10000000000000000" "62:7520566762397899821056:100000000000000000" "64:58557331862957161709568:100000000000000000"; do
  IFS=: read b s z <<< "$f"
  bash $W/t.sh G_dense_b$b G cubecl_join::tests::cubecl_cuda_join_matches_the_cpu_join_on_a_dense_field NICE_TEST_JOIN_DENSE=8 NICE_TEST_JOIN_DENSE_FIELD=$b:$s:$z
done
echo "CUDA_DONE $(date -u +%T)"
wait
echo "EX_DONE $(date -u +%T)"
