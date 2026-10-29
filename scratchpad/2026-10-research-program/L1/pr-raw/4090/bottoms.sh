#!/bin/bash
# Bottoms before/after the prune (CPU test the_field_prune_drops_exactly_the_bottoms_that_meet_the_certificate) on the
# A/B fields (1e16, 2 per base) and the first two 1e14 fields at the same starts. prept = new main (2709d3f, with #203's
# closure) + prune; ept = 85b5b4e + prune (yesterday's certificate, without closure).
F=""
for bs in 58:104400216587923470200 60:1366406074057412100454 62:7997740455941656911841 64:41242006262957161709568; do
  b=${bs%%:*}; s=${bs#*:}
  F="$F,$b:$s:1e16,$b:$(python3 -c "print($s+10**16)"):1e16,$b:$s:1e14,$b:$(python3 -c "print($s+10**14)"):1e14"
done
for t in prept ept; do
  BIN=$(cat /root/ab/bin_$t); cd /root/$t
  echo "== $(date -u +%T) tree=$t $(git rev-parse --short HEAD)"
  NICE_TEST_PRUNE_FIELDS=${F#,} $BIN --exact cpu_join::tests::the_field_prune_drops_exactly_the_bottoms_that_meet_the_certificate --nocapture 2>&1 | grep -E "^b|test result|panicked"
done
echo "BOTTOMS_DONE $(date -u +%T)"
