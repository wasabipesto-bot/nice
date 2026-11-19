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
# exactness: six base-64 slices (the staged pair, both ends of the base, a 141-probe job, the audit's first) in three
# processes; the wide path at b40 (fast) and b65 (one slice, the CPU reference ~1.5 min); the fault tests
: "${XS1:=712012851,318575442}" "${XS2:=0,1073741823}" "${XS3:=806726610,502136830}"
: "${XWIDE:=40:3:6:1234,65:4:10:717171717}" "${XFAULT:=712012851}"
: "${MOCLS:=63}"          # classes per launch batch (the library's default; 4 on lavapipe)
: "${XWCLS:=}"            # the wide test's classes per batch (default: the library's; 2 on lavapipe)
: "${HTHREADS:=11}"       # host threads (demoux: 12)
# timing: base-64 fields t (digits 6-8); the first is a warm-up the analysis drops (BUILD-NOTES 11.4's set)
: "${MOFIELDS:=4095,13107,131072,249036,65536,196608}"
: "${STAGEF:=4095,77777}" # stage profile: warm-up, then field 77777 (BUILD-NOTES 9 and 10.6)
: "${MOPART:=}"           # dry run only: "--slices K" (each field's first K slices)
# main: B64.1's base-64 1e17 fields 2 and 6 (the bracket of WINDOW-RESULTS.md: 90.83 s and 100.41 s that morning,
# base mean 4.707 fs); one process each (the harness's untimed warm-up field first)
: "${SZ64:=1e17}"
F2=43445731862957161709568; F6=58557331862957161709568
: "${HARNESS:=cubecl_join::tests::join_throughput_fixed_fields}"
