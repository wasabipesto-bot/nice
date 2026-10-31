#!/bin/bash
# host2.sh: the parallel-only failure of host.log, rerun: alone x3, then the
# full suite twice on the committed tree's binary and once on main's.
cd /root/nice/common
T=/root/nice/target/release/deps/nice_common-c0034331d0049e16
cp $T /root/bin/fixclean-test
F=gpu_niceonly::tests::threaded_pipeline_matches_the_one_field_form_field_by_field
{ echo "fixclean sha $(sha256sum /root/bin/fixclean-test | cut -c1-16) labels: $(grep -c L26TREE /root/bin/fixclean-test)"
  for i in 1 2 3; do echo "== alone $i"; /root/bin/fixclean-test $F --exact 2>&1 | grep -E "^test |test result"; done
  for i in 1 2; do echo "== full suite fix $i"; s=$(date +%s)
    /root/bin/fixclean-test --test-threads 8 2>&1 | grep -E "^test result|FAILED|panicked"; echo "secs=$(( $(date +%s) - s ))"; done
  echo "== full suite main"; s=$(date +%s)
  /root/bin/main-test --test-threads 8 2>&1 | grep -E "^test result|FAILED|panicked"; echo "secs=$(( $(date +%s) - s ))"
  date -u; } > /root/logs/host2.log 2>&1
echo "HOST2_DONE $(date -u +%T)" >> /root/logs/tests.status
