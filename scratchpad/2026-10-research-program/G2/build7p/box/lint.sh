#!/bin/bash
# box: lint.sh DIR OUT — `just lint`'s three commands on /root/DIR, target dir /root/t/DIR
# (the box's apt `just` cannot parse the justfile, so the recipe's commands are run as written there)
source ~/.cargo/env; cd /root/$1; export CARGO_TARGET_DIR=/root/t/$1; O=/root/runs7p/$2; mkdir -p $O; rm -f $O/done $O/rc.txt
git log --oneline -1 > $O/head.txt; git status --short >> $O/head.txt
cargo fmt --all --check > $O/fmt.txt 2>&1; echo "fmt rc=$?" >> $O/rc.txt
cargo clippy -p "*" --all-targets -- -D warnings > $O/clippy1.txt 2>&1; echo "clippy default rc=$?" >> $O/rc.txt
cargo clippy -p "*" --all-targets --features nice_client/gpu,nice_client/cubecl-spirv -- -D warnings > $O/clippy2.txt 2>&1; echo "clippy gpu,cubecl-spirv rc=$?" >> $O/rc.txt
echo done > $O/done
