#!/bin/bash
# Exactness, tree $1 (main or pr): host tests, CUDA parity tests, dense-field
# tests at b58 (1e15) and b64 (1e16), and the throughput harness with
# NICE_TEST_JOIN_COMPARE=1 (every 1e14 field also through the stride pipeline).
source ~/.cargo/env
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH
t=$1
if [ "$t" = pr ]; then
  # The PR's final head (the A/B binary plus test-only and doc commits).
  cd /root/pr && git fetch -q origin pr/join-partitions-per-launch && git checkout -q FETCH_HEAD
  echo "== $(date -u +%T) building the final head $(git log --oneline -1)"
  /root/build.sh pr
  tail -n 1 /root/logs/build_pr_test.log /root/logs/build_pr_client.log
  /root/stage.sh pr prfinal
  BINDIR=/root/bin/prfinal
  # Lint beside the GPU tests (CPU only).
  (cd /root/pr && cargo fmt --all --check > /root/logs/lint_fmt.log 2>&1; echo "fmt exit $?" >> /root/logs/lint_fmt.log;
   export CARGO_TARGET_DIR=/root/tgt_clippy;
   cargo clippy -j 6 -p nice_common -p nice_client --all-targets --features nice_client/gpu -- -D warnings > /root/logs/lint_clippy_gpu.log 2>&1; echo "clippy gpu exit $?" >> /root/logs/lint_clippy_gpu.log;
   cargo clippy -j 6 -p nice_common -p nice_client --all-targets -- -D warnings > /root/logs/lint_clippy_default.log 2>&1; echo "clippy default exit $?" >> /root/logs/lint_clippy_default.log) &
else
  BINDIR=/root/bin/$t
fi
STARTS=58:104400216587923470200,60:1366406074057412100454,62:7997740455941656911841,64:41242006262957161709568
BIN=$BINDIR/nice_common_test
cd /root/$t
echo "== $(date -u +%T) $t $(git log --oneline -1)"
echo "== $(date -u +%T) non-ignored nice_common tests"
$BIN --test-threads 12 2>&1 | grep -E "^test result|FAILED|panicked|failures:"
echo "== $(date -u +%T) join_plan tests, verbose"
$BIN join_plan --nocapture --test-threads 1 2>&1 | grep -E "^b[0-9]|test result|panicked"
echo "== $(date -u +%T) CUDA join vs the CPU reference (windows, tight layouts, slices, refusals, production shape)"
$BIN --ignored --exact cubecl_join::tests::cubecl_cuda_join_matches_the_cpu_reference --test-threads 1 --nocapture 2>&1 | grep -E "test result|panicked|differ|agree" | tail -12
echo "== $(date -u +%T) CUDA whole b42 field vs reference"
NICE_TEST_JOIN_FULL_FIELD=1 $BIN --ignored --exact cubecl_join::tests::cubecl_cuda_join_matches_the_reference_on_a_whole_field --test-threads 1 --nocapture 2>&1 | grep -E "test result|panicked|differ" | tail -5
for f in 58:102121216587923470200:1e15:64 64:41242006262957161709568:1e16:8 64:41242006262957161709568:1e14:1024; do
  IFS=: read b s z n <<< "$f"
  echo "== $(date -u +%T) dense-field test b$b $s +$z, $n partitions"
  NICE_TEST_JOIN_DENSE=$n NICE_TEST_JOIN_DENSE_FIELD=$b:$s:$z $BIN --ignored --exact \
    cubecl_join::tests::cubecl_cuda_join_matches_the_cpu_join_on_a_dense_field --nocapture --test-threads 1 2>&1 | grep -E "^b|overran|panicked|test result|differ"
done
echo "== $(date -u +%T) throughput harness with NICE_TEST_JOIN_COMPARE=1 (5 fields of 1e14 per base, A/B starts, budget B10)"
NICE_TEST_JOIN_MAX_BUFFER=2684354560 NICE_TEST_JOIN_COMPARE=1 NICE_TEST_JOIN_FIELDS=5 NICE_TEST_JOIN_BASES=58,60,62,64 NICE_TEST_JOIN_STARTS=$STARTS \
  $BIN --ignored --exact cubecl_join::tests::cubecl_cuda_join_throughput_fixed_fields --nocapture --test-threads 1 2>&1 | grep -E "JOIN THROUGHPUT|STRIDE|test result|panicked|differs"
wait
echo EXACT_${t}_DONE $(date -u +%T)
