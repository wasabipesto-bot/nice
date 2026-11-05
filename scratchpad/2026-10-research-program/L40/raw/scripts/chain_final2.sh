#!/bin/bash
# chain_final2.sh: after A/B 5 (ab5.done): tree Z = fork pr/join-group-walk (the head with F2's code); its test binary
# (compared with F2's, the A/B's binary), registers, Z's CUDA exactness list; and on the CPU, once Z is built, the lint
# and lavapipe chains on Z.
L=/root/l40/logs
until [ -e $L/ab5.done ]; do sleep 10; done
/root/l40/tree.sh Z pr/join-group-walk
/root/l40/build.sh Z Z || exit 1
(setsid nohup bash -c "/root/l40/chain_lint.sh Z; /root/l40/chain_lvp.sh Z; echo CPU_Z_DONE \$(date -u +%T) > $L/cpu_z.done" > $L/chain_cpu_z.out 2>&1 < /dev/null &)
cmp /root/l40/bin/Z /root/l40/bin/F2 > $L/cmp_Z_F2.txt 2>&1; echo "cmp rc=$? size Z $(stat -c %s /root/l40/bin/Z) F2 $(stat -c %s /root/l40/bin/F2) differing bytes $(cmp -l /root/l40/bin/Z /root/l40/bin/F2 2>/dev/null | wc -l)" >> $L/cmp_Z_F2.txt
diff <(strings -n 8 /root/l40/bin/Z | sort -u) <(strings -n 8 /root/l40/bin/F2 | sort -u) | head -20 >> $L/cmp_Z_F2.txt
/root/l40/regs.sh Z Z Z > $L/regs_Z.out 2>&1
grep join_kernel /root/l40/sass/Z/registers.txt; head -1 $L/regs_Z.out
/root/l40/chain_x.sh Z
echo CHAIN_FINAL2_DONE $(date -u +%T) > $L/final2.done
