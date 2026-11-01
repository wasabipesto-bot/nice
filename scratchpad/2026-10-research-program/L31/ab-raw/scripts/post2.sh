#!/bin/bash
# After the A/B and NiceMark: B from the doc-fixed tree (B2, clippy's doc lints; same code) -> rebuild and compare md5 with B,
# re-run fmt + clippy on it, then the whole-field check on B (minutes of CPU, so after the timed runs).
L=/root/l31b/logs
until [ -e $L/chainNM.done ]; do sleep 10; done
cd /root/l31b
mkdir -p src/B2 && tar xzf B2.tgz -C src/B2 && md5sum src/B2/common/src/cubecl_join.rs > $L/b2_src_md5.txt
J=10 /root/l31b/build.sh B2 B2 gpu > $L/build_B2.out 2>&1
md5sum bin/B bin/B2 >> $L/build_B2.out
sed -i 's#cd /root/l31b/src/B$#cd /root/l31b/src/B2#' /root/l31b/chain_lint.sh
for f in fmt clippy_default clippy_gpu clippy_gpu_spirv; do mv $L/lint_$f.log $L/lint1_$f.log; done; mv $L/lint_summary.txt $L/lint1_summary.txt; rm -f $L/lint.done
/root/l31b/chain_lint.sh > $L/chain_lint2.out 2>&1
/root/l31b/test.sh x_whole B cubecl_join::tests::cubecl_cuda_join_matches_the_reference_on_a_whole_field X=1
echo POST_DONE $(date -u +%T) > $L/post.done
