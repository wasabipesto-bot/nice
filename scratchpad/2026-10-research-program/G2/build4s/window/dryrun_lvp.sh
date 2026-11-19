#!/bin/sh
# dryrun_lvp.sh WS: the whole of go_mo.sh on ivory's lavapipe (container lvp26, W 8, 2 threads), at sizes it can
# finish: one slice per parity process, the wide path at b40 only, fields of 1 slice (--slices 1), main's two
# bracket fields at 1e14 (smaller fields route to the stride pipeline). BIN=WS/bin must hold t_mo, mo_bench and
# mo_wide_bench built --features cubecl-spirv (and t_pr270 for the optional step 0). Everything else is go_mo.sh unchanged.
WS=$1; D=$(dirname "$(readlink -f "$0")")
podman run --rm --cgroups=disabled -v $WS:$WS -v $D:$D -w $WS \
  -e VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/lvp_icd.json -e LP_NUM_THREADS=2 \
  -e W=$WS -e DEV=lvp -e PAR=0 -e MOCLS=4 -e XWCLS=2 -e HTHREADS=2 \
  -e XS1=712012851 -e XS2=4977728 -e XS3=1061942336 -e X496=77777 -e XWIDE=40:3:6:1234 -e XFAULT=712012851 \
  -e MOPART="--slices 1" -e MOFIELDS=4095,77777 -e STAGEF=4095,77777 -e SZ64=1e14 \
  -e END_AT=$(( $(date +%s) + ${MINUTES:-120} * 60 )) localhost/lvp26 sh $D/go_mo.sh
