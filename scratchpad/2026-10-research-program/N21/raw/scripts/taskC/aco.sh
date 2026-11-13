#!/bin/sh
# aco.sh MODE: compile each SPIR-V of $OUT/spv_MODE/ for GFX1201 on RADV's null winsys (pipec), RADV_DEBUG=shaders,
# shaderstats: $OUT/spv_MODE/<kernel>.aco.txt. Also SUBGROUP=32 / 64 variants of the join kernel (required subgroup size).
. "${SCRIPTS:-/root/n16/scripts}/env.sh"
T=$SCRIPTS/taskC
export VK_ICD_FILENAMES=$W/mesa-inst/share/vulkan/icd.d/radeon_icd.x86_64.json RADV_FORCE_FAMILY=gfx1201
for s in $OUT/spv_$1/*.spv; do
  k=${s%.spv}
  spirv-dis "$s" -o "$k.spvasm" 2>/dev/null
  python3 -I $T/reflect.py "$k.spvasm" > "$k.layout"
  ENTRY=$(sed -n 's/^# entry //p' "$k.layout") RADV_DEBUG=shaders,shaderstats $T/pipec "$s" "$k.layout" > "$k.aco.txt" 2>&1
  echo "$(basename $k): $(grep -o 'PIPEC ok\|failed.*' "$k.aco.txt" | head -1) $(wc -l < "$k.aco.txt") lines"
  case $k in *JoinKernel*) for sg in 32 64; do
    SUBGROUP=$sg ENTRY=$(sed -n 's/^# entry //p' "$k.layout") RADV_DEBUG=shaders,shaderstats $T/pipec "$s" "$k.layout" > "$k.aco$sg.txt" 2>&1
    echo "  subgroup $sg: $(grep -o 'PIPEC ok\|failed.*' "$k.aco$sg.txt" | head -1)"; done;;
  esac
done
