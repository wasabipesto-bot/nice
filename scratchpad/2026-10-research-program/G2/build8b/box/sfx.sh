#!/bin/bash
# box: sfx.sh — the fix branch's checks in /root/sfx (target /root/t/sfx): the new test with the guard removed (must
# fail) and with it (must pass); `just lint`; production's CI suite (workspace `cargo test --locked --release
# --no-fail-fast`, nice_common `--features gpu --lib`); then the fixed client (release, --features gpu) to
# /root/bin/sfx for g2claim.sh. Output /root/runs/sfx.
source ~/.cargo/env; cd /root/sfx; export CARGO_TARGET_DIR=/root/t/sfx; O=/root/runs/sfx; mkdir -p $O; rm -f $O/done $O/rc.txt
git log --oneline -1 > $O/head.txt; git diff --stat >> $O/head.txt
t() { n=$1; shift; s0=$(date +%s); "$@" > $O/$n.txt 2>&1; echo "$n rc=$? $(( $(date +%s) - s0 )) s" >> $O/rc.txt; }
cp common/src/stride_filter.rs /root/sf_fixed.rs
python3 - <<'PY'
p='/root/sfx/common/src/stride_filter.rs'; s=open(p).read()
g='''        if self.valid_residues.is_empty() {
            return Vec::new();
        }
'''
assert s.count(g)==1; open(p,'w').write(s.replace(g,''))
PY
t test_without_guard cargo test --release -p nice_common --lib residue_empty_bases_search_to_nothing
cp /root/sf_fixed.rs common/src/stride_filter.rs; git diff --stat >> $O/head.txt
t test_with_guard cargo test --release -p nice_common --lib stride_filter
t just_lint /usr/local/bin/just lint
t workspace cargo test --locked --release --no-fail-fast
t common_gpu cargo test --locked --release -p nice_common --features gpu --lib
t client_build cargo build --release -p nice_client --features gpu
mkdir -p /root/bin/sfx; cp /root/t/sfx/release/nice_client /root/bin/sfx/
echo done > $O/done
