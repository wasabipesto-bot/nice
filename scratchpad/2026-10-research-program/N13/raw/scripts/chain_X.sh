#!/bin/sh
# chain_X.sh: exactness on the wgpu device against the CPU join (dense compare, hits + both survivor counts):
# T251 at b60 1e16 (0.55, 48 partitions) and b62 1e17 (0.45, 24 partitions of slice 0); T254 at b64 1e16 and 1e17 (0.55).
W=/tmp/claude-exp-2026-11-11-amd; O=$W/out; export NICE_BUILD_SHA=test
x() { n=$1; b=$2; f=$3; parts=$4
  echo "START $n $(date -u +%T) $b $f $parts" > $O/$n.log
  NICE_TEST_JOIN_DENSE=$parts NICE_TEST_JOIN_DENSE_FIELD=$f $W/bin/$b --ignored --exact cubecl_join::tests::wgpu_join_matches_the_cpu_join_on_a_dense_field --nocapture --test-threads 1 >> $O/$n.log 2>&1
  echo "$(date -u +%T) $n $(grep -o 'partitions: .*' $O/$n.log | cut -c1-200) $(grep -o 'test result: [a-z]*' $O/$n.log)"; }
x x_T251_b60 T251 60:1447429612114824200908:1e16 48
x x_T251_b62 T251 62:7520566762397899821056:1e17 24
x x_T254_b64e16 T254 64:58557331862957161709568:1e16 48
x x_T254_b64e17 T254 64:58557331862957161709568:1e17 24
echo X_DONE $(date -u +%T)
sh $W/scripts/chain_A2.sh > $O/chain_A2.out 2>&1
