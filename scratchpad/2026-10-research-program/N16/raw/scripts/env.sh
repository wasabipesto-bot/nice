# N16 environment, sourced by every script here. Override any of these in the caller's environment.
#   W        workspace (demoux: /tmp/claude-exp-<date>-amd as the window's brief names it; the box: /root/n16)
#   SCRIPTS  this directory (copied to $W/scripts)
#   OUT      logs; BIN binaries
#   DEV      wgpu (the RX 9070 XT, lavapipe) or cuda (the RTX 3080): which harness test runs and how the GPU is sampled
: "${W:=/root/n16}"
: "${SCRIPTS:=$W/scripts}"
: "${OUT:=$W/out}"
: "${BIN:=$W/bin}"
: "${DEV:=wgpu}"
mkdir -p "$OUT" "$BIN"
export NICE_BUILD_SHA=test
command -v cargo > /dev/null 2>&1 || { [ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"; }
case $DEV in
  cuda) HARNESS=cubecl_join::tests::cubecl_cuda_join_throughput_fixed_fields
        DENSE=cubecl_join::tests::cubecl_cuda_join_matches_the_cpu_join_on_a_dense_field;;
  *)    HARNESS=cubecl_join::tests::join_throughput_fixed_fields
        DENSE=cubecl_join::tests::wgpu_join_matches_the_cpu_join_on_a_dense_field;;
esac
# The fields (N13/B64 positions; starts.py): b62 1e17 at 0.45 (the heavy field), b64 1e17 at 0.55, b60 1e16 at 0.55.
: "${F62:=7520566762397899821056}"
: "${F64:=58557331862957161709568}"
: "${F60:=1447429612114824200908}"
