#!/bin/bash
# chain_post.sh REF: after the screen: tree P at the clone's local REF (the PR branch, fetched from a bundle while
# GitHub refused pushes), its test binary and client_P; then the
# CUDA exactness list on P (chain_x.sh) beside P's lavapipe builds (niced); then the A/B M vs P with nothing else on the
# box (chain_ab.sh, started at the same time and waiting for ab_go); after it, lavapipe tests (chain_lvp.sh) and the
# lint (chain_lint.sh).
L=/root/l38/logs; REF=$1
until [ -e $L/screen.done ]; do sleep 10; done
echo POST_START $(date -u +%T)
cd /root/nice && git worktree add -q --detach /root/l38/src/P $REF && (cd /root/l38/src/P && echo "P $(git log --oneline -1) $(md5sum common/src/cubecl_join.rs) $(date -u +%T)") >> $L/trees.txt
/root/l38/build.sh P P || exit 1
/root/l38/buildclient.sh P client_P || exit 1
/root/l38/regs.sh P P P > $L/regs_P.out 2>&1
/root/l38/chain_ab.sh P > $L/chain_ab.out 2>&1 &
/root/l38/chain_lvp.sh P > $L/chain_lvp.out 2>&1 &
/root/l38/chain_x.sh P > $L/chain_x_P.out 2>&1
until [ -e $L/lvp_P.built ]; do sleep 10; done
echo AB_GO $(date -u +%T); touch $L/ab_go
until [ -e $L/ab.done ]; do sleep 10; done
touch $L/lvp_go
until [ -e $L/lvp_P.done ]; do sleep 10; done
/root/l38/chain_lint.sh P > $L/chain_lint.out 2>&1
echo POST_DONE $(date -u +%T) > $L/post.done
