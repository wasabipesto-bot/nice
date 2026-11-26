#!/bin/bash
# runs_reads.sh: before (branch point 4fff25e7) and after (batched reads) on the RTX 3060, base 65 wide (warm-up
# 13731, field 77777), quiet and under 6 busy loops (PIDs recorded, killed by PID), Vulkan/SPIR-V then CUDA; base 64
# through the wide path once each (CUDA). Waits for the builds and the tests.
. "$HOME/research/scripts/env.sh"
until [ -f $R/logs/reads/builds.done ] && [ -f $R/runs/reads-tests/done ]; do sleep 10; done
S=$R/b65/scripts; O=$R/runs/reads-bench; mkdir -p $O
W65="--base 65 --fields 13731,77777 --group 16"; W64="--base 64 --fields 4095,77777 --group 16"
stop() { [ -e $R/b65/stop ] && { echo "stopped" >> $O/rc.txt; exit 0; }; }
busy() { P=""; for i in $(seq 1 $1); do sh -c 'while :; do :; done' & P="$P $!"; done
  echo "$(date -u +%T) busy $1 pids$P" >> $O/busy.pids; sleep 2; }
unbusy() { for p in $P; do kill $p; done; wait $P 2>/dev/null; echo "$(date -u +%T) killed$P" >> $O/busy.pids; P=""; }
cell() { n=$1; k=$2; e=$3; rt=$4; shift 4; stop; [ "$k" -gt 0 ] && busy $k
  bash $S/run_b65.sh reads-bench $n $e $rt -- "$@"; [ "$k" -gt 0 ] && unbusy; }
cell v_base_q   0 rb-base-spv/midout_wide_bench  vk   $W65
cell v_reads_q  0 rb-reads-spv/midout_wide_bench vk   $W65
cell v_reads_b6 6 rb-reads-spv/midout_wide_bench vk   $W65
cell v_base_b6  6 rb-base-spv/midout_wide_bench  vk   $W65
cell c_base_q   0 rb-base-cuda/midout_wide_bench  cuda $W65
cell c_reads_q  0 rb-reads-cuda/midout_wide_bench cuda $W65
cell c_reads_b6 6 rb-reads-cuda/midout_wide_bench cuda $W65
cell c_base_b6  6 rb-base-cuda/midout_wide_bench  cuda $W65
cell c64_base   0 rb-base-cuda/midout_wide_bench  cuda $W64
cell c64_reads  0 rb-reads-cuda/midout_wide_bench cuda $W64
cell v_reads_q2 0 rb-reads-spv/midout_wide_bench vk   $W65
echo done > $O/done
