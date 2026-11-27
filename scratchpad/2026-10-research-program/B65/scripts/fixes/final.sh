#!/bin/bash
# final.sh REV: the final head REV: test binaries (CUDA, SPIR-V; tree b65t) and benches (tree b65b); the device
# tests on the RTX 3060 through CUDA then Vulkan, the brute-force test on the GTX 1060 beside them (brute.sh),
# then the timing A/B (ab_fx.sh) and the field-path out-of-memory test at two fills.
. "$HOME/research/scripts/env.sh"
S=$R/b65/scripts; F=$R/b65b/scripts; REV=$1; OUT=fixes-tests
cd $SRC && git fetch -q fork dev/mo-wide-b65b
bash $S/build_t.sh b65t $REV cubecl-cuda,midout-box-tests fx-t-cuda
bash $S/build_t.sh b65t $REV cubecl-spirv,midout-box-tests fx-t-spv
bash $F/brute.sh $OUT fx-t-cuda fx-t-spv &
bash $S/build_b65.sh b65b $REV cubecl-cuda,midout-bench midout_wide_bench,midout_bench fx-fin-bench-cuda
bash $S/build_b65.sh b65b $REV cubecl-spirv,midout-bench midout_wide_bench,midout_bench fx-fin-bench-spv
bash $F/tests_fx.sh $OUT fx-t-cuda cuda
bash $F/tests_fx.sh $OUT fx-t-spv vk
echo tests > $R/b65b/final.tests
bash $F/ab_fx.sh
O=$R/runs/$OUT; export NICE_BUILD_SHA=test RUST_LOG=warn CUDA_VISIBLE_DEVICES=1 MIDOUT_CUDA=1
for f in 6400 7000; do
  [ -e $R/b65b/stop ] && break
  AUDIT_FILL_MB=$f $R/bin/fx-t-cuda/t_box --ignored --exact midout::gpu_wide::tests::wide_field_oom_is_loud --nocapture --test-threads 1 > $O/cuda_oom_$f.txt 2>&1
  echo "$(date -u +%T) oom $f rc=$? $(grep -h -o 'test result: [a-zA-Z]*\. [0-9]* passed; [0-9]* failed' $O/cuda_oom_$f.txt)" >> $O/rc.txt
done
wait
echo done > $R/b65b/final.done
