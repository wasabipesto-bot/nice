#!/bin/bash
# after.sh REV: the final head's benches (CUDA, SPIR-V; tree b65b), then, once chain_w5 is done, the timing A/B
# (ab_fx.sh) and the field-path out-of-memory test (fx-w5-cuda) at two fills.
. "$HOME/research/scripts/env.sh"
S=$R/b65/scripts; REV=$1
cd $SRC && git fetch -q fork dev/mo-wide-b65b
bash $S/build_b65.sh b65b $REV cubecl-cuda,midout-bench midout_wide_bench,midout_bench fx-fin-bench-cuda
bash $S/build_b65.sh b65b $REV cubecl-spirv,midout-bench midout_wide_bench,midout_bench fx-fin-bench-spv
echo built > $R/b65b/after.built
until [ -f $R/b65b/chain_w5.done ]; do sleep 20; done
bash $R/b65b/scripts/ab_fx.sh
O=$R/runs/fixes-tests-w5; export NICE_BUILD_SHA=test RUST_LOG=warn CUDA_VISIBLE_DEVICES=1 MIDOUT_CUDA=1
for f in 6400 7000; do
  [ -e $R/b65b/stop ] && break
  AUDIT_FILL_MB=$f $R/bin/fx-w5-cuda/t_box --ignored --exact midout::gpu_wide::tests::wide_field_oom_is_loud --nocapture --test-threads 1 > $O/cuda_oom_$f.txt 2>&1
  echo "$(date -u +%T) oom $f rc=$? $(grep -h -o 'test result: [a-zA-Z]*\. [0-9]* passed; [0-9]* failed' $O/cuda_oom_$f.txt)" >> $O/rc.txt
done
echo done > $R/b65b/after.done
