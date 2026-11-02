#!/bin/bash
# Phase 1: build the baseline (A = exp/join-all3 0f1a8a7) and its profile variant (P = A + 0382c84 + 32b84af),
# then profile P at b62 1e17 (1 field) and b60 1e16 (2 fields).
L=/root/l34/logs; S=/root/l34
mkdir -p $L
apt-get install -y -qq libpq5 > $L/apt_libpq.log 2>&1
$S/build.sh P P gpu || exit 1
echo P_DONE $(date -u +%T) > $L/p.done
$S/build.sh A A gpu || exit 1
echo A_DONE $(date -u +%T) > $L/a.done
