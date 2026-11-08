#!/bin/bash
# go.sh: after E's build, build B (d813aea) beside the sanity chain, then main, then screen.
cd /root/l51
until grep -q BUILD_DONE build_E.out 2>/dev/null || grep -q FAILED build_E.out 2>/dev/null; do sleep 5; done
grep -q FAILED build_E.out && { echo E failed; exit 1; }
( J=6 NICEN=10 bash build.sh B B > build_B.out 2>&1; touch build_B.done ) &
bash chain_sanity.sh > chain_sanity.out 2>&1
bash chain_main.sh > chain_main.out 2>&1
bash chain_screen.sh > chain_screen.out 2>&1
