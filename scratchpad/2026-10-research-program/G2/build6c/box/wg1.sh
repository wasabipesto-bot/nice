#!/bin/bash
# box: wg1.sh TAG OUT — the base-64 device tests at CI size on lavapipe through WGSL (naga), test binary t_wg of TAG
X=/root/bin/$1/t_wg; O=/root/runs/$2; mkdir -p $O; export VK_ICD_FILENAMES=$(ls /usr/share/vulkan/icd.d/lvp_icd*.json | head -1)
for t in midout::gpu::tests::gpu_slices_equal_cpu; do
  s0=$(date +%s); env MIDOUT_CLASSES=4 MIDOUT_BATCHES=1 $X --ignored --exact $t --nocapture --test-threads 1 > $O/$(basename ${t//::/_}).txt 2>&1
  echo "$t rc=$? $(( $(date +%s) - s0 )) s" >> $O/rc.txt
done
echo done > $O/done
