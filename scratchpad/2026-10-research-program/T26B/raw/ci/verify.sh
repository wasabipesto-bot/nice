#!/bin/bash
# verify.sh: the fix (FS = cubecl-spirv, FW = cubecl) on Mesa 26.0.8 lavapipe in the 26.04 chroot:
# the new test 20 times alone with each compiler, then the lavapipe suites as CI runs them (FW: every ignored test of
# nice_common; FS: every ignored test matching cubecl_), CI's default thread count and --test-threads=4.
O=/root/w/out/verify.out; echo "VERIFY START $(date -u +%T)" > $O
for c in FS FW; do for i in $(seq 1 20); do bash /root/t.sh ${c}_single_$i $c --ignored --exact cubecl_backend::tests::cubecl_queues_check_every_survivor_on_partly_filled_planes --nocapture --test-threads=1 >> $O; done; done
TMO=3000 bash /root/t.sh FS_suite_ci_1 FS --ignored --nocapture cubecl_ >> $O &
TMO=3000 bash /root/t.sh FW_suite_ci_1 FW --ignored --nocapture >> $O &
wait
TMO=3000 bash /root/t.sh FS_suite_t4_2 FS --ignored --nocapture cubecl_ --test-threads=4 >> $O &
TMO=3000 bash /root/t.sh HS_suite_ci_x HS --ignored --nocapture cubecl_ >> $O &
wait
echo "VERIFY DONE $(date -u +%T)" >> $O
