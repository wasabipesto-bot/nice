#!/bin/bash
# chain_p6.sh: the final head P6 (48ac631 = P4 with the exhaustive test opt-in and the tests clippy-clean):
# after chain_final, its test binary, the host tests (the exhaustive one without and with the env), rustfmt, registers.
L=/root/l41/logs
until [ -e $L/final.done ]; do sleep 10; done
J=10 /root/l41/build.sh P6 P6 > $L/build_P6.out 2>&1 || { cat $L/build_P6.out; exit 1; }
cat $L/build_P6.out; grep -c "^warning" $L/build_P6.log
cd /root/l41/src/P6
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu NICE_BUILD_SHA=test
( /root/l41/bin/P6 fx_ lean_ --nocapture; /root/l41/bin/P6 fx_digits_are_exact_everywhere --ignored --nocapture; NICE_TEST_FX_EXHAUSTIVE=1 /root/l41/bin/P6 fx_digits_are_exact_everywhere --ignored --nocapture; /root/l41/bin/P6 join_plan:: ; /root/l41/bin/P6 cubecl_join:: ) > $L/host_P6.log 2>&1
grep -h "test result\|FAILED\|panicked\|skipping\|triples" $L/host_P6.log
( source ~/.cargo/env; cargo fmt --all --check; echo "fmt rc=$?" ) > $L/fmt_P6.log 2>&1; tail -1 $L/fmt_P6.log
/root/l41/regs.sh P6 P6 P6 > $L/regs_P6.out 2>&1; grep join_kernel /root/l41/sass/P6/registers.txt
/root/l41/chain_lint.sh P6 > $L/chain_lint_P6.out 2>&1; tail -n1 $L/fmt_P6.log $L/clippy_*_P6.log
touch $L/p6.done
