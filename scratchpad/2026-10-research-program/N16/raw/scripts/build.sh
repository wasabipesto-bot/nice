#!/bin/sh
# build.sh TREE LABEL [FEATURES]: nice_common's release test binary of $W/wt/TREE -> $BIN/LABEL, with its own target
# directory ($W/target-TREE, so two trees of the same crate version never share artifact slots), niced, -j ${JOBS:-8}.
# FEATURES default gpu,cubecl-spirv (production's build on the RX 9070 XT: CUDA + CubeCL's wgpu runtime with the SPIR-V
# compiler); the binary carries both the CUDA and the wgpu harness. Prints the build time and the binary's md5.
. "${SCRIPTS:-$(dirname "$0")}/env.sh"
T=$1; L=$2; F=${3:-gpu,cubecl-spirv}
cd "$W/wt/$T" || exit 1
export CARGO_TARGET_DIR=$W/target-$T
t0=$(date +%s)
nice -n 19 cargo test --release -j "${JOBS:-8}" -p nice_common --features "$F" --no-run > "$OUT/build_$L.log" 2>&1 ||
  { echo "BUILD FAILED $L"; tail -40 "$OUT/build_$L.log"; exit 1; }
bin=$(grep -o "$CARGO_TARGET_DIR/release/deps/nice_common-[0-9a-f]*" "$OUT/build_$L.log" | head -1)
cp "$bin" "$BIN/$L" && echo "built $L ($T $(git -C "$W/wt/$T" log --oneline -1 | cut -c1-12), features $F) in $(( $(date +%s) - t0 )) s: md5 $(md5sum "$BIN/$L" | cut -c1-8) from $bin"
# The binary must be the tree's: N16's binary carries the string NICE_EXP_JOIN_DBL, main's does not.
if strings "$BIN/$L" | grep -q NICE_EXP_JOIN_DBL; then echo "  $L: has the N16 switches"; else echo "  $L: no N16 switches"; fi
