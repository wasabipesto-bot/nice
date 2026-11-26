#!/bin/bash
# runs_stage.sh: step 3 of B65/BRIEF.md: cumulative MIDOUT_STOP 1 tops, 2 + parents, 3 + main kernel, 5 + expansion,
# then the whole field (6 = no stop), one cold process each, warm-up then field 77777, CUDA, head f61cf79e.
# Order: base 65 wide, base 64 narrow (reference), base 64 wide.
. "$HOME/research/scripts/env.sh"
S=$R/b65/scripts
bash $S/runs_load_vk.sh   # the Vulkan/SPIR-V load cells first (coordinator, 06:5x UTC)
stop() { [ -e $R/b65/stop ] && { echo "stopped" >> $R/runs/b65-stage/rc.txt; exit 0; }; }
for st in 1 2 3 5; do stop; bash $S/run_b65.sh b65-stage w65_s$st mo-mode/midout_wide_bench cuda MIDOUT_STOP=$st -- --base 65 --fields 13731,77777 --group 16; done
for st in 1 2 3 5; do stop; bash $S/run_b65.sh b65-stage n64_s$st mo-mode/midout_bench cuda MIDOUT_STOP=$st -- --threads 5 --fields 4095,77777 --group 16 --no-cpu-check; done
stop; bash $S/run_b65.sh b65-stage n64_s6 mo-mode/midout_bench cuda -- --threads 5 --fields 4095,77777 --group 16 --no-cpu-check
for st in 1 2 3 5; do stop; bash $S/run_b65.sh b65-stage w64_s$st mo-mode/midout_wide_bench cuda MIDOUT_STOP=$st -- --base 64 --fields 4095,77777 --group 16; done
stop; bash $S/run_b65.sh b65-stage w64_s6 mo-mode/midout_wide_bench cuda -- --base 64 --fields 4095,77777 --group 16
echo done > $R/runs/b65-stage/done
