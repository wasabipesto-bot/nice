#!/bin/bash
# box: lintX.sh SRC TAG — `just lint` and the middle-out clippy sets on /root/SRC (target /root/t/SRC); output /root/runs/l_TAG
source ~/.cargo/env; S=$1; O=/root/runs/l_$2; mkdir -p $O; rm -f $O/done $O/rc.txt; cd /root/$S; git log --oneline -1 > $O/head.txt; git status --short >> $O/head.txt; md5sum common/src/midout/*.rs >> $O/head.txt
export CARGO_TARGET_DIR=/root/t/$S
t() { n=$1; shift; s0=$(date +%s); "$@" > $O/$n.txt 2>&1; echo "$n rc=$? $(( $(date +%s) - s0 )) s" >> $O/rc.txt; }
t just_lint /usr/local/bin/just lint
for f in cubecl-cuda,cubecl-spirv,midout-bench,midout-box-tests cubecl,midout-box-tests cubecl-spirv; do t clippy_$f cargo clippy -p nice_common --all-targets --features $f -- -D warnings; done
echo done > $O/done
