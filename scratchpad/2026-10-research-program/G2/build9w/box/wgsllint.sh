#!/bin/bash
# box: wgsllint.sh TAG OUT — the WGSL CubeCL generates for every middle-out kernel the tier-(b) tests compile
# (lavapipe, test binary t_wg of TAG, CUBECL_DEBUG_LOG), then production's Apple half-shift-division lint on it
# (scripts/wgsl-lint.py from /root/mc). Kernels are compiled at the first launch, so short runs suffice.
X=/root/bin/$1/t_wg; O=/root/runs/$2; mkdir -p $O; rm -f $O/done $O/wgsl.log; export VK_ICD_FILENAMES=$(ls /usr/share/vulkan/icd.d/lvp_icd*.json | head -1)
for t in midout::gpu::tests::cubecl_midout_shared_parents_slice_part_equals_cpu midout::gpu::tests::cubecl_midout_check_rebuilds_the_survivors midout::gpu_wide::tests::cubecl_midout_wide_b40_slice_equals_cpu; do
  CUBECL_DEBUG_LOG=$O/wgsl.log $X --ignored --exact $t --test-threads 1 > $O/run_${t##*::}.txt 2>&1; echo "$t rc=$?" >> $O/rc.txt
done
grep -o "^name: [^<]*" $O/wgsl.log | sort | uniq -c > $O/kernels.txt
python3 /root/mc/scripts/wgsl-lint.py --verbose $O/wgsl.log > $O/lint.txt 2>&1; echo "wgsl-lint rc=$?" >> $O/rc.txt
echo done > $O/done
