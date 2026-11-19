#!/bin/bash
# box: sfx2.sh — the follow-up commit's checks in /root/sfx2 (reusing target /root/t/sfx): the base-43 field test
# alone with the guard removed (must panic) and with it (must pass); cargo fmt check and `just lint`; production's CI
# suite (workspace `cargo test --locked --release --no-fail-fast`; nice_common `--features gpu --lib`); the two new
# tests' times in release and debug. Output /root/runs/sfx2.
source ~/.cargo/env; cd /root/sfx2; export CARGO_TARGET_DIR=/root/t/sfx; O=/root/runs/sfx2; mkdir -p $O; rm -f $O/done $O/rc.txt
git log --oneline -1 > $O/head.txt; git diff --stat >> $O/head.txt
t() { n=$1; shift; s0=$(date +%s); "$@" > $O/$n.txt 2>&1; echo "$n rc=$? $(( $(date +%s) - s0 )) s" >> $O/rc.txt; }
cp common/src/stride_filter.rs /root/sf2_fixed.rs
python3 - <<'PY'
p='/root/sfx2/common/src/stride_filter.rs'; s=open(p).read()
g='''        if self.valid_residues.is_empty() {
            return Vec::new();
        }
'''
assert s.count(g)==1; open(p,'w').write(s.replace(g,''))
PY
t b43_without_guard cargo test --release -p nice_common --lib -- --exact stride_filter::tests::residue_empty_base_43_field_searches_to_nothing
cp /root/sf2_fixed.rs common/src/stride_filter.rs; git diff --stat >> $O/head.txt
t b43_with_guard cargo test --release -p nice_common --lib -- --exact stride_filter::tests::residue_empty_base_43_field_searches_to_nothing
t fmt cargo fmt --all --check
t just_lint /usr/local/bin/just lint
t workspace cargo test --locked --release --no-fail-fast
t common_gpu cargo test --locked --release -p nice_common --features gpu --lib
t new_tests_release cargo test --release -p nice_common --lib residue_empty -- --test-threads 1 --report-time -Z unstable-options
[ -s $O/new_tests_release.txt ] && grep -q "error" $O/new_tests_release.txt && t new_tests_release cargo test --release -p nice_common --lib residue_empty -- --test-threads 1
t new_tests_debug cargo test -p nice_common --lib residue_empty -- --test-threads 1
for k in residue_empty_bases_search_to_nothing residue_empty_base_43_field_searches_to_nothing; do
  for p in release debug; do
    X=$(ls -t /root/t/sfx/$p/deps/nice_common-* 2>/dev/null | grep -v '\.d$' | head -1)
    s0=$(date +%s.%N); $X --exact stride_filter::tests::$k > /dev/null 2>&1; echo "time $p $k rc=$? $(echo "$(date +%s.%N) - $s0" | bc) s" >> $O/rc.txt
  done
done
echo done > $O/done
