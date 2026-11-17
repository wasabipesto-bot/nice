# G2 window environment (sourced). Override in the caller's environment.
#   W     workspace: bin/ (g2 = the G2 example, main = nice_common's test binary at the same commit), data/ (the two
#         super-units' tops.bin, surv.bin, meta.txt), out/
#   DEV   card (RX 9070 XT: RADV, AMD sysfs sampled) or lvp (dry run on lavapipe; no GPU sampling)
: "${W:?set W}"
: "${OUT:=$W/out}" "${BIN:=$W/bin}" "${DATA:=$W/data}" "${DEV:=card}"
: "${SCRIPTS:=$(dirname "$(readlink -f "$0")")}"
mkdir -p "$OUT"
export NICE_BUILD_SHA=test RUST_LOG=${RUST_LOG:-warn}
SU1=$DATA/su64_712012851; SU2=$DATA/su64_391856203
# G2 runs: the whole super-unit in launches of 1008 jobs (output buffers stay under 64 MB); REPS launches per mode
: "${G2JOBS:=all}" "${G2BATCH:=1008}" "${REPS:=400}"
# main: B64.1's ten base-64 1e17 fields at 0.05..0.95 (aligned; 0.25, 0.45 and 0.75 are empty), one process each
# (the harness's untimed warm-up field first), the same starts as G2/bench/box/queue_b64.json
: "${SZ64:=1e17}"
F64S="39667831862957161709568 43445731862957161709568 47223631862957161709568 51001531862957161709568 54779431862957161709568 58557331862957161709568 62335231862957161709568 66113031862957161709568 69890931862957161709568 73668831862957161709568"
# HARNESS: the wgpu harness on the AMD card; cubecl_join::tests::cubecl_cuda_join_throughput_fixed_fields for a CUDA dry run
: "${HARNESS:=cubecl_join::tests::join_throughput_fixed_fields}"
# G2EXTRA: extra arguments for every G2 run (--cuda for the CUDA dry run)
: "${G2EXTRA:=}"
