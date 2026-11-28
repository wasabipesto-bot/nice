#!/bin/bash
# chain_v5.sh [WAITFILE]: B65.9 on eventeo (EXPERIMENTS.md). Waits for WAITFILE if given (the group sweep's done file),
# then: V5's benches (CUDA, SPIR-V), the timing against the base (ab_v5.sh), V5's test binaries, the device tests
# through CUDA and Vulkan (plane width 32), and powers the box off if nothing else needs it.
# Rule written beforehand: every V5 count equals the base's and every device test passes, or V5 has a defect at 32
# lanes; within 2 % of the base on this card at both bases: it can be the common path and the RX 9070 XT decides its
# value; slower by more than 2 % at base 64: it would have to be a plane-width-64-only variant.
. "$HOME/research/scripts/env.sh"
S=$R/v5/scripts; V5=a4fb3543; mkdir -p $R/v5
exec >> $R/v5/chain.log 2>&1
echo "$(date -u +%FT%T) chain_v5 start, waiting for ${1:-nothing}"
if [ -n "$1" ]; then until [ -e "$1" ] || [ -e $R/v5/stop ]; do sleep 3; done; fi
[ -e $R/v5/stop ] && { echo stopped; exit 0; }
touch $R/keep-up    # holds the box up for this chain (off_if_idle.sh); removed at the end
cd $SRC && git fetch -q fork exp/mo-wide-aco && git cat-file -e $V5^{commit} || { echo "fetch failed"; rm -f $R/keep-up; exit 1; }
echo "$(date -u +%T) bench builds"
bash $S/build_b65.sh v5 $V5 cubecl-cuda,midout-bench midout_wide_bench,midout_bench v5-bench-cuda
bash $S/build_b65.sh v5 $V5 cubecl-spirv,midout-bench midout_wide_bench,midout_bench v5-bench-spv
echo "$(date -u +%T) timing"
bash $S/ab_v5.sh
echo "$(date -u +%T) test builds"
bash $S/build_t.sh v5 $V5 cubecl-cuda,midout-box-tests v5-t-cuda
bash $S/build_t.sh v5 $V5 cubecl-spirv,midout-box-tests v5-t-spv
echo "$(date -u +%T) tests"
bash $S/tests_fx.sh v5-tests v5-t-cuda cuda
bash $S/tests_fx.sh v5-tests v5-t-spv vk
echo "$(date -u +%T) chain done"; echo done > $R/v5/done
rm -f $R/keep-up
bash -l $R/scripts/off_if_idle.sh
