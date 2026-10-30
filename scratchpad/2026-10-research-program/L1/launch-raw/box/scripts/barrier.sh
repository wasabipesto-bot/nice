#!/bin/bash
# The PR with the flush-decision barrier (fork rp/launch-with-barrier):
# build, then the CUDA parity tests, the dense-field tests and one 1e14
# A/B-shaped run, after the third 1e16 round.
source ~/.cargo/env
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH
until grep -q AB16R3_DONE /root/logs/ab16r3.out 2>/dev/null; do sleep 15; done
cd /root/nice && git fetch -q origin rp/launch-with-barrier && (git worktree add -q /root/prb FETCH_HEAD 2>/dev/null || git -C /root/prb checkout -q FETCH_HEAD)
cd /root/prb && echo "== $(date -u +%T) $(git log --oneline -1)"
CARGO_TARGET_DIR=/root/pr/target cargo test --release -p nice_common --features gpu --no-run > /root/logs/build_prb_test.log 2>&1; echo "test exit $?" >> /root/logs/build_prb_test.log
tail -n 1 /root/logs/build_prb_test.log
mkdir -p /root/bin/prb; TB=$(grep -o "Executable unittests src/lib.rs ([^)]*)" /root/logs/build_prb_test.log | tail -1 | sed "s/.*(//; s/)//"); cp $TB /root/bin/prb/nice_common_test; md5sum /root/bin/prb/nice_common_test | tee /root/bin/prb/md5.txt
BIN=/root/bin/prb/nice_common_test
echo "== $(date -u +%T) CUDA join vs the CPU reference"
$BIN --ignored --exact cubecl_join::tests::cubecl_cuda_join_matches_the_cpu_reference --test-threads 1 --nocapture 2>&1 | grep -E "test result|panicked|differ" | tail -5
for f in 58:102121216587923470200:1e15:64 64:41242006262957161709568:1e14:1024; do
  IFS=: read b s z n <<< "$f"
  echo "== $(date -u +%T) dense-field test b$b $s +$z, $n partitions"
  NICE_TEST_JOIN_DENSE=$n NICE_TEST_JOIN_DENSE_FIELD=$b:$s:$z $BIN --ignored --exact \
    cubecl_join::tests::cubecl_cuda_join_matches_the_cpu_join_on_a_dense_field --nocapture --test-threads 1 2>&1 | grep -E "^b|overran|panicked|test result|differ"
done
echo "== $(date -u +%T) 1e14, 10 GB budget, 20 fields per base"
/root/run.sh /root/bin/prb f14_B10_prb_r1 1e14 20 NICE_TEST_JOIN_MAX_BUFFER=2684354560
/root/summ.sh /root/logs/f14_B10_prb_r1.log
echo BARRIER_DONE $(date -u +%T)
