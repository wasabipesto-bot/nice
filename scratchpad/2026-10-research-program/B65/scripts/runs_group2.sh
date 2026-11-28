#!/bin/bash
# runs_group2.sh SPVTAG [WAITFILE]: B65.10, the group size for production's route (EXPERIMENTS.md B65.8, B65.10).
# Holds the box up with its own file (keep-up.g2), waits for WAITFILE if given (the V5 chain's done file), then on
# the RTX 3060 through Vulkan/SPIR-V: base 64 narrow at group 128 and base 65 wide at groups 128 and 256, quiet and
# under 6 busy loops, with a quiet and a busy group-16 cell of base 64 in the same session; then the GTX 1060 3 GB:
# one base-64 field at group 16 and one at group 256 (does the larger group still fit; card memory sampled).
# Output $R/runs/b65-group2/. Ends by removing its hold and running off_if_idle.sh.
. "$HOME/research/scripts/env.sh"
T=${1:?SPVTAG}; S=$R/b65/scripts; O=$R/runs/b65-group2; mkdir -p $O $R/g2
touch $R/keep-up.g2
exec >> $R/g2/chain.log 2>&1
echo "$(date -u +%FT%T) runs_group2 start, waiting for ${2:-nothing}"
if [ -n "$2" ]; then until [ -e "$2" ] || [ -e $R/g2/stop ]; do sleep 30; done; fi
fin() { rm -f $R/keep-up.g2; bash -l $R/scripts/off_if_idle.sh; }
[ -e $R/g2/stop ] && { echo stopped; fin; exit 0; }
[ -x $R/bin/$T/midout_bench ] && [ -x $R/bin/$T/midout_wide_bench ] || { echo "no benches under $R/bin/$T"; fin; exit 2; }
echo "$(date -u +%FT%T) sweep 2 of $T" >> $O/rc.txt
busy() { P=""; for i in $(seq 1 $1); do sh -c 'while :; do :; done' & P="$P $!"; done
  echo "$(date -u +%T) busy $1 pids$P" >> $O/busy.pids; sleep 2; }
unbusy() { for p in $P; do kill $p; done; wait $P 2>/dev/null; echo "$(date -u +%T) killed$P" >> $O/busy.pids; P=""; }
cell() { n=$1; k=$2; shift 2; [ -e $R/g2/stop ] && { echo stopped >> $O/rc.txt; fin; exit 0; }; [ "$k" -gt 0 ] && busy $k
  bash $S/run_b65.sh b65-group2 $n "$@"; [ "$k" -gt 0 ] && unbusy; }
n64() { cell $1 $2 $T/midout_bench vk -- --threads 5 --fields 4095,77777 --group $3 --no-cpu-check; }
w65() { cell $1 $2 $T/midout_wide_bench vk -- --base 65 --fields 13731,77777 --group $3; }
n64 n64_g16_q    0 16
n64 n64_g16_b6   6 16
n64 n64_g128_q   0 128
n64 n64_g128_b6  6 128
w65 w65_g128_q   0 128
w65 w65_g128_b6  6 128
w65 w65_g256_q   0 256
w65 w65_g256_b6  6 256
# the GTX 1060 3 GB (wgpu adapter DiscreteGpu(0), nvidia-smi index 0): one field each
g1060() { n=$1; g=$2
  nvidia-smi -i 0 --query-gpu=timestamp,utilization.gpu,power.draw,memory.used --format=csv,noheader,nounits -lms 500 > $O/$n.gpu 2>&1 & MON=$!
  ( . $R/scripts/env_vulkan.sh; export CUBECL_WGPU_DEFAULT_DEVICE='DiscreteGpu(0)' NICE_BUILD_SHA=test RUST_LOG=warn
    $R/bin/$T/midout_bench --threads 5 --fields 77777 --group $g --no-cpu-check ) > $O/$n.log 2>&1; rc=$?
  kill $MON 2>/dev/null; wait $MON 2>/dev/null
  echo "$(date -u +%T) $n rc=$rc $(grep -h 'fs per admissible' $O/$n.log | tail -1 | cut -c1-110) memmax $(cut -d, -f4 $O/$n.gpu | sort -n | tail -1) MiB" >> $O/rc.txt; }
g1060 g1060_n64_g16 16
g1060 g1060_n64_g256 256
echo done > $O/done; echo "$(date -u +%FT%T) runs_group2 done"
fin
