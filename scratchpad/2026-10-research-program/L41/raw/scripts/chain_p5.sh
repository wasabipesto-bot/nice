#!/bin/bash
# chain_p5.sh: the final head P5 (b6bf434 = P4 with fx_digits_are_exact_everywhere opt-in by NICE_TEST_FX_EXHAUSTIVE):
# after chain_final, its test binary, the host tests (the exhaustive one without and with the env), rustfmt, registers.
L=/root/l41/logs
until [ -e $L/final.done ]; do sleep 10; done
J=10 /root/l41/build.sh P5 P5 > $L/build_P5.out 2>&1 || { cat $L/build_P5.out; exit 1; }
cat $L/build_P5.out; grep -c "^warning" $L/build_P5.log
cd /root/l41/src/P5
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu NICE_BUILD_SHA=test
( /root/l41/bin/P5 fx_ lean_ --nocapture; /root/l41/bin/P5 fx_digits_are_exact_everywhere --ignored --nocapture; NICE_TEST_FX_EXHAUSTIVE=1 /root/l41/bin/P5 fx_digits_are_exact_everywhere --ignored --nocapture; /root/l41/bin/P5 join_plan:: ; /root/l41/bin/P5 cubecl_join:: ) > $L/host_P5.log 2>&1
grep -h "test result\|FAILED\|panicked\|skipping\|triples" $L/host_P5.log
( source ~/.cargo/env; cargo fmt --all --check; echo "fmt rc=$?" ) > $L/fmt_P5.log 2>&1; tail -1 $L/fmt_P5.log
/root/l41/regs.sh P5 P5 P5 > $L/regs_P5.out 2>&1; grep join_kernel /root/l41/sass/P5/registers.txt
touch $L/p5.done
