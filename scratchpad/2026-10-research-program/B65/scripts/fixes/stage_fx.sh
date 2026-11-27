#!/bin/bash
# stage_fx.sh: after final.sh, where the counts' cost sits, RTX 3060, CUDA, base 65 (fields 13731, 77777): the
# cumulative timing stops 2 (tops + parents), 3 (+ main kernel), 5 (+ expansion) before (fx-base) and after
# (fx-fin); then the final head without the split faults' emulation code (fx-noemul: the counts kept, built on
# ivory from f503a13c with the fault conditions removed) against fx-fin, base 65 wide and base 64 narrow; the
# base-65 pair again in the other order.
. "$HOME/research/scripts/env.sh"
until [ -f $R/b65b/final.done ]; do sleep 20; done
S=$R/b65/scripts; RUN=fixes-stage; O=$R/runs/$RUN; mkdir -p $O
W65="--base 65 --fields 13731,77777 --group 16"; N64="--fields 4095,77777 --group 16 --no-cpu-check"
c() { [ -e $R/b65b/stop ] && { echo stopped >> $O/rc.txt; exit 0; }; bash $S/run_b65.sh $RUN "$@"; }
for st in 2 3 5; do
  c cu65s${st}_base fx-base-bench-cuda/midout_wide_bench cuda MIDOUT_STOP=$st -- $W65
  c cu65s${st}_fin fx-fin-bench-cuda/midout_wide_bench cuda MIDOUT_STOP=$st -- $W65
done
c cu65_noemul_1 fx-noemul-bench-cuda/midout_wide_bench cuda -- $W65
c cu65_fin_1 fx-fin-bench-cuda/midout_wide_bench cuda -- $W65
c cu64n_noemul_1 fx-noemul-bench-cuda/midout_bench cuda -- $N64
c cu64n_fin_1 fx-fin-bench-cuda/midout_bench cuda -- $N64
c cu65_fin_2 fx-fin-bench-cuda/midout_wide_bench cuda -- $W65
c cu65_noemul_2 fx-noemul-bench-cuda/midout_wide_bench cuda -- $W65
echo done > $O/done
