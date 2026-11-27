#!/bin/bash
# chain_w5.sh: test binaries of the merge head + wip5.patch (CUDA, SPIR-V), then the device tests through CUDA and
# through Vulkan on the RTX 3060.
. "$HOME/research/scripts/env.sh"
S=$R/b65b/scripts; P=$R/b65b/wip5.patch
bash $S/build_wip.sh $P fx-w5-cuda && bash $S/tests_fx.sh fixes-tests-w5 fx-w5-cuda cuda &
BP=$!
wait $BP
bash $S/build_wip.sh $P fx-w5-spv spv && bash $S/tests_fx.sh fixes-tests-w5 fx-w5-spv vk
echo done > $R/b65b/chain_w5.done
