#!/bin/bash
# box: lint8.sh TAG — `just lint` (fmt check, clippy default, clippy with the GPU and SPIR-V features) and clippy of
# nice_common with the middle-out feature sets (in no CI set) on /root/mc. Target dir /root/t/mc. Output /root/runs/TAG.
source ~/.cargo/env; cd /root/mc; export CARGO_TARGET_DIR=/root/t/mc; O=/root/runs/$1; mkdir -p $O; rm -f $O/done $O/rc.txt
git log --oneline -1 > $O/head.txt; git status --short >> $O/head.txt
t() { n=$1; shift; s0=$(date +%s); "$@" > $O/$n.txt 2>&1; echo "$n rc=$? $(( $(date +%s) - s0 )) s" >> $O/rc.txt; }
t just_lint /usr/local/bin/just lint
for f in cubecl-cuda,cubecl-spirv,midout-bench,midout-box-tests cubecl,midout-box-tests cubecl-spirv; do
  t clippy_$f cargo clippy -p nice_common --all-targets --features $f -- -D warnings
done
echo done > $O/done
