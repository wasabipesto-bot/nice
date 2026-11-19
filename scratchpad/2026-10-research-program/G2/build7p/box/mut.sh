#!/bin/bash
# box: mut.sh — does the brute-force test see a wrong search? Two one-line faults in a scratch copy of
# /root/p2 (its own target dir /root/t/p2m), each must make whole_small_bases_vs_brute_force fail.
source ~/.cargo/env; O=/root/runs7p/mut; mkdir -p $O; rm -f $O/done $O/rc.txt
rm -rf /root/p2m; git clone -q /root/p2 /root/p2m; cd /root/p2m
[ -d /root/t/p2m ] || cp -a /root/t/p2 /root/t/p2m
export CARGO_TARGET_DIR=/root/t/p2m
F=common/src/midout/cpu.rs
run() { cargo test --release -p nice_common --lib whole_small_bases_vs_brute_force > $O/$1.txt 2>&1; echo "$1 rc=$?" >> $O/rc.txt; git checkout -q $F; }
# 1: the prefilter ignores the top's certified digits (mhi)
sed -i 's/if !(seen \& bit).is_zero() || (j >= k \&\& !(mhi \& bit).is_zero()) {/if !(seen \& bit).is_zero() {/' $F; git diff --stat >> $O/rc.txt; run m1_prefilter_no_mhi
# 2: a child whose two new digits are equal is kept
sed -i 's/if e2 == e3 || !(p.mask \& add).is_zero() {/if !(p.mask \& add).is_zero() {/' $F; git diff --stat >> $O/rc.txt; run m2_child_repeat
# 3: a top probes one class too few (the last root skipped)
sed -i 's/for \&rt in \&base.roots {/for \&rt in \&base.roots[..base.roots.len() - 1] {/' $F; git diff --stat >> $O/rc.txt; run m3_root_skipped
echo done > $O/done
