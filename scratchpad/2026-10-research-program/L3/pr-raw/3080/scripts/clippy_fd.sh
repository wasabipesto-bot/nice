#!/bin/bash
source /root/.cargo/env
cd /root/fd
{ date -u; cargo fmt --all --check && echo FMT_OK; cargo clippy --all-targets --features gpu -- -D warnings && echo CLIPPY_OK; date -u; echo CLIPPY_DONE; } > /root/logs/clippy_fd.log 2>&1
