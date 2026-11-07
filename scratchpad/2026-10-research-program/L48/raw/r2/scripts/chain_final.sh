#!/bin/bash
# chain_final.sh (round 2): after main.done (C's A/B, lavapipe, lint) and cf.done: tree F = the final commit (C +
# docs, the CUDA plan scoped to FD fields: b64 keeps its plan); build F; fmt (+ rustfmt check); F's host unit tests,
# FD-vs-top device test, registers; then an interleaved S/F check: 3 rounds of b64 1e16 and b64 1e14 (the only fields
# whose plan moved from C), and 1 round of b62 1e17 / b60 1e16 (plan and kernels as C's); then lint and lavapipe on F.
L=/root/l48/logs; cd /root/l48; R=/root/l48/run.sh; T=/root/l48/test.sh
until [ -e $L/main.done ] && [ -e $L/cf.done ]; do sleep 15; done
echo FINAL_START $(date -u +%T)
./tree.sh F exp/top-fd-round2-rb || exit 1
J=19 ./build.sh F F || exit 1
export SRCD=F
( cd src/F && LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu NICE_BUILD_SHA=test /root/l48/bin/F join_plan:: ; \
  LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu NICE_BUILD_SHA=test /root/l48/bin/F cubecl_join:: ) > $L/unit_F.log 2>&1
echo "F unit: $(grep -h 'test result' $L/unit_F.log | tr '\n' ' ')"
$T q_topfd_F F cubecl_join::tests::cubecl_cuda_top_fd_matches_the_top_kernel X=1
echo "F device test: $(grep -h 'test result' $L/q_topfd_F.log) $(grep -h 'top_kernel on' $L/q_topfd_F.log | sed 's/.*3080: //') $(date -u +%T)"
./regs48.sh F F 0 > regs_F.out 2>&1
echo "F regs: $(grep 'nvcc' regs_F.out | tr '\n' ' ')"
for r in 1 2 3; do
  if [ $r = 2 ]; then O="F S"; else O="S F"; fi
  for t in $O; do SRCD=$t $R fin_${t}_e16_b64_r$r $t 64 2 1e16; done
  for t in $O; do SRCD=$t $R fin_${t}_e14_b64_r$r $t 64 3 1e14; done
done
for t in S F; do SRCD=$t $R fin_${t}_e17_b62_r1 $t 62 1 1e17; SRCD=$t $R fin_${t}_e16_b60_r1 $t 60 2 1e16; done
for f in $L/fin_*.log; do echo "$(basename $f) $(grep -o 'device=[0-9.]*s wall' $f) $(grep -o 'batches=[0-9]* slots=[0-9]* plan_mib=[0-9]*' $f) $(grep -o 'survivors=[0-9]* checked=[0-9]*' $f)"; done
echo FIN_AB_DONE $(date -u +%T)
touch $L/ab.done
./chain_lint.sh F > chain_lint_F.out 2>&1
cat chain_lint_F.out
( NICEN=5 J=19 ./build.sh F F_naga cubecl /root/tgt_lvp && NICEN=5 J=19 ./build.sh F F_spv cubecl-spirv /root/tgt_lvp ) > build_lvp_F.out 2>&1
GO=ab.done ./chain_lvp.sh F F "" 0 > chain_lvp_F.out 2>&1
grep "LVP" chain_lvp_F.out
export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/lvp_icd.json NICE_BUILD_SHA=test
cd /root/l48/src/F
rm -f $L/wgsl_F.log
( CUBECL_DEBUG_LOG=$L/wgsl_F.log timeout 900 /root/l48/bin/F_naga --ignored --exact cubecl_backend::tests::wgsl_dump_for_lint --nocapture; echo "exit $?" ) > $L/lint_dump_F.log 2>&1
( python3 scripts/wgsl-lint.py $L/wgsl_F.log --require DetailedKernelU32@80 --require DetailedFdKernelU32@40 --require DetailedFdKernelU32@50 --require DetailedFdKernel@23 --require DetailedFdKernel@40 --require DetailedFdKernel@50 --require DetailedFdKernel@62 --require DetailedKernel@80 --require NiceonlyKernel@40 --require BucketKernel@57 --require JoinKernel@57 --require TopKernel@57 --require CheckKernel@57 --verbose; echo "lint rc=$?" ) > $L/wgsl_lint_F.log 2>&1
gzip -f $L/wgsl_F.log; tail -n 2 $L/wgsl_lint_F.log
for B in F_spv; do
  rm -f $L/spvdump_$B.log
  ( CUBECL_DEBUG_LOG=$L/spvdump_$B.log timeout 2400 /root/l48/bin/$B --ignored --exact cubecl_join::tests::top_fd_matches_the_top_kernel --nocapture --test-threads 1; echo "exit $?" ) > $L/lvpfd_$B.log 2>&1
  python3 /root/l48/blocks.py $L/spvdump_$B.log --top 40 > $L/blocks_$B.txt 2>&1; gzip -f $L/spvdump_$B.log
done
cd /root/l48/src/S
( CUBECL_DEBUG_LOG=$L/spvdump_S_spv.log timeout 2400 /root/l48/bin/F_spv --version >/dev/null 2>&1 ) ; true
grep TopFdKernel $L/blocks_F_spv.txt | head -12
echo FINAL_DONE $(date -u +%T) | tee $L/final.done
