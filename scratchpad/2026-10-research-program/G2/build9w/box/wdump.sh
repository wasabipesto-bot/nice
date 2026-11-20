#!/bin/bash
# box: wdump.sh TAG TBOX — the wide path's SPIR-V at 64 lanes, base 65, without the card: the parity test on
# lavapipe with MIDOUT_FORCE_W=64 (every kernel compiled for W 64; lavapipe runs them on narrower planes, so the run
# is COMPILE-ONLY and its results are invalid), CUBECL_DEBUG_SPIRV dumps each module to /root/dump/TAG. ACO for
# GFX1201 then runs on ivory (g2mesa).
T=$1; X=$2; O=/root/dump/$T; rm -rf $O; mkdir -p $O; md5sum $X > $O/bins.txt
LVP=$(ls /usr/share/vulkan/icd.d/lvp_icd*.json | head -1)
cd $O && timeout 1200 env CUBECL_DEBUG_SPIRV=$O VK_ICD_FILENAMES=$LVP LP_NUM_THREADS=2 MIDOUT_FORCE_W=64 MIDOUT_WIDE_CASES=65:4:10:717171717 MIDOUT_CLASSES=1 \
  $X --ignored --exact midout::gpu_wide::tests::wide_slices_equal_cpu --nocapture --test-threads 1 > $O/run.txt 2>&1
echo "rc=$? (a failure is expected: W 64 on lavapipe's planes)" >> $O/run.txt; ls $O/*.spv | wc -l >> $O/run.txt
