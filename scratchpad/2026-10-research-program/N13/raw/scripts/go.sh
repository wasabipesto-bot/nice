#!/bin/sh
# go.sh: after the builds: build E_naga (E, wgpu through naga/WGSL: --features gpu,cubecl), then A, X, B.
W=/tmp/claude-exp-2026-11-11-amd; O=$W/out
until grep -q "ALL_BUILT" $O/builds.out; do sleep 5; done
sh $W/scripts/build.sh E E_naga gpu,cubecl >> $O/builds.out 2>&1
sh $W/scripts/chain_A.sh > $O/chain_A.out 2>&1
sh $W/scripts/chain_X.sh > $O/chain_X.out 2>&1
sh $W/scripts/chain_B.sh > $O/chain_B.out 2>&1
echo GO_DONE $(date -u +%T) > $O/go.done
