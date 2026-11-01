#!/bin/bash
# Final verification of the fix tree (/root/src/fix) on the box.
. /root/.cargo/env
export NICE_BUILD_SHA=test RUST_BACKTRACE=1
cd /root/src/fix
L=/root/logs/v; mkdir -p $L
md5sum common/src/cubecl_join.rs > $L/src_md5.txt
B=target/release/deps/nice_common
for F in cubecl-spirv:spirv cubecl:naga gpu:gpu; do
  feat=${F%%:*}; tag=${F##*:}
  { date -u; cargo test --release --features $feat -p nice_common --no-run 2>&1 | grep -v "^ *Compiling\|^ *Downloaded" | tail -8; date -u; } > $L/build_$tag.log 2>&1
done
cp ${B}-6773f06445c05522 /root/binf_spirv; cp ${B}-59758d2e435b71e1 /root/binf_naga; cp ${B}-cbd4e892b0124d04 /root/binf_gpu
md5sum /root/binf_* > $L/md5_bins.txt
touch $L/builds.done
export LVP=$(ls /usr/share/vulkan/icd.d/lvp_icd*.json | head -n1)
# (A) the CI step "Run device parity tests (CubeCL direct SPIR-V compiler)"
( VK_ICD_FILENAMES=$LVP /root/binf_spirv --ignored --nocapture cubecl_ > $L/ci_spirv.log 2>&1; echo "exit $?" >> $L/ci_spirv.log; touch $L/A.done ) &
# (B) the CI steps "Run device parity tests" (naga) and the WGSL lint, then the cert kernel's WGSL
(
  export VK_ICD_FILENAMES=$LVP
  cargo test --release --features cubecl -p nice_common -- --ignored --nocapture > $L/ci_naga.log 2>&1; echo "exit $?" >> $L/ci_naga.log
  rm -f $L/wgsl.log
  CUBECL_DEBUG_LOG=$L/wgsl.log cargo test --release --features cubecl -p nice_common --lib -- --ignored --exact cubecl_backend::tests::wgsl_dump_for_lint --nocapture > $L/lint_dump.log 2>&1; echo "exit $?" >> $L/lint_dump.log
  python3 scripts/wgsl-lint.py $L/wgsl.log \
      --require DetailedKernelU32@80 --require DetailedFdKernelU32@40 \
      --require DetailedFdKernelU32@50 \
      --require DetailedFdKernel@23 --require DetailedFdKernel@40 \
      --require DetailedFdKernel@50 --require DetailedFdKernel@62 \
      --require DetailedKernel@80 --require NiceonlyKernel@40 \
      --require BucketKernel@57 --require JoinKernel@57 \
      --require TopKernel@57 --require CheckKernel@57 > $L/lint.log 2>&1; echo "exit $?" >> $L/lint.log
  rm -f $L/wgsl_cert.log
  CUBECL_DEBUG_LOG=$L/wgsl_cert.log NICE_TEST_CERT_SAMPLES=2000 /root/binf_naga --ignored --exact cubecl_join::tests::top_certificates_match_the_lockstep_scan_and_the_cpu --nocapture > $L/cert_naga_dump.log 2>&1; echo "exit $?" >> $L/cert_naga_dump.log
  python3 scripts/wgsl-lint.py $L/wgsl_cert.log > $L/lint_cert.log 2>&1; echo "exit $?" >> $L/lint_cert.log
  gzip -f $L/wgsl.log $L/wgsl_cert.log
  touch $L/B.done
) &
# (C) CUDA: join parity and the certificate test
(
  /root/binf_gpu --ignored --exact cubecl_join::tests::cubecl_cuda_join_matches_the_cpu_reference --nocapture > $L/cuda_parity.log 2>&1; echo "exit $?" >> $L/cuda_parity.log
  /root/binf_gpu --ignored --exact cubecl_join::tests::cubecl_cuda_top_certificates_match_the_lockstep_scan_and_the_cpu --nocapture > $L/cuda_cert.log 2>&1; echo "exit $?" >> $L/cuda_cert.log
  touch $L/C.done
) &
# (D) fmt and clippy in their own target dir
(
  rustup component add clippy rustfmt > $L/rustup_comp.log 2>&1
  cargo fmt --all --check > $L/fmt.log 2>&1; echo "exit $?" >> $L/fmt.log
  export CARGO_TARGET_DIR=/root/clippy-target
  nice -n 10 cargo clippy -p "*" --all-targets -- -D warnings > $L/clippy_default.log 2>&1; echo "exit $?" >> $L/clippy_default.log
  nice -n 10 cargo clippy -p "*" --all-targets --features nice_client/gpu -- -D warnings > $L/clippy_gpu.log 2>&1; echo "exit $?" >> $L/clippy_gpu.log
  nice -n 10 cargo clippy -p "*" --all-targets --features nice_client/gpu,nice_client/cubecl-spirv -- -D warnings > $L/clippy_spirv.log 2>&1; echo "exit $?" >> $L/clippy_spirv.log
  touch $L/D.done
) &
wait
touch $L/all.done
