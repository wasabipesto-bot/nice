#!/bin/bash
# tests.sh: every untimed check, in parallel streams (no timed run is in progress while this runs).
#  G: CUDA (RTX 3080): S and F's host tests, every CUDA device test of cubecl_join, the dense compares vs the CPU join
#  L: lavapipe: every wgpu test of cubecl_join, naga and CubeCL's SPIR-V compiler, for S and F (and M with naga, for
#     the WGSL comparison); the WGSL is logged
#  C: fmt + clippy -p nice_common --all-targets --features gpu,cubecl-spirv -D warnings, S and F (own target dirs)
#  X: throwaway builds of S with a pairs-past-the-stage counter (stage 16/flush 8, and the PR's 512/256), then dense runs
#  D: CUDA source of the kernels at b58/b60/b62/b64 (1e14 fields) for M and F, via CUBECL_DEBUG_LOG
W=/root/prp; B=$W/bin; L=$W/logs/t; mkdir -p $L; S=$W/scripts
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH:-} NICE_BUILD_SHA=test RUST_BACKTRACE=1
F60=1447429612114824200908; F62=7520566762397899821056; F64=58557331862957161709568; F64B=39667831862957161709568
dense() { # name bin base start size parts
  mkdir -p $W/run/$1; cd $W/run/$1
  echo "START $1 $(date -u +%T) bin=$2 md5=$(md5sum $B/$2 | cut -c1-8) $3:$4:$5 parts=$6" > $L/$1.log
  NICE_TEST_JOIN_DENSE=$6 NICE_TEST_JOIN_DENSE_FIELD=$3:$4:$5 $B/$2 --ignored --exact \
    cubecl_join::tests::cubecl_cuda_join_matches_the_cpu_join_on_a_dense_field --nocapture --test-threads 1 >> $L/$1.log 2>&1
  echo "END $1 $(date -u +%T) rc=$?" >> $L/$1.log
  echo "$1: $(grep -o 'survivors [0-9]* checked [0-9]*' $L/$1.log) $(grep -o 'PAST_FULL_STAGE.*' $L/$1.log) $(grep -o 'test result: [a-z]*' $L/$1.log)"
}
echo TESTS_START $(date -u +%T)
( mkdir -p $W/run/g && cd $W/run/g
  for T in S F; do
    $B/$T --test-threads 16 > $L/host_$T.log 2>&1; echo "host $T: $(grep 'test result' $L/host_$T.log | tr '\n' ' ')"
    $B/$T --ignored cubecl_join::tests::cubecl_cuda --nocapture --test-threads 1 > $L/cuda_$T.log 2>&1
    echo "cuda $T: $(grep -c '^test .* ok$' $L/cuda_$T.log) ok lines; $(grep 'test result' $L/cuda_$T.log)"
  done
  dense x_S_b60_e16 S 60 $F60 1e16 48
  dense x_S_b62_e17 S 62 $F62 1e17 32
  dense x_F_b64_e16 F 64 $F64B 1e16 48
  dense x_F_b64_e17 F 64 $F64 1e17 32
  echo G_DONE $(date -u +%T)
) > $L/stream_G.out 2>&1 &
( export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/lvp_icd.json
  mkdir -p $W/run/l && cd $W/run/l
  for X in S_naga S F_naga F M_naga; do
    ( CUBECL_DEBUG_LOG=$L/shader_$X.log timeout 5400 $B/$X --ignored cubecl_join::tests:: --skip cuda --nocapture --test-threads 1 > $L/lvp_$X.log 2>&1
      echo "lavapipe $X: $(grep 'test result' $L/lvp_$X.log)" ) &
  done
  wait; echo L_DONE $(date -u +%T)
) > $L/stream_L.out 2>&1 &
( . /root/.cargo/env
  for T in S F; do
    cd $W/wt/$T; export CARGO_TARGET_DIR=$W/target-clippy-$T
    cargo fmt --all --check > $L/fmt_$T.log 2>&1; echo "fmt $T rc=$?"
    nice -n 10 cargo clippy -j 8 -p nice_common --all-targets --features gpu,cubecl-spirv -- -D warnings > $L/clippy_$T.log 2>&1; echo "clippy $T rc=$?"
  done; echo C_DONE $(date -u +%T)
) > $L/stream_C.out 2>&1 &
( . /root/.cargo/env; cd /root/nice
  for c in "16 8" "512 256"; do
    set -- $c; T=T$1
    [ -d $W/wt/$T ] || git worktree add -q --detach $W/wt/$T b/pr/join-survivor-stage-512
    python3 $S/patch_cnt.py $W/wt/$T $1 $2
    JOBS=8 bash $S/build.sh $T $T test gpu,cubecl-spirv
    strings $B/$T | grep -c PAST_FULL_STAGE
  done
  dense xc_T16_b60_e16 T16 60 $F60 1e16 48
  dense xc_T16_b62_e17 T16 62 $F62 1e17 32
  dense xc_T512_b60_e16 T512 60 $F60 1e16 48
  dense xc_T512_b62_e17 T512 62 $F62 1e17 32
  dense xc_T512_b64_e17 T512 64 $F64 1e17 32
  echo X_DONE $(date -u +%T)
) > $L/stream_X.out 2>&1 &
( mkdir -p $W/run/d && cd $W/run/d
  for T in M F; do
    rm -f $L/cuda_src_$T.log
    CUBECL_DEBUG_LOG=$L/cuda_src_$T.log NICE_TEST_JOIN_FIELDS=1 NICE_TEST_JOIN_SIZE=1e14 NICE_TEST_JOIN_BASES=58,60,62,64 \
      $B/$T --ignored --exact cubecl_join::tests::cubecl_cuda_join_throughput_fixed_fields --nocapture --test-threads 1 > $L/srcdump_$T.out 2>&1
    echo "srcdump $T rc=$? $(grep -o 'base=[0-9]* .*survivors=[0-9]* checked=[0-9]*' $L/srcdump_$T.out | sed 's/fields=.*survivors/survivors/' | tr '\n' ';')"
  done; echo D_DONE $(date -u +%T)
) > $L/stream_D.out 2>&1 &
wait
echo TESTS_DONE $(date -u +%T) | tee $L/tests.done
