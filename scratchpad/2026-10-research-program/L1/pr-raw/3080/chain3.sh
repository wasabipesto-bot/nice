#!/bin/bash
# Replaces chain2 after its PR rebuild: EPT branch first, then the profile, NiceMark, tests.
source ~/.cargo/env
eval "$(sed -n "/^build() {/,/^}/p" /root/setup.sh)"
cd /root/nice && git fetch -q origin pr/join-ept-2
[ -d /root/ept2 ] || git worktree add -q --detach /root/ept2 FETCH_HEAD
echo "== $(date -u +%T) ept2 $(git -C /root/ept2 log --oneline -1)"
( cd /root/ept2 && find common client -name "*.rs" -exec touch {} + && CARGO_TARGET_DIR=/root/tgt_a cargo clean -q --release -p nice_common -p nice_client && build ept2 a 10 ) &
until grep -q "\[pr\] built\|\[pr\].*FAILED" /root/ab/chain2.log; do sleep 5; done
echo "== $(date -u +%T) $(grep '^pr: md5' /root/ab/chain2.log || grep '\[pr\]' /root/ab/chain2.log)"
( cd /root/pr && echo "== $(date -u +%T) host tests on $(git log --oneline -1)" && /root/bins/pr/nice_common_test --test-threads 8 2>&1 | grep -E "^test result|FAILED|panicked|failures:" && \
  /root/bins/pr/nice_common_test --exact cpu_join::tests::the_field_prune_drops_exactly_the_bottoms_that_meet_the_certificate --nocapture 2>&1 | grep -E "^b|test result|panicked" ) > /root/ab/hosttests.log 2>&1
wait
for t in main pr ept2 xmain xpr; do echo "$t: md5=$(md5sum < /root/bins/$t/nice_common_test | cut -c1-8) $(git -C /root/$t rev-parse --short HEAD)"; done
echo "== $(date -u +%T) builds and host tests done"
/root/x14.sh > /root/ab/x14.log 2>&1
echo "== $(date -u +%T) x14 done"
PROF_TREES="xmain xpr" FLUSH=512 /root/prof.sh > /root/ab/prof.log 2>&1
echo "== $(date -u +%T) profile done"
/root/nicemark.sh > /root/ab/nm.log 2>&1
echo "== $(date -u +%T) nicemark done"
/root/tests2.sh > /root/ab/tests2.log 2>&1
echo "== $(date -u +%T) tests2 done"
/root/e16.sh > /root/ab/e16.log 2>&1
echo CHAIN3_DONE $(date -u +%T)
