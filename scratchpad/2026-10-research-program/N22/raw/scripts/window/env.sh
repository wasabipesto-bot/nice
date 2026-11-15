# N22 window environment (from N21's window13/env.sh), sourced by every script here.
#   W        workspace (demoux: /tmp/claude-exp-<date>-amd; the box: /root/win)
#   DEV      wgpu (the RX 9070 XT; lavapipe on the box) or cuda (the box's RTX 3080)
#   COMMIT   the fork exp/n22-rdna4 commit the window builds
: "${W:?set W}"
: "${SCRIPTS:=$W/scripts}"
: "${OUT:=$W/out}"
: "${BIN:=$W/bin}"
: "${DEV:=wgpu}"
: "${COMMIT:=exp/n22-rdna4}"
mkdir -p "$OUT" "$BIN"
export NICE_BUILD_SHA=test
command -v cargo > /dev/null 2>&1 || { [ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"; }
case $DEV in
  cuda) HARNESS=cubecl_join::tests::cubecl_cuda_join_throughput_fixed_fields;;
  *)    HARNESS=cubecl_join::tests::join_throughput_fixed_fields;;
esac
# The fields (N16's production-shaped starts): b62 1e17 at 0.45, b64 1e17 at 0.55.
: "${F62:=7520566762397899821056}"
: "${F64:=58557331862957161709568}"
: "${SZ62:=1e17}" "${SZ64:=1e17}"
