#!/bin/bash
# runs_load_vk.sh (spare time; no bisection was needed): the load cells through Vulkan with the direct SPIR-V
# compiler, the runtime of the AMD card: b65 wide and b64 narrow under 6 busy loops (quiet b65 = b65-ab spv_head*),
# a quiet b64 narrow for reference. Waits for chain1.sh to finish.
. "$HOME/research/scripts/env.sh"
# (06:5x: run from runs_stage_only.sh before the stage profile, at the coordinator's request)
S=$R/b65/scripts; O=$R/runs/b65-loadvk; mkdir -p $O
W65="--base 65 --fields 13731,77777 --group 16"; N64="--fields 4095,77777 --group 16 --no-cpu-check"
stop() { [ -e $R/b65/stop ] && { echo "stopped" >> $O/rc.txt; exit 0; }; }
busy() { P=""; for i in $(seq 1 $1); do nice -n $2 sh -c 'while :; do :; done' & P="$P $!"; done
  echo "$(date -u +%T) busy $1 nice $2 pids$P" >> $O/busy.pids; sleep 2; }
unbusy() { for p in $P; do kill $p; done; wait $P 2>/dev/null; echo "$(date -u +%T) killed$P" >> $O/busy.pids; P=""; }
cell() { n=$1; k=$2; ni=$3; e=$4; shift 4; stop; [ "$k" -gt 0 ] && busy $k $ni
  bash $S/run_b65.sh b65-loadvk $n $e vk -- "$@"; [ "$k" -gt 0 ] && unbusy; }
cell vw65_q  0 0 head-spv/midout_wide_bench $W65
cell vw65_b6 6 0 head-spv/midout_wide_bench $W65
cell vn64_q  0 0 head-spv/midout_bench --threads 5 $N64
cell vn64_b6 6 0 head-spv/midout_bench --threads 5 $N64

echo done > $O/done
