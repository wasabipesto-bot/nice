#!/bin/bash
# chain_fmtfix.sh: the PR head after rustfmt's one-line fix (6539b9e, fork pr/join-top-record): tree Q, its test binary
# (expected byte-identical to P's: whitespace only), then `just lint` as CI runs it (chain_lint.sh Q).
L=/root/l38/logs
/root/l38/tree.sh Q pr/join-top-record
/root/l38/build.sh Q Q
echo "md5 P $(md5sum /root/l38/bin/P | cut -c1-32) Q $(md5sum /root/l38/bin/Q | cut -c1-32)" | tee $L/fmtfix_md5.txt
/root/l38/chain_lint.sh Q > $L/chain_lint_Q.out 2>&1
for f in fmt_Q clippy_default_Q clippy_gpu_Q clippy_gpuspv_Q; do echo "$f: $(tail -n 1 $L/$f.log)"; done | tee $L/lint_Q.txt
echo FMTFIX_DONE $(date -u +%T) > $L/fmtfix.done
