#!/bin/bash
# on box: exactness of the tuned port 4170a781 at W = 32 (CUDA runtime), whole super-units, GPU prep, sets checked.
# x_{A,D}_su{1,2}: --tdig 0 / 1 on both super-units; x_A_su1_p20: --prep2 0 once. fill is 1024 by default at W = 32.
cd /root/g2; mkdir -p out; export NICE_BUILD_SHA=test
run() { N=$1; shift; echo "$(date -u +%FT%TZ) exact $N start [$*] md5=$(md5sum bin/g2_T | cut -c1-8)" >> out/runs.log
  ./bin/g2_T "$@" --cuda --gpu-prep --reps 1 > out/$N.log 2>&1; rc=$?
  echo "$(date -u +%FT%TZ) exact $N end rc=$rc" >> out/runs.log
  echo "== $N rc=$rc $(grep -c 'EQUAL' out/$N.log) EQUAL lines; $(grep -h 'ALL CHECKS\|FAIL\|NOT EQUAL\|errors: plane [1-9]' out/$N.log | tr '\n' ' ' | cut -c1-200)"; }
run x_A_su1 su64_712012851 --tdig 0
run x_D_su1 su64_712012851 --tdig 1
run x_A_su2 su64_391856203 --tdig 0
run x_D_su2 su64_391856203 --tdig 1
run x_A_su1_p20 su64_712012851 --tdig 0 --prep2 0
echo EXACT_DONE
