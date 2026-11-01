#!/bin/bash
# trim.sh: EXPERIMENT (not in the PR): the PR plus a comptime bound on the
# long division (divide only the limbs x / B^pass can still have). Build,
# certificate test on CUDA, then pr vs trim at 1e16 (2 rounds, interleaved).
while ! grep -q FINAL_DONE /root/logs/final.log; do sleep 10; done
source /root/.cargo/env
cd /root/src/pr
cp common/src/cubecl_join.rs /root/pr_cubecl_join.rs.bak
cp /root/trim_cubecl_join.rs common/src/cubecl_join.rs
echo "== $(date -u +%T) build trim"
cargo test --release -p nice_common --features gpu --no-run --message-format=json 2>/root/logs/build_trim.err > /root/logs/build_trim.json
BIN=$(grep -o "\"executable\":\"[^\"]*nice_common-[^\"]*\"" /root/logs/build_trim.json | tail -1 | cut -d\" -f4)
mkdir -p /root/bin/trim && cp "$BIN" /root/bin/trim/nice_common_test
cp /root/pr_cubecl_join.rs.bak common/src/cubecl_join.rs
md5sum /root/bin/trim/nice_common_test
echo "== $(date -u +%T) built trim"
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH
echo "== $(date -u +%T) cert cuda (trim)"
/root/bin/trim/nice_common_test --ignored --exact cubecl_join::tests::cubecl_cuda_top_certificates_match_the_lockstep_scan_and_the_cpu --nocapture --test-threads 1 > /root/logs/x_trim_cert_cuda.log 2>&1
echo "exit $? $(date -u +%T)"
cd /root
for r in 1 2; do
  for t in pr trim; do
    echo "== $(date -u +%T) t16 round=$r tree=$t"
    ./run.sh $t t16_${t}_r$r 1e16 2 62,60,64
    echo "done $(date -u +%T) $(grep -o "per_field=[0-9.]*" logs/t16_${t}_r$r.log | tr "\n" " ")"
  done
done
echo TRIM_DONE $(date -u +%T)
