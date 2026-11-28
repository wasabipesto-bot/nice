#!/bin/bash
# final_hk.sh REV TAG: the head REV of dev/mo-hooks: test binaries (CUDA, SPIR-V; tree hkt) and benches (tree hkb)
# into bin/TAG-t-{cuda,spv}, bin/TAG-bench-{cuda,spv}; the device tests on the RTX 3060 through CUDA then Vulkan,
# the brute-force test on the GTX 1060 beside them; the timing (ab_hk.sh) only after the brute force has ended.
. "$HOME/research/scripts/env.sh"
S=$R/b65/scripts; H=$R/b65h/scripts; REV=$1; TAG=$2; OUT=hooks-tests-$TAG
cd $SRC && git fetch -q fork dev/mo-hooks || { echo "fetch failed" > $R/b65h/$TAG.fail; exit 1; }
bash $S/build_t.sh hkt $REV cubecl-cuda,midout-box-tests $TAG-t-cuda || echo "t-cuda build failed" >> $R/b65h/$TAG.fail
bash $S/build_t.sh hkt $REV cubecl-spirv,midout-box-tests $TAG-t-spv || echo "t-spv build failed" >> $R/b65h/$TAG.fail
bash $H/brute_hk.sh $OUT $TAG-t-cuda $TAG-t-spv & BR=$!
bash $S/build_b65.sh hkb $REV cubecl-cuda,midout-bench midout_wide_bench,midout_bench $TAG-bench-cuda || echo "bench-cuda build failed" >> $R/b65h/$TAG.fail
bash $S/build_b65.sh hkb $REV cubecl-spirv,midout-bench midout_wide_bench,midout_bench $TAG-bench-spv || echo "bench-spv build failed" >> $R/b65h/$TAG.fail
bash $H/tests_hk.sh $OUT $TAG-t-cuda cuda
bash $H/tests_hk.sh $OUT $TAG-t-spv vk
echo tests > $R/b65h/$TAG.tests
wait $BR
[ "${NOAB:-0}" = 1 ] || bash $H/ab_hk.sh $TAG
echo done > $R/b65h/$TAG.done
