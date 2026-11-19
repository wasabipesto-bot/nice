#!/bin/bash
# box: post.sh — after final.sh: the wide kernels' sources of both heads (dumpwide.sh), then the middle-out tests
# alone of tier (a) in the debug profile (the head's debug test binary, filter "midout"), timed.
bash /root/dumpwide.sh base5a; bash /root/dumpwide.sh fin
diff /root/dump/w_base5a/wcu_sums.txt /root/dump/w_fin/wcu_sums.txt > /root/runs/wcu_sums.diff; echo "wcu_sums diff rc=$?" >> /root/runs/wcu_sums.diff
XD=$(grep -oP "Executable unittests src/lib.rs \(\K[^)]*" /root/runs/head/build_debug.txt | tail -1)
s0=$(date +%s); $XD midout --test-threads 4 > /root/runs/head/tier_a_debug_midout.txt 2>&1; echo "tier_a_debug_midout rc=$? $(( $(date +%s) - s0 )) s" >> /root/runs/head/rc.txt
X=/root/bin/head/t_sc; s0=$(date +%s); $X midout --test-threads 4 > /root/runs/head/tier_a_release_midout.txt 2>&1; echo "tier_a_release_midout rc=$? $(( $(date +%s) - s0 )) s" >> /root/runs/head/rc.txt
echo done > /root/runs/post.done
