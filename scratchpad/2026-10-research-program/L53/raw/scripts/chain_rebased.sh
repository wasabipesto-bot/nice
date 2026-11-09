#!/bin/bash
# chain_rebased.sh: the two held branches rebased onto the new #249 head (trees R2 = pr/top-fd-round2, CD = pr/check-d):
# build each (gpu), then host unit tests (join_plan::, cubecl_join::), the 1e14 compare at b57/60/62/64, CPU-reference
# parity, and on CD check-d's own device test (whose JoinDevice::new call took the layer argument in the rebase);
# then fmt and clippy -D warnings on nice_common (default; --features gpu) for each. Builds after the lavapipe builds
# (lvp_C.built; 7.7 GB of RAM), device tests after x_C.done.
L=/root/l53/logs; T=/root/l53/test.sh; R=/root/l53/run.sh
until [ -e $L/lvp_C.built ]; do sleep 15; done
echo RB_START $(date -u +%T)
for t in R2 CD; do NICEN=10 J=6 bash /root/l53/build.sh $t $t | tail -2; done
until [ -e $L/x_C.done ]; do sleep 15; done
for t in R2 CD; do
  export SRCD=$t
  ( cd /root/l53/src/$t && LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu NICE_BUILD_SHA=test /root/l53/bin/$t join_plan:: ; \
    LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu NICE_BUILD_SHA=test /root/l53/bin/$t cubecl_join:: ) > $L/rb_${t}_unit.log 2>&1
  NICE_TEST_JOIN_COMPARE=1 $R rb_${t}_cmp $t 57,60,62,64 1 1e14
  $T rb_${t}_ref $t cubecl_join::tests::cubecl_cuda_join_matches_the_cpu_reference X=1
  [ $t = CD ] && $T rb_${t}_checkcounts $t cubecl_join::tests::cubecl_cuda_check_counts_match_the_cpu X=1
  echo "$t: unit $(grep -h 'test result' $L/rb_${t}_unit.log | tr '\n' ' ')"
  echo "$t: cmp $(grep -o 'base=[0-9]* fields=1 in_flight.*found=[0-9]*' $L/rb_${t}_cmp.log | sed 's/secs.*survivors/survivors/' | tr '\n' ';') $(grep -h 'test result' $L/rb_${t}_cmp.log)"
  for f in ref checkcounts; do [ -e $L/rb_${t}_$f.log ] && echo "$t: $f $(grep -h 'test result' $L/rb_${t}_$f.log) $(grep -h '^END' $L/rb_${t}_$f.log)"; done
done
source ~/.cargo/env
for t in R2 CD; do
  cd /root/l53/src/$t
  export CARGO_TARGET_DIR=/root/tgt_clippy NICE_BUILD_SHA=test
  ( cargo fmt --all --check; echo "fmt rc=$?" ) > $L/rb_${t}_fmt.log 2>&1
  ( nice -n 15 cargo clippy -j 6 -p nice_common --all-targets -- -D warnings; echo "clippy default rc=$?" ) > $L/rb_${t}_clippy_default.log 2>&1
  ( nice -n 15 cargo clippy -j 6 -p nice_common --all-targets --features gpu -- -D warnings; echo "clippy gpu rc=$?" ) > $L/rb_${t}_clippy_gpu.log 2>&1
  echo "$t: $(tail -n1 $L/rb_${t}_fmt.log) $(tail -n1 $L/rb_${t}_clippy_default.log) $(tail -n1 $L/rb_${t}_clippy_gpu.log)"
done
echo RB_DONE $(date -u +%T) | tee $L/rb.done
