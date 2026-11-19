#!/bin/bash
# box: lint.sh OUT — `just lint`'s commands on /root/mc (fmt check, clippy default, clippy with the GPU and SPIR-V features),
# then clippy of nice_common with the middle-out bench and box-test features (in no CI set) and with cubecl-spirv alone, into /root/t/mc
source ~/.cargo/env; cd /root/mc; export CARGO_TARGET_DIR=/root/t/mc; O=/root/runs/$1; mkdir -p $O; rm -f $O/done
git log --oneline -1 > $O/head.txt; git status --short >> $O/head.txt
# the recipe's three commands (the box's apt `just` 1.21 cannot parse the justfile)
cargo fmt --all --check > $O/fmt.txt 2>&1; echo "fmt rc=$?" >> $O/rc.txt
cargo clippy -p "*" --all-targets -- -D warnings > $O/clippy1.txt 2>&1; echo "clippy default rc=$?" >> $O/rc.txt
cargo clippy -p "*" --all-targets --features nice_client/gpu,nice_client/cubecl-spirv -- -D warnings > $O/clippy2.txt 2>&1; echo "clippy gpu,cubecl-spirv rc=$?" >> $O/rc.txt
for f in cubecl-cuda,cubecl-spirv,midout-bench,midout-box-tests cubecl,midout-box-tests cubecl-spirv; do cargo clippy -p nice_common --all-targets --features $f -- -D warnings > $O/clippy_$f.txt 2>&1; echo "clippy nice_common $f rc=$?" >> $O/rc.txt; done
echo done > $O/done
