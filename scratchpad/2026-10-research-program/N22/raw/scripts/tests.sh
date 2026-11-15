#!/bin/bash
# tests.sh: N22's untimed exactness checks, two streams (nothing timed runs meanwhile).
#  G (CUDA, RTX 3080): the CUDA device suite of cubecl_join with NICE_EXP_N22=26 (walk loop + b64 bit field + check in
#    24-bit multiplies) and the dense compares against the CPU join (b62 1e17 32 partitions, b64 1e17 32) for modes 0,
#    26, 2 and 16.
#  L (lavapipe of Mesa 26.0.8, the Ubuntu 26.04 chroot as CI runs it): every wgpu test of cubecl_join (--skip cuda)
#    with CubeCL's SPIR-V compiler (X2) and with naga (X2n), NICE_EXP_N22=27 (every switch, scan-form appends).
W=/root/n22; B=$W/bin; L=$W/logs/t; mkdir -p $L; S=$W/scripts
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH:-} NICE_BUILD_SHA=test RUST_BACKTRACE=1
F62=7520566762397899821056; F64=58557331862957161709568
echo TESTS_START $(date -u +%T)
( mkdir -p $W/run/g && cd $W/run/g
  NICE_EXP_N22=26 $B/X2 --ignored cubecl_join::tests::cubecl_cuda --nocapture --test-threads 1 > $L/cuda_X2_26.log 2>&1
  echo "cuda X2 n22=26: $(grep 'test result' $L/cuda_X2_26.log)"
  for m in 26 0 2 16; do
    bash $S/dense.sh x_${m}_b62 X2 $m 62 $F62 1e17 32
    bash $S/dense.sh x_${m}_b64 X2 $m 64 $F64 1e17 32
  done
  echo G_DONE $(date -u +%T)
) > $L/stream_G.out 2>&1 &
( mkdir -p /srv/r26/root/bin; cp $B/X2 $B/X2n /srv/r26/root/bin/
  lvp() { # bin n22
    chroot /srv/r26 /usr/bin/env -i PATH=/usr/bin:/bin HOME=/root NICE_BUILD_SHA=test NICE_EXP_N22=$2 LP_NUM_THREADS=4 \
      VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/lvp_icd.json timeout 5400 /root/bin/$1 --ignored cubecl_join::tests:: \
      --skip cuda --nocapture --test-threads 1 > $L/lvp_${1}_$2.log 2>&1
    echo "lavapipe 26.0.8 $1 n22=$2: $(grep 'test result' $L/lvp_${1}_$2.log)"
  }
  lvp X2 27 & lvp X2n 27 & wait
  echo L_DONE $(date -u +%T)
) > $L/stream_L.out 2>&1 &
wait
echo TESTS_DONE $(date -u +%T) | tee $L/tests.done
