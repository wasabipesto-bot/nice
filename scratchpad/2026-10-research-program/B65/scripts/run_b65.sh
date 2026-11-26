#!/bin/bash
# run_b65.sh RUN NAME BINTAG/EXE RT [VAR=VALUE ...] -- ARGS: one bench process on the RTX 3060, card and host sampled.
#   RT  cuda (CUDA_VISIBLE_DEVICES=1, --cuda added) | vk (env_vulkan.sh, wgpu adapter DiscreteGpu(1))
# Output: $R/runs/RUN/NAME.{log,gpu,cpu}. Nothing reaches the production API (env.sh).
. "$HOME/research/scripts/env.sh"
RUN=$1; NAME=$2; B=$3; EXE=$R/bin/$3; RT=$4; shift 4
E=""; while [ "$1" != "--" ]; do E="$E $1"; shift; done; shift
O=$R/runs/$RUN; mkdir -p "$O"
export NICE_BUILD_SHA=test RUST_LOG=${RUST_LOG:-warn}
X=""
case $RT in
  cuda) export CUDA_VISIBLE_DEVICES=1 MIDOUT_CUDA=1; X=--cuda ;;
  vk)   . "$R/scripts/env_vulkan.sh"; export CUBECL_WGPU_DEFAULT_DEVICE='DiscreteGpu(1)' ;;
  *) echo "RT cuda|vk"; exit 2 ;;
esac
nvidia-smi -i 1 --query-gpu=timestamp,utilization.gpu,power.draw,clocks.gr,clocks.mem,clocks.sm,pstate,temperature.gpu,memory.used,clocks_throttle_reasons.active --format=csv,noheader,nounits -lms 500 > "$O/$NAME.gpu" 2>&1 & MON=$!
vmstat -n 1 > "$O/$NAME.cpu" 2>&1 & VM=$!
echo "START $NAME $(date -u +%FT%T) exe=$B md5=$(md5sum "$EXE" | cut -c1-8) rt=$RT env=[$E] args=[$X $*]" > "$O/$NAME.log"
s0=$(date +%s%N)
env $E "$EXE" $X "$@" >> "$O/$NAME.log" 2>&1; RC=$?
echo "END $NAME $(date -u +%FT%T) rc=$RC wall=$(( ($(date +%s%N) - s0) / 1000000 )) ms" >> "$O/$NAME.log"
kill $MON $VM 2>/dev/null; wait $MON $VM 2>/dev/null
echo "$(date -u +%T) $NAME rc=$RC $(grep -h 'fs per admissible' "$O/$NAME.log" | tail -1 | cut -c1-110)" >> "$O/rc.txt"
