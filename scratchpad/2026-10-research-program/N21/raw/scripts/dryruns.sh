#!/bin/bash
# dryruns.sh: the window scripts end to end, as demoux will run them (dryrun_window.sh): first under CUDA (fresh clone
# from GitHub, build, b62/b64/b60 chains at 1e16/1e15), then the same workspace under lavapipe (DEV=wgpu, KEEP=1: no
# re-clone, the build is cached) at 1e13. Untimed; starts after after_ab.sh's builds.
W=/root/n21
until [ -e $W/out/dumps3.done ]; do sleep 20; done
echo DRY_CUDA_START $(date -u +%T)
W=/root/win DEV=cuda JOBS=8 MINUTES=30 SZ=1e16 bash $W/scripts/window/dryrun_window.sh
tail -25 /root/win/out/go.out
echo DRY_WGPU_START $(date -u +%T)
W=/root/win DEV=wgpu KEEP=1 JOBS=8 MINUTES=40 SZ=1e13 VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/lvp_icd.json \
  bash $W/scripts/window/dryrun_window.sh
tail -25 /root/win/out/go.out
echo DRYRUNS_DONE $(date -u +%T)
