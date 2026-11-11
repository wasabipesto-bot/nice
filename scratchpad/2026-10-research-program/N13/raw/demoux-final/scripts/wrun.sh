#!/bin/sh
# wrun.sh NAME BIN BASES N SIZE: the wgpu throughput harness (join_throughput_fixed_fields, CubeclContext::new_default:
# wgpu, here Vulkan/RADV with CubeCL's SPIR-V compiler) on NICE_TEST_JOIN_LIST (or N consecutive fields from STARTS);
# one untimed 1e14 warm-up field first. Logs $W/out/NAME.log and NAME.gpu (busy %, sclk, power every 5 s).
W=/tmp/claude-exp-2026-11-11-amd
NAME=$1; BIN=$2; BASES=$3; N=$4; SIZE=$5
OUT=$W/out; export NICE_BUILD_SHA=test
STARTS=${STARTS:-60:1366406074057412100454,62:7997740455941656911841,64:41242006262957161709568}
if [ -n "${NICE_TEST_JOIN_LIST:-}" ]; then STARTS=$BASES:${NICE_TEST_JOIN_LIST%%,*}; fi
D=$(ls -d /sys/class/drm/card*/device 2>/dev/null | while read d; do [ -e $d/gpu_busy_percent ] && echo $d; done | head -1)
HW=$(ls -d $D/hwmon/hwmon* 2>/dev/null | head -1)
( while true; do echo "$(date -u +%T) busy=$(cat $D/gpu_busy_percent) sclk=$(grep '\*' $D/pp_dpm_sclk | tr -d ' *') pw=$(cat $HW/power1_average 2>/dev/null || cat $HW/power1_input 2>/dev/null) cap=$(cat $HW/power1_cap 2>/dev/null) temp=$(cat $HW/temp1_input 2>/dev/null) load=$(cut -d' ' -f1 /proc/loadavg)"; sleep 5; done ) > $OUT/$NAME.gpu 2>&1 &
MON=$!
echo "START $NAME $(date -u +%T) bases=$BASES n=$N size=$SIZE env=[$(env | grep -E '^NICE_(EXP_|TEST_JOIN_LIST)' | sort | tr '\n' ' ')] bin=$BIN md5=$(md5sum $W/bin/$BIN | cut -c1-8)" > $OUT/$NAME.log
NICE_TEST_JOIN_FIELDS=$N NICE_TEST_JOIN_SIZE=$SIZE NICE_TEST_JOIN_BASES=$BASES NICE_TEST_JOIN_STARTS=$STARTS \
  $W/bin/$BIN --ignored --exact cubecl_join::tests::join_throughput_fixed_fields --nocapture --test-threads 1 >> $OUT/$NAME.log 2>&1
echo "END $NAME $(date -u +%T) rc=$?" >> $OUT/$NAME.log
kill $MON
