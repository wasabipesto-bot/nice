#!/bin/bash
# aco.sh DIR...: compile every SPIR-V module in DIR for GFX1201 (RX 9070 XT) with RADV from Mesa 26.0.8 on the amdgpu
# no-op DRM shim (inside the g2mesa container), RADV_DEBUG=shaders,shaderstats -> DIR/<kernel>.aco.txt
A=$(dirname $(readlink -f $0)); M=$A/../mesa
export VK_ICD_FILENAMES=$M/mesa-inst/share/vulkan/icd.d/radeon_icd.x86_64.json AMDGPU_GPU_ID=gfx1201
SHIM=$M/mesa-26.0.8/build/src/amd/drm-shim/libamdgpu_noop_drm_shim.so
for D in "$@"; do for s in $D/*.spv; do
  k=${s%.spv}
  spirv-dis "$s" -o "$k.spvasm" 2>/dev/null
  python3 -I $A/reflect.py "$k.spvasm" > "$k.layout"
  ENTRY=$(sed -n 's/^# entry //p' "$k.layout") LD_PRELOAD=$SHIM RADV_DEBUG=shaders,shaderstats $A/pipec "$s" "$k.layout" > "$k.aco.txt" 2>&1
  echo "$(basename $k): $(grep -o 'PIPEC ok\|failed.*' "$k.aco.txt" | head -1) $(grep -o 'PIPEC device=[^\n]*' "$k.aco.txt" | head -1)"
done; done
