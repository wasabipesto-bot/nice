#!/bin/bash
# verify2.sh: three more CI-style suites of the fix on cubecl-spirv (4 threads, default, 4 threads)
O=/root/w/out/verify.out; echo "VERIFY2 START $(date -u +%T)" >> $O
TMO=3000 bash /root/t.sh FS_suite_t4_3 FS --ignored --nocapture cubecl_ --test-threads=4 >> $O
TMO=3000 bash /root/t.sh FS_suite_ci_4 FS --ignored --nocapture cubecl_ >> $O
TMO=3000 bash /root/t.sh FS_suite_t4_5 FS --ignored --nocapture cubecl_ --test-threads=4 >> $O
echo "VERIFY2 DONE $(date -u +%T)" >> $O
