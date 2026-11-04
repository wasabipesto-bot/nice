#!/bin/bash
# chain_head.sh: the final head (734899f: 6539b9e with "four" -> "three" in one doc comment and the CHANGELOG line):
# tree R, its test binary (expected byte-identical to Q's: no line moves), and rustfmt's check.
source ~/.cargo/env
L=/root/l38/logs
/root/l38/tree.sh R pr/join-top-record
NICEN=10 /root/l38/build.sh R R
echo "md5 Q $(md5sum /root/l38/bin/Q | cut -c1-32) R $(md5sum /root/l38/bin/R | cut -c1-32)" | tee $L/head_md5.txt
( cd /root/l38/src/R && cargo fmt --all --check; echo "fmt rc=$?" ) > $L/fmt_R.log 2>&1
tail -n 1 $L/fmt_R.log
echo HEAD_DONE $(date -u +%T) > $L/head.done
