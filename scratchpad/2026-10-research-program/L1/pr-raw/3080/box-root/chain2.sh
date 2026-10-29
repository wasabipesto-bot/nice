#!/bin/bash
# After the A/B: rebuild the PR tree at its final head (and lint it), then profile, NiceMark,
# the exactness tests and the exact-counter run on main (run under nohup).
source ~/.cargo/env
until grep -q AB_DONE /root/ab/ab.log; do sleep 10; done
cd /root/pr && git fetch -q origin pr/field-cert-prune && git checkout -q --detach FETCH_HEAD
echo "== $(date -u +%T) pr now $(git log --oneline -1)"
eval "$(sed -n "/^build() {/,/^}/p" /root/setup.sh)"
find common client -name "*.rs" -exec touch {} +
CARGO_TARGET_DIR=/root/tgt_b cargo clean -q --release -p nice_common -p nice_client
(build pr b 12; echo "pr: md5=$(md5sum < /root/bins/pr/nice_common_test | cut -c1-8) prune-log=$(grep -c 'bottom prefixes' /root/bins/pr/nice_common_test) exp-knob=$(grep -c NICE_EXP_SURV_FLUSH /root/bins/pr/nice_common_test)") &
J=8 /root/lint.sh > /root/ab/lint_final.log 2>&1 &
wait
echo "== $(date -u +%T) rebuilt; lint: $(grep -E 'OK|EXIT' /root/ab/lint_final.log | tr '\n' ' ')"
PROF_TREES="xmain xpr" FLUSH=512 /root/prof.sh > /root/ab/prof.log 2>&1
echo "== $(date -u +%T) profile done"
FLUSH=512 /root/nicemark.sh > /root/ab/nm.log 2>&1
echo "== $(date -u +%T) nicemark done"
/root/tests.sh > /root/ab/tests.log 2>&1
echo "== $(date -u +%T) tests done"
NOWAIT=1 /root/exact256.sh > /root/ab/exact256.log 2>&1
echo CHAIN2_DONE $(date -u +%T)
