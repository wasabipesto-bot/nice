#!/bin/bash
# box: tiers.sh TAG — tier (a) (every non-ignored nice_common lib test with the device modules compiled: CUDA +
# SPIR-V features) in release (4 threads) and in debug (`just test`'s profile), each timed; then tier (b) on
# lavapipe with both compilers (wg: WGSL via naga, sc: CubeCL's SPIR-V compiler), one test at a time, timed.
# Test binaries by bt.sh (sc, wg) into /root/bin/TAG. Output /root/runs/TAG.
T=$1; O=/root/runs/$T; mkdir -p $O; rm -f $O/done $O/rc.txt; source ~/.cargo/env
bash /root/bt.sh mc $T; cp /root/logs/$T/bins.txt $O/
LVP=$(ls /usr/share/vulkan/icd.d/lvp_icd*.json | head -1)
run() { local n=$1; shift; s0=$(date +%s); env "$@" > $O/$n.txt 2>&1; echo "$n rc=$? $(( $(date +%s) - s0 )) s" >> $O/rc.txt; }
run tier_a_release /root/bin/$T/t_sc --test-threads 4
(cd /root/mc; CARGO_TARGET_DIR=/root/t/mcd cargo test -p nice_common --features cubecl-cuda,cubecl-spirv --lib --no-run > $O/build_debug.txt 2>&1)
XD=$(grep -oP "Executable unittests src/lib.rs \(\K[^)]*" $O/build_debug.txt | tail -1)
run tier_a_debug $XD --test-threads 4
for k in wg sc; do
  for t in $(/root/bin/$T/t_$k --list --ignored 2>/dev/null | grep -o "^[a-z_:0-9]*cubecl_midout[a-z_0-9]*"); do
    run b_${k}_${t##*::} VK_ICD_FILENAMES=$LVP /root/bin/$T/t_$k --ignored --exact $t --nocapture --test-threads 1
  done
done
echo done > $O/done
