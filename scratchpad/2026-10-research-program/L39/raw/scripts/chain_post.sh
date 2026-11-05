#!/bin/bash
# chain_post.sh: after the screen and client_B: tree P at the fork's pr/join-bottom-record, its test binary, client_P and
# registers; tree X (exp/join-entry-sectors: the base with a test that counts the entry loads' sectors) and its binary;
# the sector count on four production fields; then the CUDA exactness list on P (chain_x.sh) beside P's lavapipe builds (niced); then the A/B B vs P
# with nothing else on the box (chain_ab.sh, waiting for ab_go); after it, the lavapipe tests (chain_lvp.sh), the lint
# (chain_lint.sh) and the second register passes (chain_regs2.sh).
L=/root/l39/logs
until [ -e $L/screen.done ] && grep -q "BUILD_DONE\|FAILED" $L/buildclient_B.out 2>/dev/null; do sleep 10; done
echo POST_START $(date -u +%T)
/root/l39/tree.sh P pr/join-bottom-record
/root/l39/build.sh P P || exit 1
/root/l39/buildclient.sh P client_P || exit 1
/root/l39/regs.sh P P P > $L/regs_P.out 2>&1
/root/l39/tree.sh X exp/join-entry-sectors
/root/l39/build.sh X X || exit 1
/root/l39/chain_ab.sh P > $L/chain_ab.out 2>&1 &
/root/l39/chain_regs2.sh > $L/chain_regs2.out 2>&1 &
/root/l39/chain_lvp.sh P > $L/chain_lvp.out 2>&1 &
SRCD=X /root/l39/test.sh sectors X cubecl_join::tests::cubecl_cuda_entry_sectors NICE_TEST_ENTRY_SECTORS=62:7997740455941656911841:1e17,62:7997740455941656911841:1e16,60:1366406074057412100454:1e16,64:41242006262957161709568:1e16
/root/l39/chain_x.sh P > $L/chain_x_P.out 2>&1
until [ -e $L/lvp_P.built ]; do sleep 10; done
echo AB_GO $(date -u +%T); touch $L/ab_go
until [ -e $L/ab.done ]; do sleep 10; done
touch $L/lvp_go
/root/l39/chain_lint.sh P > $L/chain_lint.out 2>&1
until [ -e $L/lvp_P.done ] && [ -e $L/regs2.done ]; do sleep 10; done
echo POST_DONE $(date -u +%T) > $L/post.done
