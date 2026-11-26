#!/bin/bash
# run_mo.sh TAG RUN PHASES: the middle-out join on this Mac's GPU (Metal through wgpu; the device the client would use).
#   a  exactness: the card tier of nice_common's tests     b  timing: whole base-64 fields (and one of production's)
# No sampler: macOS gives no GPU load without root. Nothing reaches the production API.
. "$(dirname "$0")/env.sh"
TAG=$1; RUN=$2; PH=${3:-a}; BIN=$R/bin/$TAG; O=$R/runs/$RUN; mkdir -p "$O"; rm -f "$O/done"
export NICE_BUILD_SHA=test RUST_LOG=${RUST_LOG:-warn}
X=$BIN/t_box; HT=${HTHREADS:-8}
md5 -r "$BIN"/* > "$O/bins.txt"; echo "START $(date -u +%FT%T) tag=$TAG phases=$PH $(sysctl -n machdep.cpu.brand_string) macOS $(sw_vers -productVersion)" >> "$O/rc.txt"
g() { n=$1; shift; s0=$(date +%s); env "$@" > "$O/$n.txt" 2>&1; rc=$?
      echo "$n rc=$rc $(( $(date +%s) - s0 )) s $(grep -h -o 'test result: [a-zA-Z]*\. [0-9]* passed; [0-9]* failed' "$O/$n.txt" | tail -1)" >> "$O/rc.txt"; }
T="--nocapture --test-threads 1"
case $PH in *a*)
  g tier_b       $X --ignored cubecl_midout $T
  g slices       MIDOUT_GPU_SLICES=712012851,502136830 $X --ignored --exact midout::gpu::tests::gpu_slices_equal_cpu $T
  g faults       $X --ignored --exact midout::gpu::audit::accounts_faults_are_loud $T
  g share_faults $X --ignored --exact midout::gpu::tests::field_parent_sharing_is_exact_and_loud $T
  g wide_slices  $X --ignored --exact midout::gpu_wide::tests::wide_slices_equal_cpu $T
  g wide_faults  $X --ignored --exact midout::gpu_wide::tests::wide_faults_are_loud $T
;; esac
F2=43445731862957161709568; H=cubecl_join::tests::join_throughput_fixed_fields
case $PH in *b*)
  g b_r1    "$BIN/midout_bench" --threads "$HT" --fields "${MOFIELDS:-4095,77777}" --group 16
  g main_f2 NICE_TEST_JOIN_FIELDS=1 NICE_TEST_JOIN_SIZE=1e17 NICE_TEST_JOIN_BASES=64 NICE_TEST_JOIN_STARTS=64:$F2 $X --ignored --exact $H $T
;; esac
echo "END $(date -u +%FT%T)" >> "$O/rc.txt"; echo done > "$O/done"
