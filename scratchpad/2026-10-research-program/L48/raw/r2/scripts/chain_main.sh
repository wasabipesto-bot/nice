#!/bin/bash
# chain_main.sh (round 2): after S and C are built: CM (measurement-only plan report) build and run; C's FD-vs-top
# device test first (stop if it fails); host unit tests; client_C; registers of S and C; C's CUDA exactness list
# beside C's lavapipe builds; then (nothing else running) the A/B of S against C; then lavapipe tests and lint of C.
L=/root/l48/logs; cd /root/l48
until grep -q "BUILD_DONE C \|FAILED" build_C.out 2>/dev/null; do sleep 10; done
grep -q FAILED build_C.out && { echo C_BUILD_FAILED; exit 1; }
echo MAIN_START $(date -u +%T)
export SRCD=C
./test.sh q_topfd_C C cubecl_join::tests::cubecl_cuda_top_fd_matches_the_top_kernel X=1
echo "C device test: $(grep -h 'test result' $L/q_topfd_C.log) $(grep -h 'top_kernel on' $L/q_topfd_C.log | sed 's/.*3080: //') $(date -u +%T)"
grep -q "test result: ok" $L/q_topfd_C.log || { echo C_DEVICE_TEST_FAILED; exit 1; }
( cd src/C && LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu NICE_BUILD_SHA=test /root/l48/bin/C join_plan:: ; \
  LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu NICE_BUILD_SHA=test /root/l48/bin/C cubecl_join:: ) > $L/unit_C.log 2>&1
echo "C unit: $(grep -h 'test result' $L/unit_C.log | tr '\n' ' ')"
J=19 ./buildclient.sh C client_C /root/tgt_cl || exit 1
J=19 ./build.sh CM CM || exit 1
SRCD=CM ./test.sh plan_CM CM cubecl_join::tests::l48_plan_report X=1
grep -h "L48 PLAN" $L/plan_CM.log
./regs48.sh S S 0 > regs_S.out 2>&1
./regs48.sh C C 0 > regs_C.out 2>&1
echo REGS_DONE $(date -u +%T)
( NICEN=15 J=10 ./build.sh C C_naga cubecl /root/tgt_lvp && NICEN=15 J=10 ./build.sh C C_spv cubecl-spirv /root/tgt_lvp ) > build_lvp_C.out 2>&1 &
SRCD=C ./chain_x.sh C 0 C > chain_x_C.out 2>&1
echo X_C_DONE $(date -u +%T)
wait
while pgrep -f "cargo |rustc" > /dev/null; do sleep 15; done
echo AB_GO $(date -u +%T)
touch $L/ab_go
./chain_ab.sh C > chain_ab.out 2>&1
echo AB_DONE $(date -u +%T)
( GO=ab.done ./chain_lvp.sh C C "" 0 > chain_lvp_C.out 2>&1 ) &
./chain_lint.sh C > chain_lint_C.out 2>&1
wait
echo MAIN_DONE $(date -u +%T) | tee $L/main.done
