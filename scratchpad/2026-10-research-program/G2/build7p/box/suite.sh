#!/bin/bash
# box: suite.sh DIR OUT — CI's test commands (rust-build-test.yml) on /root/DIR, target dir /root/t/DIR,
# then the midout tests alone in release and in debug (`just test` / plain `cargo test` form), timed
source ~/.cargo/env; cd /root/$1; export CARGO_TARGET_DIR=/root/t/$1; O=/root/runs7p/$2; mkdir -p $O; rm -f $O/done $O/rc.txt
. /root/guard7p.sh $O
git log --oneline -1 > $O/head.txt; git status --short >> $O/head.txt
cargo test --locked --release --no-fail-fast > $O/workspace.txt 2>&1; echo "workspace rc=$?" >> $O/rc.txt
cargo test --locked --release -p nice_common --features gpu --lib > $O/common_gpu.txt 2>&1; echo "common gpu lib rc=$?" >> $O/rc.txt
( time cargo test --locked --release -p nice_common --lib midout -- --test-threads 4 ) > $O/midout_release.txt 2>&1; echo "midout release rc=$?" >> $O/rc.txt
( time cargo test --locked -p nice_common --lib midout -- --test-threads 4 ) > $O/midout_debug_build.txt 2>&1
( time cargo test --locked -p nice_common --lib midout -- --test-threads 4 ) > $O/midout_debug.txt 2>&1; echo "midout debug rc=$?" >> $O/rc.txt
echo done > $O/done
