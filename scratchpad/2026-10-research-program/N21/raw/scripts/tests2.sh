#!/bin/bash
# tests2.sh (after the timed A/B): the untimed checks, two streams.
#  G: host tests of X4 (the N21 tests among them); the CUDA device suite of the candidates CM and CP; the dense
#     compares against the CPU join (b60 1e16 48 partitions, b62 1e17 32, b64 1e17 32) for X4 with switches U (32),
#     B (64), D (128) and all (239), and for the candidate binaries CM and CP (their own code, no switch).
#  L: lavapipe, every wgpu test of cubecl_join (--skip cuda), with CubeCL's SPIR-V compiler and with naga: X4 / X4n
#     with NICE_EXP_N21=239 (every switch), CM / CMn, CP / CPn.
W=/root/n21; B=$W/bin; L=$W/logs/t; mkdir -p $L; S=$W/scripts
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH:-} NICE_BUILD_SHA=test RUST_BACKTRACE=1
until grep -q AB_DONE $W/out/ab3.out; do sleep 20; done
echo TESTS2_START $(date -u +%T)
( mkdir -p $W/run/g && cd $W/run/g
  $B/X4 --test-threads 8 > $L/host_X4.log 2>&1; echo "host X4: $(grep 'test result' $L/host_X4.log | tr '\n' ' ')"
  for T in CM CP; do
    $B/$T --ignored cubecl_join::tests::cubecl_cuda --nocapture --test-threads 1 > $L/cuda_$T.log 2>&1
    echo "cuda $T: $(grep 'test result' $L/cuda_$T.log)"
  done
  bash $S/dense1.sh X4 128 239 32 64
  bash $S/dense1.sh CM 0
  bash $S/dense1.sh CP 0
  echo G_DONE $(date -u +%T)
) > $L/stream_G.out 2>&1 &
( export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/lvp_icd.json LP_NUM_THREADS=4
  mkdir -p $W/run/l && cd $W/run/l
  lvp() { # bin n21
    ( NICE_EXP_N21=$2 timeout 5400 nice -n 5 $B/$1 --ignored cubecl_join::tests:: --skip cuda --nocapture --test-threads 1 > $L/lvp_${1}_$2.log 2>&1
      echo "lavapipe $1 n21=$2: $(grep 'test result' $L/lvp_${1}_$2.log)" )
  }
  lvp X4 239 & lvp X4n 239 & lvp CM 0 & wait
  lvp CMn 0 & lvp CP 0 & lvp CPn 0 & wait
  echo L_DONE $(date -u +%T)
) > $L/stream_L.out 2>&1 &
wait
echo TESTS2_DONE $(date -u +%T) | tee $L/tests2.done
