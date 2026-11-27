#!/bin/bash
# build_pair.sh TREE REV TAG [spv]: the wide bench (midout-bench) and the lib test binary (midout-box-tests) of REV
# in worktree TREE, CUDA (or SPIR-V with "spv"): bin/TAG-bench-<rt>/midout_wide_bench, bin/TAG-t-<rt>/t_box.
. "$HOME/research/scripts/env.sh"
TREE=$1; REV=$2; TAG=$3; RT=${4:-cuda}
F=cubecl-cuda; [ "$RT" = spv ] && F=cubecl-spirv
S=$R/b65/scripts
bash $S/build_b65.sh $TREE $REV $F,midout-bench midout_wide_bench $TAG-bench-$RT || exit 1
bash $S/build_t.sh $TREE $REV $F,midout-box-tests $TAG-t-$RT
