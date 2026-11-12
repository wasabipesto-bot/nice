#!/bin/sh
# taskC_dump.sh MODE...: compile the join pipeline for the RX 9070 XT (GFX1201) without the card: RADV's null winsys
# (RADV_FORCE_FAMILY=gfx1201, Mesa built by taskC_build_mesa.sh) under the N16 binary's wgpu harness on one small b60
# field, RADV_DEBUG=shaders,shaderstats dumping NIR / ACO IR / disassembly at pipeline creation. Nothing executes, so
# the run stalls at its first readback: a timeout ends it. One dump per mode in $OUT/aco_<mode>.txt.
. "${SCRIPTS:-$(dirname "$0")}/env.sh"
. "$SCRIPTS/modes.sh"
for m in ${@:-c wg128 wg64}; do
  setmode $m; unset NICE_EXP_HOSTACC
  VK_ICD_FILENAMES=$W/mesa-inst/share/vulkan/icd.d/radeon_icd.x86_64.json RADV_FORCE_FAMILY=gfx1201 \
  RADV_DEBUG=shaders,shaderstats ACO_DEBUG=${ACO_DEBUG:-} NICE_EXP_INFO=1 \
  NICE_TEST_JOIN_FIELDS=1 NICE_TEST_JOIN_SIZE=1e15 NICE_TEST_JOIN_BASES=60 NICE_TEST_JOIN_STARTS=60:$F60 \
  NICE_TEST_JOIN_LIST=$F60 timeout ${TMO:-90} "$BIN/${NB:-N16}" --ignored --exact cubecl_join::tests::join_throughput_fixed_fields \
    --nocapture --test-threads 1 > "$OUT/aco_$m.txt" 2>&1
  echo "$m rc=$? $(wc -c < "$OUT/aco_$m.txt") bytes, $(grep -c 'ACO shader stage' "$OUT/aco_$m.txt") ACO dumps"
done
