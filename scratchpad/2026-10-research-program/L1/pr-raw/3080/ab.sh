#!/bin/bash
# Fixed-field throughput A/B/C, interleaved A B C x 3 (run under nohup).
#   A = /root/main (upstream main 2709d3f + the PR's test-only harness commit)
#   B = /root/pr   (the PR branch)
#   C = /root/xpr  (the PR + exp knobs) with NICE_EXP_JOIN_EPT=2 and the PR's flush level
# Two fields of 1e16 per base (two in flight), after a 1e14 warm-up per base.
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH
FLUSH=${FLUSH:?set FLUSH to the flush level of the PR}
STARTS=58:104400216587923470200,60:1366406074057412100454,62:7997740455941656911841,64:41242006262957161709568
for r in 1 2 3; do
  for t in main pr ept2; do
    case $t in
      main) dir=main; envs="";;
      pr)   dir=pr;   envs="";;
      ept2) dir=xpr;  envs="NICE_EXP_JOIN_EPT=2 NICE_EXP_SURV_FLUSH=$FLUSH";;
    esac
    cd /root/$dir
    echo "== $(date -u +%T) round=$r tree=$t dir=$dir commit=$(git rev-parse --short HEAD) $envs"
    env $envs NICE_TEST_JOIN_FIELDS=2 NICE_TEST_JOIN_SIZE=1e16 NICE_TEST_JOIN_BASES=58,60,62,64 NICE_TEST_JOIN_STARTS=$STARTS \
      /root/bins/$dir/nice_common_test --ignored --exact cubecl_join::tests::cubecl_cuda_join_throughput_fixed_fields \
      --nocapture --test-threads 1 > /root/ab/thr_r${r}_$t.log 2>&1
    grep -E "panicked|test result" /root/ab/thr_r${r}_$t.log
    grep -oE "base=[0-9]+ fields|per_field=[0-9.]+|device=[0-9.]+s|slices?=[0-9]+|batches=[0-9]+ slots=[0-9]+|survivors=[0-9]+ checked=[0-9]+" /root/ab/thr_r${r}_$t.log | paste -d' ' - - - - - | sed 's/^/   /'
  done
done
echo AB_DONE $(date -u +%T)
