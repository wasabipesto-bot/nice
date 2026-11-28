#!/bin/bash
# final_s2.sh PATCH BASE TAG: step 2 (the wide expansion's lookups) as a local commit of PATCH on BASE in eventeo's
# clone (not pushed), test binaries and benches as final_hk.sh (trees hkt, hkb), the device tests through CUDA and
# Vulkan with the brute-force test on the GTX 1060 beside them, then the timing of TAG against hk1 (ab_s2.sh).
. "$HOME/research/scripts/env.sh"
S=$R/b65/scripts; H=$R/b65h/scripts; P=$1; BASE=$2; TAG=$3; OUT=hooks-tests-$TAG
W=$SRC/.worktrees/s2src; cd $SRC || exit 1
if [ -d $W ]; then git -C $W checkout -q -f --detach $BASE; else git worktree add -q --detach $W $BASE; fi
cd $W && git apply $P && git -c user.name=local -c user.email=local@localhost commit -q -am "step 2 (local)" || { echo "apply failed" > $R/b65h/$TAG.fail; exit 1; }
REV=$(git rev-parse HEAD); echo $REV > $R/b65h/$TAG.rev
bash $S/build_t.sh hkt $REV cubecl-cuda,midout-box-tests $TAG-t-cuda || echo "t-cuda build failed" >> $R/b65h/$TAG.fail
bash $S/build_t.sh hkt $REV cubecl-spirv,midout-box-tests $TAG-t-spv || echo "t-spv build failed" >> $R/b65h/$TAG.fail
bash $H/brute_hk.sh $OUT $TAG-t-cuda $TAG-t-spv & BR=$!
bash $S/build_b65.sh hkb $REV cubecl-cuda,midout-bench midout_wide_bench,midout_bench $TAG-bench-cuda || echo "bench-cuda build failed" >> $R/b65h/$TAG.fail
bash $S/build_b65.sh hkb $REV cubecl-spirv,midout-bench midout_wide_bench,midout_bench $TAG-bench-spv || echo "bench-spv build failed" >> $R/b65h/$TAG.fail
echo built > $R/b65h/$TAG.built
bash $H/tests_hk.sh $OUT $TAG-t-cuda cuda
bash $H/tests_hk.sh $OUT $TAG-t-spv vk
echo tests > $R/b65h/$TAG.tests
wait $BR
[ "${NOAB:-0}" = 1 ] || bash $H/ab_s2.sh $TAG
echo done > $R/b65h/$TAG.done
