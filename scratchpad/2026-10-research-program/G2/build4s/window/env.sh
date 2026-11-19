# Window 2 (the library path) environment, sourced by every script here. Override in the caller's environment.
#   W     workspace: bin/ (t_mo = nice_common's test binary, mo_bench and mo_wide_bench = the examples, all from
#         dev/middle-out-join at the commit named in WINDOW-PLAN-2.md, --features cubecl-spirv; main = t_mo, whose
#         production code is main's), out/
#   DEV   card (RX 9070 XT: RADV, AMD sysfs sampled) or lvp (dry run on lavapipe: small sizes, no sampling)
: "${W:?set W}"
: "${OUT:=$W/out}" "${BIN:=$W/bin}" "${DEV:=card}"
: "${SCRIPTS:=$(dirname "$(readlink -f "$0")")}"
mkdir -p "$OUT"
export NICE_BUILD_SHA=test RUST_LOG=${RUST_LOG:-warn}
# exactness (step 5L head): seven base-64 slices in three processes. A slice (digits 4-8) is a slice of exactly one
# field under either coordinate; under the default (4, 8, 5) the field is t = digits 5-7 = (pip >> 6) & 0x3FFFF.
# XS1, XS2 run with the parents shared across digit 8 (MIDOUT_SHARE8=1: the slice's depth-8 list built by anc8, then
# hist2 over it, as a (4, 8, 5) field does); XS3 unshared: the 141-probe job and three slices of the timing field
# 77777 under (4, 8, 5) (digit 4 = 0; digit 8 = 0, 63, 13: 4977728 + c << 24). The wide path at b40 and b65; then the
# fault test; then one whole field under the old coordinate (4, 9, 6) with the sampled CPU check (accounts + one
# slice n for n), since both coordinates are supported.
: "${XS1:=712012851,318575442}" "${XS2:=0,1073741823}" "${XS3:=806726610,4977728,1061942336,223081536}"
: "${XWIDE:=40:3:6:1234,65:4:10:717171717}" "${XFAULT:=712012851}"
: "${X496:=77777}"
: "${MOCLS:=63}"          # classes per launch batch (the library's default; 4 on lavapipe)
: "${XWCLS:=}"            # the wide test's classes per batch (default: the library's; 2 on lavapipe)
: "${HTHREADS:=11}"       # host threads (demoux: 12)
# timing: base-64 fields t under the default (4, 8, 5) (t = digits 5-7; any t < 2^18 is a field of either coordinate);
# the first is a warm-up the analysis drops (BUILD-NOTES 11.4's t values; 13.3 timed the same t under (4, 8, 5))
: "${MOFIELDS:=4095,13107,131072,249036,65536,196608}"
: "${STAGEF:=4095,77777}" # stage profile: warm-up, then field 77777 (BUILD-NOTES 9 and 10.6)
: "${MOPART:=}"           # dry run only: "--slices K" (each field's first K slices)
# (optional step 0) PR #270's two tests: $BIN/t_pr270 = nice_common's test binary of upstream branch
# pr/stride-ran-account at 05f18331 (--features cubecl-spirv); skipped if absent
: "${PR270_TESTS:=cubecl_dropped_launches_fail_the_field cubecl_queues_check_every_survivor_on_partly_filled_planes}"
# main: B64.1's base-64 1e17 fields 2 and 6 (the bracket of WINDOW-RESULTS.md: 90.83 s and 100.41 s that morning,
# base mean 4.707 fs); one process each (the harness's untimed warm-up field first)
: "${SZ64:=1e17}"
F2=43445731862957161709568; F6=58557331862957161709568
: "${HARNESS:=cubecl_join::tests::join_throughput_fixed_fields}"
