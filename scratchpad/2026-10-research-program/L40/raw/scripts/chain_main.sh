#!/bin/bash
# chain_main.sh: tree P = fork pr/join-group-walk (the candidate); its test binary, registers, client; the counter
# binaries MR (base + NICE_EXP_JOIN_ROUNDS) and GR (P + the same); the counter runs (modes 1-3, b62 1e17 1 field and
# b60 1e16 2 fields); then P's CUDA exactness list (chain_x.sh).
L=/root/l40/logs; R=/root/l40/run.sh
/root/l40/tree.sh P pr/join-group-walk
/root/l40/build.sh P P || exit 1
touch $L/P.built
/root/l40/regs.sh P P P > $L/regs_P.out 2>&1
grep join_kernel /root/l40/sass/P/registers.txt; head -1 $L/regs_P.out
/root/l40/buildclient.sh P client_P > $L/buildclient_P.out 2>&1; tail -2 $L/buildclient_P.out
python3 /root/l40/add_rounds.py /root/l40/src/P/common/src/cubecl_join.rs /root/l40/src/GR/common/src/cubecl_join.rs G
(cd /root/l40/src/MR && md5sum common/src/cubecl_join.rs; cd /root/l40/src/GR && md5sum common/src/cubecl_join.rs) >> $L/trees.txt
/root/l40/build.sh MR MR || exit 1
/root/l40/build.sh GR GR || exit 1
touch $L/builds.done
echo CTR_START $(date -u +%T)
for m in 1 2 3; do
  for t in MR GR; do
    SRCD=$t NICE_EXP_JOIN_ROUNDS=$m $R ctr_${t}_m${m}_e17_b62 $t 62 1 1e17
    SRCD=$t NICE_EXP_JOIN_ROUNDS=$m $R ctr_${t}_m${m}_e16_b60 $t 60 2 1e16
    for f in e17_b62 e16_b60; do echo "ctr $t mode $m $f: $(grep -o 'survivors=[0-9]*\|device=[0-9.]*s' $L/ctr_${t}_m${m}_$f.log | tr '\n' ' ')"; done
  done
done
echo CTR_DONE $(date -u +%T)
/root/l40/chain_x.sh P
echo CHAIN_MAIN_DONE $(date -u +%T) > $L/main.done
