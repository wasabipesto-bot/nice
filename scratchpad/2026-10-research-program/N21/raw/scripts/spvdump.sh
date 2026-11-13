#!/bin/bash
# spvdump.sh LABEL N21 BASE [SIZE]: CubeCL's SPIR-V of every kernel one lavapipe run compiles at BASE (field = env
# start for that base, SIZE default 1e16 at b60, 1e17 at b62/b64, the timed fields' shapes), with NICE_EXP_N21=N21, by
# the spirv-dump binary $W/bin/${DB:-Xd}; killed after ${TMO:-120} s (only the compile is wanted). Then the join
# kernel is compiled for GFX1201 by RADV's null winsys (pipec) with RADV_DEBUG=shaders,shaderstats: $W/spv/LABEL/.
W=/root/n21; S=$W/scripts; T=$S/taskC
L=$1; N=$2; B=$3
F60=1447429612114824200908; F62=7520566762397899821056; F64=58557331862957161709568
case $B in 60) F=$F60; Z=${4:-1e16};; 62) F=$F62; Z=${4:-1e17};; 64) F=$F64; Z=${4:-1e17};; esac
D=$W/spv/$L; rm -rf $D; mkdir -p $D
export NICE_BUILD_SHA=test
( cd $D && VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/lvp_icd.json NICE_EXP_N21=$N CUBECL_DEBUG_SPIRV=$D LP_NUM_THREADS=2 \
  NICE_TEST_JOIN_FIELDS=1 NICE_TEST_JOIN_SIZE=$Z NICE_TEST_JOIN_BASES=$B NICE_TEST_JOIN_STARTS=$B:$F \
  timeout ${TMO:-120} nice -n 19 $W/bin/${DB:-Xd} --ignored --exact cubecl_join::tests::join_throughput_fixed_fields \
  --nocapture --test-threads 1 > $D/run.log 2>&1 )
export VK_ICD_FILENAMES=$W/mesa-inst/share/vulkan/icd.d/radeon_icd.x86_64.json RADV_FORCE_FAMILY=gfx1201
for s in $D/JoinKernel*.spv; do
  [ -f "$s" ] || { echo "$L: no join kernel SPIR-V"; tail -5 $D/run.log; exit 1; }
  k=${s%.spv}
  spirv-dis "$s" -o "$k.spvasm" 2>/dev/null
  python3 -I $T/reflect.py "$k.spvasm" > "$k.layout"
  ENTRY=$(sed -n 's/^# entry //p' "$k.layout") RADV_DEBUG=shaders,shaderstats $T/pipec "$s" "$k.layout" > "$k.aco.txt" 2>&1
  echo "$L n21=$N b$B $(basename $k): $(grep -o 'PIPEC ok\|failed.*' "$k.aco.txt" | head -1)"
  python3 -I $S/walkcount.py "$k.aco.txt"
  python3 -I $T/summarize.py "$k.aco.txt" | head -1 | cut -c1-200
done
