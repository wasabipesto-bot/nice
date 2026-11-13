# N21 window environment, sourced by every script here. Override any of these in the caller's environment.
#   W        workspace (demoux: /tmp/claude-exp-<date>-amd as the window's brief names it; the box: /root/win)
#   DEV      wgpu (the RX 9070 XT; lavapipe on the box) or cuda (the box's RTX 3080)
#   COMMIT   the exp/n21-walk-loop commit the window builds
: "${W:?set W}"
: "${SCRIPTS:=$W/scripts}"
: "${OUT:=$W/out}"
: "${BIN:=$W/bin}"
: "${DEV:=wgpu}"
: "${COMMIT:=origin/exp/n21-walk-loop}"
mkdir -p "$OUT" "$BIN"
export NICE_BUILD_SHA=test
command -v cargo > /dev/null 2>&1 || { [ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"; }
case $DEV in
  cuda) HARNESS=cubecl_join::tests::cubecl_cuda_join_throughput_fixed_fields;;
  *)    HARNESS=cubecl_join::tests::join_throughput_fixed_fields;;
esac
# The fields (N16's): b62 1e17 at 0.45, b64 1e17 at 0.55, b60 1e16 at 0.55.
: "${F62:=7520566762397899821056}"
: "${F64:=58557331862957161709568}"
: "${F60:=1447429612114824200908}"
: "${SZ62:=1e17}" "${SZ64:=1e17}" "${SZ60:=1e16}"
