#!/bin/bash
# Extra: production-size A/B on new main: 1e14 fields, 20 consecutive per base from the A/B starts (a 1e14 warm-up
# first), variants main, prune (26a8b15), prept:2 (prune + EPT 2), 3 interleaved rounds.
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH
STARTS=58:104400216587923470200,60:1366406074057412100454,62:7997740455941656911841,64:41242006262957161709568
VARIANTS=${VARIANTS:-"main prune prept:2"}
for r in 1 2 3; do
  for v in $VARIANTS; do
    t=${v%%:*}; e=""; [ "$t" != "$v" ] && e=${v#*:}
    BIN=$(cat /root/ab/bin_$t); cd /root/$t
    name=$t${e:+_e$e}
    echo "== $(date -u +%T) round=$r tree=$t ept=${e:-default} commit=$(git rev-parse --short HEAD)"
    env ${e:+NICE_EXP_JOIN_EPT=$e} NICE_TEST_JOIN_FIELDS=20 NICE_TEST_JOIN_SIZE=1e14 NICE_TEST_JOIN_BASES=58,60,62,64 NICE_TEST_JOIN_STARTS=$STARTS \
      $BIN --ignored --exact cubecl_join::tests::cubecl_cuda_join_throughput_fixed_fields --nocapture --test-threads 1 > /root/ab/x14_r${r}_$name.log 2>&1
    grep -E "JOIN THROUGHPUT|panicked|test result" /root/ab/x14_r${r}_$name.log
  done
done
echo "X14_DONE $(date -u +%T)"
