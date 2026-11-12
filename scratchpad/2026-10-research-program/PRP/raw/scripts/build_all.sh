#!/bin/bash
# build_all.sh: per tree (in parallel, -j 10 each): test binary gpu,cubecl-spirv (X), test binary gpu (X_naga), client gpu (client_X).
S=/root/prp/scripts
for T in M S F; do
  ( bash $S/build.sh $T $T test gpu,cubecl-spirv; bash $S/build.sh $T ${T}_naga test gpu; bash $S/build.sh $T client_$T client gpu ) > /root/prp/out/build_all_$T.out 2>&1 &
done
wait; echo BUILD_ALL_DONE $(date -u +%T)
