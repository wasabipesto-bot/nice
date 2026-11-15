#!/bin/bash
# spvdump.sh LABEL N22 BASE [SIZE]: CubeCL's SPIR-V of every kernel one lavapipe run compiles at BASE (field = the
# production start for that base, N16/raw/scripts/env.sh; SIZE default 1e17), with NICE_EXP_N22=N22, by the
# spirv-dump binary $W/bin/${DB:-Ed1}; killed after ${TMO:-150} s (only the compile is wanted). Then every kernel is
# compiled for GFX1201 by RADV's null winsys (pipec, Mesa 26.0.8, wave64 as wgpu creates it) with
# RADV_DEBUG=shaders,shaderstats: $W/spv/LABEL/<kernel>.aco.txt. (From N21's spvdump.sh: all kernels, not only the join.)
W=/root/n22; S=$W/scripts; T=$S/taskC
L=$1; N=$2; B=$3
F60=1447429612114824200908; F62=7520566762397899821056; F64=58557331862957161709568
case $B in 60) F=$F60; Z=${4:-1e16};; 62) F=$F62; Z=${4:-1e17};; 64) F=$F64; Z=${4:-1e17};; esac
D=$W/spv/$L; [ -n "$SKIPRUN" ] || { rm -rf $D; mkdir -p $D; }
export NICE_BUILD_SHA=test
[ -n "$SKIPRUN" ] || ( cd $D && VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/lvp_icd.json NICE_EXP_N22=$N CUBECL_DEBUG_SPIRV=$D LP_NUM_THREADS=2 \
  NICE_TEST_JOIN_FIELDS=1 NICE_TEST_JOIN_SIZE=$Z NICE_TEST_JOIN_BASES=$B NICE_TEST_JOIN_STARTS=$B:$F \
  timeout ${TMO:-150} nice -n 19 $W/bin/${DB:-Ed1} --ignored --exact cubecl_join::tests::join_throughput_fixed_fields \
  --nocapture --test-threads 1 > $D/run.log 2>&1 )
# Mesa 26 removed RADV_FORCE_FAMILY: the amdgpu no-op DRM shim exposes a GFX1201 device instead.
export VK_ICD_FILENAMES=$W/mesa-inst/share/vulkan/icd.d/radeon_icd.x86_64.json AMDGPU_GPU_ID=gfx1201
SHIM=$W/mesa/mesa-26.0.8/build/src/amd/drm-shim/libamdgpu_noop_drm_shim.so
for s in $D/*.spv; do
  [ -f "$s" ] || { echo "$L: no SPIR-V"; tail -5 $D/run.log; exit 1; }
  k=${s%.spv}
  spirv-dis "$s" -o "$k.spvasm" 2>/dev/null
  python3 -I $T/reflect.py "$k.spvasm" > "$k.layout"
  ENTRY=$(sed -n 's/^# entry //p' "$k.layout") LD_PRELOAD=$SHIM RADV_DEBUG=shaders,shaderstats $T/pipec "$s" "$k.layout" > "$k.aco.txt" 2>&1
  echo "$L n22=$N b$B $(basename $k): $(grep -o 'PIPEC ok\|failed.*' "$k.aco.txt" | head -1) $(python3 -I $T/summarize.py "$k.aco.txt" | head -1 | cut -c1-160)"
done
