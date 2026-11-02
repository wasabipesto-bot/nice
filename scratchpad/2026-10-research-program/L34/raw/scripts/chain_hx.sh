#!/bin/bash
# Hybrid H (fcd6581) after the post profile: lavapipe builds (CPU) beside CUDA exactness (MIN=128, G=4), then lavapipe
# (parity naga + SPIR-V, WGSL lint) with MIN=128, then a short interleaved A/B off / F G=4 / H G=4 MIN=128 and NiceMark.
L=/root/l34/logs; S=/root/l34; R=$S/run.sh; T=$S/test.sh; BIN=/root/l34/bin
until [ -e $L/post.done ]; do sleep 20; done
ON="NICE_EXP_JOIN_TRANSPOSE=1 NICE_EXP_JOIN_TRANSPOSE_G=4 NICE_EXP_JOIN_TRANSPOSE_MIN=128"
( $S/buildclient.sh H client_H && $S/build.sh H H_naga cubecl && $S/build.sh H H_spv cubecl-spirv && echo HBUILDS_DONE $(date -u +%T) > $L/hbuilds.done ) > $L/hbuilds.out 2>&1 &
$T hx_ref H cubecl_join::tests::cubecl_cuda_join_matches_the_cpu_reference $ON
$T hx_dense58 H cubecl_join::tests::cubecl_cuda_join_matches_the_cpu_join_on_a_dense_field $ON NICE_TEST_JOIN_DENSE=32
$T hx_dense62 H cubecl_join::tests::cubecl_cuda_join_matches_the_cpu_join_on_a_dense_field $ON NICE_TEST_JOIN_DENSE=4 NICE_TEST_JOIN_DENSE_FIELD=62:7997740455941656911841:1e16
$T hx_whole H cubecl_join::tests::cubecl_cuda_join_matches_the_reference_on_a_whole_field $ON NICE_TEST_JOIN_FULL_FIELD=1
env $ON $R hcmp_on_e14 H 57,60,62,64 1 1e14 1
wait
[ -e $L/hbuilds.done ] || { echo "H builds failed"; exit 1; }
export VK_ICD_FILENAMES=$(ls /usr/share/vulkan/icd.d/lvp_icd*.json | head -n1)
cd /root/l34/src/H
REQ="--require DetailedKernelU32@80 --require DetailedFdKernelU32@40 --require DetailedFdKernelU32@50 --require DetailedFdKernel@23 --require DetailedFdKernel@40 --require DetailedFdKernel@50 --require DetailedFdKernel@62 --require DetailedKernel@80 --require NiceonlyKernel@40 --require BucketKernel@57 --require JoinKernel@57 --require TopKernel@57 --require CheckKernel@57"
rm -f $L/wgsl_h.log
( date -u; env $ON NICE_BUILD_SHA=test CUBECL_DEBUG_LOG=$L/wgsl_h.log timeout 900 $BIN/H_naga --ignored --exact cubecl_backend::tests::wgsl_dump_for_lint --nocapture; echo "exit $?"; date -u ) > $L/hlint_dump.log 2>&1
( python3 /root/l34/src/H/scripts/wgsl-lint.py $L/wgsl_h.log $REQ --verbose; echo "lint rc=$?" ) > $L/hwgsl_lint.log 2>&1
gzip -f $L/wgsl_h.log
P=cubecl_join::tests::cubecl_join_matches_the_cpu_reference
( date -u; env $ON NICE_BUILD_SHA=test timeout 1800 $BIN/H_naga --ignored --exact $P --nocapture --test-threads 1; echo "exit $?"; date -u ) > $L/hlvp_par_naga.log 2>&1
( date -u; env $ON NICE_BUILD_SHA=test timeout 1800 $BIN/H_spv --ignored --exact $P --nocapture --test-threads 1; echo "exit $?"; date -u ) > $L/hlvp_par_spv.log 2>&1
unset VK_ICD_FILENAMES
echo HX_DONE $(date -u +%T) > $L/hx.done
# Short A/B (quiet box): off, F G=4, H G=4 MIN=128 per round.
FON="NICE_EXP_JOIN_TRANSPOSE=1 NICE_EXP_JOIN_TRANSPOSE_G=4"
for r in 1 2; do
  $R hab_off_e17_b62_r$r F 62 1 1e17; env $ON $R hab_h_e17_b62_r$r H 62 1 1e17
done
for spec in "62 1e16" "60 1e16" "64 1e16"; do set -- $spec
  for r in 1 2; do
    $R hab_off_e16_b$1_r$r F $1 2 1e16; env $FON $R hab_f_e16_b$1_r$r F $1 2 1e16; env $ON $R hab_h_e16_b$1_r$r H $1 2 1e16
  done
done
for r in 1 2; do
  $R hab_off_e14_r$r F 60,62,64 3 1e14; env $FON $R hab_f_e14_r$r F 60,62,64 3 1e14; env $ON $R hab_h_e14_r$r H 60,62,64 3 1e14
done
echo HAB_DONE $(date -u +%T) > $L/hab.done
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH:-} NICE_API_BASE=http://127.0.0.1:9
cd /root/l34
for r in 1 2; do
  for s in off h; do
    ( while true; do nvidia-smi --query-gpu=timestamp,clocks.sm,clocks.mem,power.draw,power.limit,temperature.gpu,utilization.gpu,clocks_throttle_reasons.active --format=csv,noheader; sleep 5; done ) > $L/hnm_${s}_r$r.smi 2>&1 &
    SMI=$!
    if [ $s = h ]; then export NICE_EXP_JOIN_TRANSPOSE=1 NICE_EXP_JOIN_TRANSPOSE_G=4 NICE_EXP_JOIN_TRANSPOSE_MIN=128; else unset NICE_EXP_JOIN_TRANSPOSE NICE_EXP_JOIN_TRANSPOSE_G NICE_EXP_JOIN_TRANSPOSE_MIN; fi
    echo "START hnm_${s}_r$r $(date -u +%T) T=${NICE_EXP_JOIN_TRANSPOSE:-unset} MIN=${NICE_EXP_JOIN_TRANSPOSE_MIN:-unset} md5=$(md5sum $BIN/client_H | cut -c1-8)" > $L/hnm_${s}_r$r.err
    $BIN/client_H niceonly --gpu --benchmark --benchmark-secs 150 --benchmark-json < /dev/null > $L/hnm_${s}_r$r.json 2>> $L/hnm_${s}_r$r.err
    echo "END hnm_${s}_r$r $(date -u +%T) rc=$?" >> $L/hnm_${s}_r$r.err
    kill $SMI
  done
done
echo HNM_DONE $(date -u +%T) > $L/hnm.done
