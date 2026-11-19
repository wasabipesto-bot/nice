#!/bin/bash
# fmt, clippy (the touched crates, default and GPU feature sets, and the test switch), and the suites; $1 = log dir
source ~/.cargo/env; cd /root/mc; export CARGO_TARGET_DIR=/root/t/mc; L=$1; mkdir -p $L
git log --oneline -1 > $L/head.txt; git status --short >> $L/head.txt
cargo fmt --all --check > $L/fmt.log 2>&1; echo rc=$? >> $L/fmt.log
cargo clippy -p nice_common -p nice_client --all-targets -- -D warnings > $L/clippy_default.log 2>&1; echo rc=$? >> $L/clippy_default.log
cargo clippy -p nice_common -p nice_client --all-targets --features nice_client/gpu,nice_client/cubecl-spirv -- -D warnings > $L/clippy_gpu.log 2>&1; echo rc=$? >> $L/clippy_gpu.log
cargo clippy -p nice_common -p nice_client --all-targets --features nice_client/cubecl-cuda,nice_client/midout-fault -- -D warnings > $L/clippy_fault.log 2>&1; echo rc=$? >> $L/clippy_fault.log
cargo test --release -p nice_common --lib > $L/suite_common.log 2>&1; echo rc=$? >> $L/suite_common.log
cargo test --release -p nice_common --features rustls-tls --lib -- midout::wire client_api_async > $L/t_common_tls.log 2>&1; echo rc=$? >> $L/t_common_tls.log
cargo test --release -p nice_client --features cubecl-cuda > $L/suite_client.log 2>&1; echo rc=$? >> $L/suite_client.log
cargo test --release -p nice_client > $L/suite_client_default.log 2>&1; echo rc=$? >> $L/suite_client_default.log
echo done > $L/done
