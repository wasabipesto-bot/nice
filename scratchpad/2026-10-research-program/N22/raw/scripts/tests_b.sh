#!/bin/bash
# tests_b.sh: after tests.sh, (1) re-run the CUDA test that failed on allocation (cubecl_cuda_top_fd_matches_the_top_kernel)
# alone with NICE_EXP_N22=0 and =26 (GPU otherwise idle); (2) X3 (switch 32, the fixed-trip AND): the CUDA suite
# with 58 (= 2+8+16+32), dense compares b62/b64 for 32 and 58, lavapipe 26.0.8 both compilers (X3, X3n) with 59.
W=/root/n22; B=$W/bin; L=$W/logs/t; S=$W/scripts
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH:-} NICE_BUILD_SHA=test RUST_BACKTRACE=1
F62=7520566762397899821056; F64=58557331862957161709568
until [ -e $L/tests.done ]; do sleep 10; done
echo TESTS_B_START $(date -u +%T)
cd $W/run/g
for m in 0 26; do
  NICE_EXP_N22=$m $B/X2 --ignored --exact cubecl_join::tests::cubecl_cuda_top_fd_matches_the_top_kernel --nocapture --test-threads 1 > $L/cuda_topfd_$m.log 2>&1
  echo "cuda top_fd test n22=$m: $(grep 'test result' $L/cuda_topfd_$m.log)"
done
( mkdir -p /srv/r26/root/bin; cp $B/X3 $B/X3n /srv/r26/root/bin/
  lvp() { chroot /srv/r26 /usr/bin/env -i PATH=/usr/bin:/bin HOME=/root NICE_BUILD_SHA=test NICE_EXP_N22=$2 LP_NUM_THREADS=4 \
      VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/lvp_icd.json timeout 5400 /root/bin/$1 --ignored cubecl_join::tests:: \
      --skip cuda --nocapture --test-threads 1 > $L/lvp_${1}_$2.log 2>&1
    echo "lavapipe 26.0.8 $1 n22=$2: $(grep 'test result' $L/lvp_${1}_$2.log)"; }
  lvp X3 59 & lvp X3n 59 & wait ) > $L/stream_L3.out 2>&1 &
NICE_EXP_N22=58 $B/X3 --ignored cubecl_join::tests::cubecl_cuda --nocapture --test-threads 1 > $L/cuda_X3_58.log 2>&1
echo "cuda X3 n22=58: $(grep 'test result' $L/cuda_X3_58.log)"
for m in 32 58; do
  bash $S/dense.sh x3_${m}_b62 X3 $m 62 $F62 1e17 32
  bash $S/dense.sh x3_${m}_b64 X3 $m 64 $F64 1e17 32
done
wait
cat $L/stream_L3.out
echo TESTS_B_DONE $(date -u +%T) | tee $L/tests_b.done
