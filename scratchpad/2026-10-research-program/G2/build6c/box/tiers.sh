#!/bin/bash
# box: tiers.sh TAG — build /root/mc's test binaries (bt.sh: sc = cubecl-cuda,cubecl-spirv; wg = cubecl) and run
# tier (a) (every non-ignored nice_common lib test, with the device modules compiled) and tier (b) on lavapipe with
# both compilers (wg: WGSL via naga, sc: CubeCL's SPIR-V compiler), one test at a time, timed. Output /root/runs/TAG.
T=$1; O=/root/runs/$T; mkdir -p $O; rm -f $O/done $O/rc.txt
bash /root/bt.sh mc $T; cp /root/logs/$T/bins.txt $O/
LVP=$(ls /usr/share/vulkan/icd.d/lvp_icd*.json | head -1)
run() { local n=$1; shift; s0=$(date +%s); env "$@" > $O/$n.txt 2>&1; echo "$n rc=$? $(( $(date +%s) - s0 )) s" >> $O/rc.txt; }
run tier_a /root/bin/$T/t_sc --test-threads 4
for k in wg sc; do
  for t in $(/root/bin/$T/t_$k --list --ignored 2>/dev/null | grep -o "^[a-z_:0-9]*cubecl_midout[a-z_0-9]*"); do
    run b_${k}_${t##*::} VK_ICD_FILENAMES=$LVP /root/bin/$T/t_$k --ignored --exact $t --nocapture --test-threads 1
  done
done
echo done > $O/done
