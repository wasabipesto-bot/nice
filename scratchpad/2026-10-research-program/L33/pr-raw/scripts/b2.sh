#!/bin/bash
# After rustfmt's one-line fix (whitespace only) to src/B: B2 = the pushed tree's CUDA test binary, built after the
# lavapipe binaries; fmt re-checked.
L=/root/l33p/logs; S=/root/l33p
until [ -e $L/lvpbuilds.done ]; do sleep 10; done
md5sum /root/l33p/src/B/common/src/cubecl_join.rs > $L/b2_src_md5.txt
$S/build.sh B B2 gpu > $L/build_B2.out 2>&1
md5sum $S/bin/B $S/bin/B2 >> $L/build_B2.out
( source ~/.cargo/env; cd /root/l33p/src/B && cargo fmt --all --check && echo FMT_OK ) > $L/lint_fmt2.log 2>&1
echo B2_DONE $(date -u +%T) > $L/b2.done
