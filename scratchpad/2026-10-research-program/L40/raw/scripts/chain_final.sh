#!/bin/bash
# chain_final.sh: after the final A/B (ab3.done): tree Q = fork pr/join-group-walk (the squashed head); its test binary
# (compared with H2's, the A/B's binary), registers; the counter binary QR (Q + NICE_EXP_JOIN_ROUNDS); Q's CUDA
# exactness list (chain_x.sh Q); the counters on QR (mode 1 at b62 1e17 and b60 1e16, modes 1-3 on the 1e14 b57/b62
# fields); a second registers pass of M and Q.
L=/root/l40/logs; R=/root/l40/run.sh
until [ -e $L/ab3.done ]; do sleep 10; done
/root/l40/tree.sh Q pr/join-group-walk
/root/l40/build.sh Q Q || exit 1
touch $L/Q.built
cmp /root/l40/bin/Q /root/l40/bin/H2 > $L/cmp_Q_H2.txt 2>&1; echo "cmp rc=$? size Q $(stat -c %s /root/l40/bin/Q) H2 $(stat -c %s /root/l40/bin/H2) differing bytes $(cmp -l /root/l40/bin/Q /root/l40/bin/H2 2>/dev/null | wc -l)" >> $L/cmp_Q_H2.txt
diff <(strings -n 8 /root/l40/bin/Q | sort -u) <(strings -n 8 /root/l40/bin/H2 | sort -u) | head -20 >> $L/cmp_Q_H2.txt
/root/l40/regs.sh Q Q Q > $L/regs_Q.out 2>&1
grep join_kernel /root/l40/sass/Q/registers.txt; head -1 $L/regs_Q.out
python3 /root/l40/add_rounds.py /root/l40/src/Q/common/src/cubecl_join.rs /root/l40/src/QR/common/src/cubecl_join.rs Q 2>/dev/null || { cd /root/nice && git worktree add -q --detach /root/l40/src/QR af21136; python3 /root/l40/add_rounds.py /root/l40/src/Q/common/src/cubecl_join.rs /root/l40/src/QR/common/src/cubecl_join.rs Q; }
(cd /root/l40/src/QR && echo "QR $(md5sum common/src/cubecl_join.rs) $(date -u +%T)") >> $L/trees.txt
/root/l40/build.sh QR QR || exit 1
/root/l40/chain_x.sh Q
echo CTRQ_START $(date -u +%T)
for f in "62 1 1e17 e17_b62" "60 2 1e16 e16_b60"; do set -- $f
  SRCD=QR NICE_EXP_JOIN_ROUNDS=1 $R ctr_QR_m1_$4 QR $1 $2 $3
  echo "ctr QR mode 1 $4: $(grep -o 'survivors=[0-9]*\|device=[0-9.]*s' $L/ctr_QR_m1_$4.log | tr '\n' ' ')"
done
for b in 57 62; do for m in 1 2 3; do
  SRCD=QR NICE_EXP_JOIN_ROUNDS=$m $R ctr14_QR_m${m}_e14_b$b QR $b 3 1e14
  echo "ctr14 QR mode $m b$b: $(grep -o 'survivors=[0-9]*\|device=[0-9.]*s' $L/ctr14_QR_m${m}_e14_b$b.log | tr '\n' ' ')"
done; done
echo CTRQ_DONE $(date -u +%T)
/root/l40/regs.sh M M2 M > $L/regs_M2.out 2>&1
/root/l40/regs.sh Q Q2 Q > $L/regs_Q2.out 2>&1
grep join_kernel /root/l40/sass/M2/registers.txt /root/l40/sass/Q2/registers.txt
echo CHAIN_FINAL_DONE $(date -u +%T) > $L/final.done
