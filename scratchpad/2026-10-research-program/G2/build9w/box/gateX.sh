#!/bin/bash
# box: gateX.sh SRC TAG — every tier on the working tree /root/SRC (own target dirs /root/t/SRC*): `just lint` and the
# middle-out clippy sets; production's CI test commands (the workspace's `cargo test --locked --release
# --no-fail-fast`, `nice_common --features gpu --lib`, `nice_client --features cubecl-cuda`); tier (a) in release
# (CI's profile) and tier (b) on lavapipe through WGSL and SPIR-V; the card tier (card9.sh, which waits for the GPU
# lock). Output /root/runs/x_TAG/.
source ~/.cargo/env; S=$1; T=$2; O=/root/runs/x_$T; mkdir -p $O; rm -f $O/done $O/rc.txt
cd /root/$S; git log --oneline -1 > $O/head.txt; git status --short >> $O/head.txt; git diff | md5sum >> $O/head.txt
t() { n=$1; shift; s0=$(date +%s); "$@" > $O/$n.txt 2>&1; echo "$n rc=$? $(( $(date +%s) - s0 )) s" >> $O/rc.txt; }
export CARGO_TARGET_DIR=/root/t/$S
t just_lint /usr/local/bin/just lint
for f in cubecl-cuda,cubecl-spirv,midout-bench,midout-box-tests cubecl,midout-box-tests cubecl-spirv; do
  t clippy_$f cargo clippy -p nice_common --all-targets --features $f -- -D warnings
done
if [ -z "${SKIPSUITE:-}" ]; then
export CARGO_TARGET_DIR=/root/t/${S}s
t suite_workspace cargo test --locked --release --no-fail-fast
t suite_common_gpu cargo test --locked --release -p nice_common --features gpu --lib
t suite_client_cubecl cargo test --locked --release -p nice_client --features cubecl-cuda
unset CARGO_TARGET_DIR
fi
bash /root/bt.sh $S $T; cp /root/logs/$T/bins.txt $O/
LVP=$(ls /usr/share/vulkan/icd.d/lvp_icd*.json | head -1)
t tier_a_release /root/bin/$T/t_sc --test-threads 4
for k in wg sc; do
  for x in $(/root/bin/$T/t_$k --list --ignored 2>/dev/null | grep -o "^[a-z_:0-9]*cubecl_midout[a-z_0-9]*"); do
    t b_${k}_${x##*::} env VK_ICD_FILENAMES=$LVP /root/bin/$T/t_$k --ignored --exact $x --nocapture --test-threads 1
  done
done
NOBENCH=1 bash /root/bb2.sh $S g_$T
bash /root/card9.sh card_$T /root/bin/g_$T/t_box
cp /root/runs/card_$T/rc.txt $O/card_rc.txt
echo done > $O/done
