#!/bin/bash
# After the A/B and NiceMark (quiet box still): extra b62 rounds (A B interleaved): 1e16 r4-r6, 1e17 r4-r5.
# Then: B2 = the doc-fixed tree (clippy's doc lints; same code) rebuilt and md5-compared with B; fmt + clippy on B2;
# the new host test and the cubecl_join host tests; the whole-field check on B.
L=/root/l31b/logs; R=/root/l31b/run.sh
until [ -e $L/chainNM.done ]; do sleep 10; done
for r in 4 5 6; do $R ab_A_e16_b62_r$r A 62 2 1e16; $R ab_B_e16_b62_r$r B 62 2 1e16; done
for r in 4 5; do $R ab_A_e17_b62_r$r A 62 1 1e17; $R ab_B_e17_b62_r$r B 62 1 1e17; done
echo EXTRA_DONE $(date -u +%T) > $L/extra.done
cd /root/l31b
mkdir -p src/B2 && tar xzf B2.tgz -C src/B2 && md5sum src/B2/common/src/cubecl_join.rs > $L/b2_src_md5.txt
J=10 /root/l31b/build.sh B2 B2 gpu > $L/build_B2.out 2>&1
md5sum bin/B bin/B2 >> $L/build_B2.out
sed -i 's#cd /root/l31b/src/B$#cd /root/l31b/src/B2#' /root/l31b/chain_lint.sh
for f in fmt clippy_default clippy_gpu clippy_gpu_spirv; do mv $L/lint_$f.log $L/lint1_$f.log; done; mv $L/lint_summary.txt $L/lint1_summary.txt; rm -f $L/lint.done
/root/l31b/chain_lint.sh > $L/chain_lint2.out 2>&1
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH:-}
( cd src/B2; ../../bin/B2 --exact cubecl_join::tests::ndig_fast_constants_give_the_digit_count --nocapture; echo "exit $?" ) > $L/host_ndig.log 2>&1
( cd src/B2; ../../bin/B2 cubecl_join:: --test-threads 4; echo "exit $?" ) > $L/host_cubecl_join.log 2>&1
/root/l31b/test.sh x_whole B cubecl_join::tests::cubecl_cuda_join_matches_the_reference_on_a_whole_field X=1
echo POST_DONE $(date -u +%T) > $L/post.done
