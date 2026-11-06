#!/bin/bash
# chain_final.sh: the final head P4 (f516356: P with the walk's comment moved and two rustc warnings fixed): tree, test
# binary, host tests, rustfmt, registers; then its CUDA exactness (chain_x.sh) beside lavapipe (chain_lvp.sh, niced
# builds) and the lint (chain_lint.sh); then, the box quiet, a screen of P (the A/B's binary) against P4 and P3 (the
# clip words copied to plain shared memory): b62 1e17 and b60 1e16, 2 rounds, order P P4 P3 then P3 P4 P; then the
# exhaustive host test on P4 and a repeat of the level-0 walk counters (X3).
L=/root/l41/logs; R=/root/l41/run.sh
rm -f $L/use_P2
/root/l41/tree.sh P4 pr/join-lean-prefilter
J=10 /root/l41/build.sh P4 P4 > $L/build_P4.out 2>&1 || { cat $L/build_P4.out; exit 1; }
cat $L/build_P4.out; grep -c "^warning" $L/build_P4.log
cd /root/l41/src/P4
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu NICE_BUILD_SHA=test
( /root/l41/bin/P4 fx_ lean_ --nocapture; /root/l41/bin/P4 join_plan:: ; /root/l41/bin/P4 cubecl_join:: ) > $L/host_P4.log 2>&1
grep -h "test result\|FAILED\|panicked" $L/host_P4.log
( source ~/.cargo/env; cargo fmt --all --check; echo "fmt rc=$?" ) > $L/fmt_P4.log 2>&1; tail -1 $L/fmt_P4.log
/root/l41/regs.sh P4 P4 P4 > $L/regs_P4.out 2>&1; tail -12 $L/regs_P4.out
cd /root/l41
/root/l41/chain_x.sh P4 > $L/chain_x_P4.out 2>&1 &
XP=$!
/root/l41/chain_lvp.sh P4 > $L/chain_lvp_P4.out 2>&1
wait $XP
/root/l41/chain_lint.sh P4 > $L/chain_lint_P4.out 2>&1
echo QUIET_START $(date -u +%T)
for r in 1 2; do
  if [ $r = 2 ]; then O="P3 P4 P"; else O="P P4 P3"; fi
  for t in $O; do SRCD=$t $R s3_${t}_e17_b62_r$r $t 62 1 1e17; done
  for t in $O; do SRCD=$t $R s3_${t}_e16_b60_r$r $t 60 2 1e16; done
done
echo S3_DONE $(date -u +%T)
( cd /root/l41/src/P4 && /root/l41/bin/P4 fx_digits_are_exact_everywhere --ignored --nocapture ) > $L/host_exh_P4.log 2>&1
NICE_EXP_JOIN_ROUNDS=1 NICE_EXP_JOIN_PF=0 SRCD=X3 $R ctr_L0b_e17_b62 X3 62 1 1e17
NICE_EXP_JOIN_ROUNDS=1 NICE_EXP_JOIN_PF=0 SRCD=X3 $R ctr_L0b_e16_b60 X3 60 2 1e16
touch $L/final.done
