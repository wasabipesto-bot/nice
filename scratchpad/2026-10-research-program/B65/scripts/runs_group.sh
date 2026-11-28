#!/bin/bash
# runs_group.sh SPVTAG: the group-size sweep (EXPERIMENTS.md B65.8; B65/AHEAD-DESIGN.md). No code is changed: the
# benches' --group argument sets how many slices are queued between two reads, so the number of idle gaps per field
# is 1/group of it. RTX 3060 through Vulkan with the direct SPIR-V compiler; base 64 narrow at group 16, 64, 256 and
# base 65 wide at group 16, 64; each quiet and under 6 busy loops (PIDs recorded, killed by PID); a second quiet
# group-16 cell of each at the end as a drift check. A cell that runs out of memory fails loudly and is recorded.
#   SPVTAG  directory under $R/bin holding midout_bench and midout_wide_bench of one SPIR-V build
# Output: $R/runs/b65-group/NAME.{log,gpu,cpu}, rc.txt, busy.pids, done.
. "$HOME/research/scripts/env.sh"
T=${1:?SPVTAG}; S=$R/b65/scripts; O=$R/runs/b65-group; mkdir -p $O
[ -x $R/bin/$T/midout_bench ] && [ -x $R/bin/$T/midout_wide_bench ] || { echo "no benches under $R/bin/$T"; exit 2; }
echo "$(date -u +%FT%T) sweep of $T: $(md5sum $R/bin/$T/midout_bench $R/bin/$T/midout_wide_bench | cut -c1-8 | tr '\n' ' ')" >> $O/rc.txt
stop() { [ -e $R/b65/stop ] && { echo "stopped" >> $O/rc.txt; exit 0; }; }
busy() { P=""; for i in $(seq 1 $1); do sh -c 'while :; do :; done' & P="$P $!"; done
  echo "$(date -u +%T) busy $1 pids$P" >> $O/busy.pids; sleep 2; }
unbusy() { for p in $P; do kill $p; done; wait $P 2>/dev/null; echo "$(date -u +%T) killed$P" >> $O/busy.pids; P=""; }
cell() { n=$1; k=$2; shift 2; stop; [ "$k" -gt 0 ] && busy $k
  bash $S/run_b65.sh b65-group $n "$@"; [ "$k" -gt 0 ] && unbusy; }
n64() { cell $1 $2 $T/midout_bench vk -- --threads 5 --fields 4095,77777 --group $3 --no-cpu-check; }
w65() { cell $1 $2 $T/midout_wide_bench vk -- --base 65 --fields 13731,77777 --group $3; }
n64 n64_g16_q   0 16
n64 n64_g16_b6  6 16
n64 n64_g64_q   0 64
n64 n64_g64_b6  6 64
n64 n64_g256_q  0 256
n64 n64_g256_b6 6 256
n64 n64_g16_q2  0 16
w65 w65_g16_q   0 16
w65 w65_g16_b6  6 16
w65 w65_g64_q   0 64
w65 w65_g64_b6  6 64
w65 w65_g16_q2  0 16
echo done > $O/done
