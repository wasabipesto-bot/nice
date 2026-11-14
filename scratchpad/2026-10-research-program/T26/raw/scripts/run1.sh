#!/bin/bash
# run1.sh: the reproduction on main's top_slot (R = main + test-only harness, RS its SPIR-V build) and the fix's
# regression test (F, FS). CUDA chain and lavapipe chain run side by side (no timing here).
W=/root/t26; S=$W/scripts
LVP="export VK_ICD_FILENAMES=$(ls /usr/share/vulkan/icd.d/lvp_icd*.json | head -n1)"
(
  eval $LVP
  for b in R RS; do
    bash $S/t.sh repro_lvp_$b $b repro_top_partial_planes_wgpu REPRO_LANE0=1
  done
  for b in F FS; do
    bash $S/t.sh fix_lvp_partial_$b $b top_fd_appends_every_top_on_partly_filled_planes
  done
) > $W/out/run1_lvp.out 2>&1 &
TMO=1800 bash $S/t.sh repro_cuda_ballot R repro_cuda_top_partial_warps
TMO=1800 bash $S/t.sh fix_cuda_partial_F F cubecl_cuda_top_fd_appends_every_top_on_partly_filled_warps
TMO=600 bash $S/t.sh repro_cuda_scan_partial R repro_cuda_top_partial_warps REPRO_FORMS=s REPRO_WGS=100,48
TMO=600 bash $S/t.sh repro_cuda_lane0_256 R repro_cuda_top_partial_warps REPRO_LANE0=only REPRO_WGS=256
wait
echo RUN1_DONE $(date -u +%T)
