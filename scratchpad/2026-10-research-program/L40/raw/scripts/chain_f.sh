#!/bin/bash
# chain_f.sh: variant F (group walk for transposed batches only; small batches walk per chunk and slot as the base):
# test binary, registers + 1e14 counts, client; then the A/B M vs F (chain_ab2.sh, nothing else on the box).
L=/root/l40/logs
/root/l40/build.sh F F || exit 1
/root/l40/regs.sh F F F > $L/regs_F.out 2>&1
grep join_kernel /root/l40/sass/F/registers.txt; head -1 $L/regs_F.out
/root/l40/buildclient.sh F client_F > $L/buildclient_F.out 2>&1; tail -n 2 $L/buildclient_F.out
(cd /root/l40/src/F && echo "F (variant, uncommitted) $(md5sum common/src/cubecl_join.rs) $(date -u +%T)") >> $L/trees.txt
touch $L/ab2_go
/root/l40/chain_ab2.sh F
echo CHAIN_F_DONE $(date -u +%T)
