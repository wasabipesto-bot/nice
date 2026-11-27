#!/bin/bash
# check_series.sh: worktree src/fx-series at 73bc0065, apply each patch of xfer/fx-series in turn (git am), and per
# commit: cargo fmt --check and cargo check of nice_common (lib + tests) with cubecl,midout-box-tests,midout-bench.
. "$(dirname "$0")/env.sh"
O=$R/runs/fx-series; W=$R/src/fx-series; mkdir -p "$O"; rm -f "$O/done" "$O/rc.txt"
cd "$R/src/nice" || exit 1
git fetch -q origin dev/mo-wide-b65b
if [ -d "$W" ]; then git -C "$W" checkout -q -f --detach 73bc0065; else git worktree add -q --detach "$W" 73bc0065; fi
cd "$W" || exit 1
export CARGO_TARGET_DIR=$R/t/lint
for p in $R/xfer/fx-series/*.patch; do
  git -c user.name=x -c user.email=x@x am -q "$p" || { echo "am failed $p" >> $O/rc.txt; break; }
  n=$(basename $p .patch | cut -c1-4)
  cargo fmt --all --check > $O/fmt_$n.txt 2>&1; f=$?
  cargo check -p nice_common --lib --tests --features cubecl,midout-box-tests,midout-bench > $O/check_$n.txt 2>&1; c=$?
  echo "$n fmt=$f check=$c tree=$(git rev-parse HEAD^{tree} | cut -c1-8)" >> $O/rc.txt
done
echo done > $O/done
