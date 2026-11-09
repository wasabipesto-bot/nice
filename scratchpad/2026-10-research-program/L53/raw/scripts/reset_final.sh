#!/bin/bash
# reset_final.sh: after the similar_names fix (commit 80a103e): archive the exactness/lint logs of the pre-rename tree
# (39a495a) to logs/prerename/, and rebuild trees C, R2, CD from the final diffs.
cd /root/l53
mkdir -p logs/prerename
for f in logs/x_C_* logs/cmp_C_e14.* logs/x_C.done logs/fmt_C.log logs/clippy_*_C.log logs/lint_C.done logs/lvp_C.built logs/build_C.log logs/build_C_naga.log logs/build_C_spv.log chain_x_C.out chain_lint_C.out chain_lvp_C.out chain_rebased.out; do
  [ -e "$f" ] && mv "$f" logs/prerename/
done
rm -f bin/C bin/C_naga bin/C_spv
bash addN.sh C /root/l53/commit2.diff && bash addN.sh R2 /root/l53/r2b.diff && bash addN.sh CD /root/l53/cdb.diff
for t in C R2 CD; do (cd src/$t; echo $t $(md5sum common/src/cubecl_join.rs common/src/join_plan.rs | cut -c1-12)); done
ls logs/prerename
