#!/bin/bash
# final.sh HEAD: after the A/B and the lavapipe runs, the PR's final head (fmt/clippy/doc fixes over the tested tree):
# build, host tests (incl. the exhaustive magic test), the count/probe device test, check_all, the 1e14 COMPARE at
# b62, fmt and clippy x3; and every A/B process's check kernel through the driver JIT.
L=/root/l47/logs; H=$1
until grep -q ORCH_DONE $L/orch.out; do sleep 15; done
echo FINAL_START $(date -u +%T)
cd /root/nice && git fetch -q origin exp/check-d-pr && cd /root/l47/src/F && git checkout -q -f --detach $H && git log --oneline -1 > $L/final_tree.txt
NICEN=5 J=10 /root/l47/scripts/build.sh F FIN gpu /root/tgt
( cd /root/l47/src/F && LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu NICE_BUILD_SHA=test /root/l47/bin/FIN join_check:: ; \
  NICE_TEST_CHECK_EXHAUSTIVE=1 /root/l47/bin/FIN --ignored --exact join_check::tests::magic_quotients_are_exact_everywhere --nocapture ) > $L/fin_unit.log 2>&1
SRCD=F /root/l47/scripts/test.sh fin_counts FIN cubecl_join::tests::cubecl_cuda_check_counts_match_the_cpu X=1
SRCD=F /root/l47/scripts/test.sh fin_ref FIN cubecl_join::tests::cubecl_cuda_join_matches_the_cpu_reference X=1
NICE_TEST_JOIN_COMPARE=1 SRCD=F /root/l47/scripts/run.sh fin_cmp FIN 62 1 1e14
SRCD=F /root/l47/scripts/chain_lint.sh FIN > $L/lint_FIN.out 2>&1
for d in /root/l47/ptx/ab_P_*; do python3 /root/l47/scripts/ptxjit.py --only check_kernel $d 2>&1 | sed "s#^#$(basename $d) #"; done > $L/ab_P_jit.txt 2>&1
echo FINAL_DONE $(date -u +%T) > $L/final.done
