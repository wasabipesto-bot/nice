# Window 2: the library path of the middle-out join on the RX 9070 XT, at most 45 minutes (step 4S, 2026-11-19)

**What it decides.** Whether the library path (`dev/middle-out-join`: device tops, preparation with accounts, the
main kernel with child lists and accounts, the expansion with the prefilter, production's check) is exact at 64
lanes on the card, and its ratio against today's main there, in the same session, by the pipelined protocol a
client would see. Until now the library path has run only on an RTX 3080 (CUDA, 32 lanes) and on lavapipe (8 lanes).

- **Prediction [P]** (`G2/build4s/model_4s.py --tag=head`, BUILD-NOTES §12.3): slice 4.17–4.80 ms, central 4.49 ms
  = **1.00 fs per admissible n, ×4.69 (×4.38–5.04)** against main's 4.707 fs. The main kernel binds (3.09–3.35 ms
  of the slice, 72 %); then the preparation (0.48–0.52), the expansion (0.43–0.56), the tops (0.12–0.24).
- **Context [M]:** the same library path on the 3080 is ×3.91 against that card's main; the prototype kernel on
  this card measured ×5.48 (inputs resident) and ×5.14 (uploads per unit).

> **Changes for step 5L's head (2026-11-19, 12:00 UTC; BUILD-NOTES §13–§14). This section overrides the text below
> where they differ.**
>
> - **Build `66259bb0`** (step 5L's `e09ad7b0` + one test-only commit), same commands. The default coordinate of b64
>   and b65 is now **(4, 8, 5)**: a field fixes digits 5–7 (t = those digits, any t < 2^18), 4,096 slices with digit 4
>   innermost; parents are shared across digit 8 by default (64 depth-8 lists per field, 870 MB).
> - **Prediction [P]:** slice 4.01–4.64 ms, **0.97 fs, ×4.87 (×4.54–5.25)**; the main kernel binds (74 %). Memory:
>   b64 ~4.9 GB, b65 ~8.3 GB at peak (sums 2.56 / 4.30 GB × the 3080's measured 1.93); fits the card.
> - **Step 0 (optional, ~2 min + its build):** PR #270's two tests, `cubecl_dropped_launches_fail_the_field` and
>   `cubecl_queues_check_every_survivor_on_partly_filled_planes`, from their own binary: upstream branch
>   `pr/stride-ran-account` at `05f18331`, `cargo test --release --features cubecl-spirv -p nice_common --lib --no-run`
>   in a second worktree with its own target directory, the unittests binary copied to `$W/bin/t_pr270`. The driver
>   runs it first if that file exists (`p_pr270`); a failure is reported, never a stop. (On lavapipe W 8: 2 passed,
>   7 s, `build4s/raw/pr270/lvp.log`.)
> - **Step 1 now:** seven slices in three processes, then the wide path alone (memory: three narrow processes ~3.3 GB
>   each, b65 up to ~8.3 GB): `x_g1` 712012851, 318575442 and `x_g2` 0, 2^30 − 1 **with the shared depth-8 lists**
>   (`MIDOUT_SHARE8=1`: `anc8` at 64 lanes, then `hist2` over the list, n for n against the CPU reference); `x_g3`
>   unshared: 806726610 (the 141-probe job) and three slices of timing field 77777 under (4, 8, 5) (digit 4 = 0, digit
>   8 = 0, 63, 13: 4977728, 1061942336, 223081536); `x_w` b40 and b65; `x_f` the fault test; then **`x_496`: one whole
>   field t 77777 under the old coordinate (4, 9, 6)** (`midout_bench --digits 4,9,6`, sampled CPU check on: every
>   account plus one random slice n for n; ~25 s), outcome E3 if it fails (the (4, 8, 5) steps continue). About 6 min.
> - **Steps 2–8 unchanged in form;** the field numbers t are the same values but now name (4, 8, 5) fields (§13.3
>   timed the same t under (4, 8, 5) on the 3080: 1.619 fs, ×4.09 there). Each bench run prints `SHARE t …: 64
>   depth-8 lists` (sharing on). Main's bracket fields are main's own, unchanged.
> - **Outcomes:** T1 ≥ ×4.54 (the new band's floor), T2 ×4.0–4.54, T3 < ×4.0; parents stage band 0.31–0.35 ms; a
>   parents stage near 0.48–0.52 means the lists were not used (check the `SHARE` line).
> - Total about 22 min (+2 with step 0), inside 45.
> - Dry run of the updated driver on lavapipe: see "Dry run 2" at the end.

## Before the window (on demoux, production client still running: building needs no GPU)

Workspace `$W` (the lease's directory), Rust 1.100.0 at `$HOME/.cargo/bin`.

```
git -C ~/nice-src fetch https://github.com/wasabipesto-bot/nice.git dev/middle-out-join   # or the bundle below
git -C ~/nice-src worktree add $W/wt <9b790647 (or the head BUILD-NOTES §1 names)>
cd $W/wt && export CARGO_TARGET_DIR=$W/target
cargo test  --release -p nice_common --features cubecl-spirv --lib --no-run      # ~10 min first time
cp <the path cargo prints after "Executable unittests src/lib.rs (...)"> $W/bin/t_mo
#   (cargo 1.100 puts it under target/release/build/nice_common/<hash>/out/, not deps/)
cargo build --release -p nice_common --features cubecl-spirv --example midout_bench --example midout_wide_bench
cp $W/target/release/examples/midout_bench $W/bin/mo_bench; cp $W/target/release/examples/midout_wide_bench $W/bin/mo_wide_bench
mkdir -p $W/scripts && cp <ivory: G2/build4s/window/*> $W/scripts/
```

- Bundle alternative (no network): `G2/build4s/midout-4s.bundle`, prerequisite upstream main `be9cc923`
  (`git -C ~/nice-src fetch <bundle> dev/middle-out-join:dev/middle-out-join`).
- `t_mo` is also main's binary: the branch changes no production code path (BUILD-NOTES §1), so main's harness
  `cubecl_join::tests::join_throughput_fixed_fields` in it is upstream main `be9cc923` byte for byte. Yesterday's
  base mean (4.707 fs) came from an older main (`7e0113fc`); the bracket fields below measure the difference.
- The driver needs nothing else: no staged data (every reference is computed on demoux's CPU inside the tests).

## Steps (director, production client stopped by the user)

1. `vulkaninfo --summary` shows RADV GFX1201, subgroup size 64. Then
   ```
   mkdir -p $W/out; W=$W END_AT=$(( $(date +%s) + 44*60 )) setsid nohup sh $W/scripts/go_mo.sh > $W/out/go.out 2>&1 &   # pgid to $W/go.pgid
   ```
2. **The order** (`go_mo.sh`), with time estimates [E] on this card and CPU (Ryzen 5600X, 12 threads):

| # | step | runs | est. |
|---|---|---|---|
| 1 | **exactness at W 64**, in parallel (the CPU references are the long part): `x_g1` slices 712012851, 318575442; `x_g2` 0, 2^30 − 1; `x_g3` 806726610 (a 141-probe job), 502136830 — device tops = host tops, prefiltered lists n for n, every count (`gpu_slices_equal_cpu`, classes 63); `x_w` the wide path at b40 slice 1234 and **b65 slice 717171717** (`wide_slices_equal_cpu`); then `x_f` the fault test at 712012851 (`accounts_faults_are_loud`: four faults loud by account, F_PF_DROP by the sampled check) | 5 processes | 4 min |
| 2 | **whole fields, round 1** (`b_r1`): `midout_bench --fields 4095,13107,131072,249036,65536,196608 --group 16 --threads 11 --no-cpu-check` (t 4095 is the warm-up, dropped) | 1 | 2.2 min |
| 3 | main's bracket field 2 (`main_f2`, B64.1 1e17 at 0.15; 90.83 s on 11-18) | 1 | 1.8 min |
| 4 | round 2 (`b_r2`) | 1 | 2.2 min |
| 5 | main's bracket field 6 (`main_f6`, 0.55; 100.41 s on 11-18) | 1 | 1.9 min |
| 6 | **stage profile**, field 77777 after a warm-up field: `MIDOUT_STOP` = 1 (tops), 2 (+ parents), 3 (+ main kernel), 5 (+ expansion), and the full path (`s_6`) | 5 | 3.5 min |
| 7 | the sampled CPU check's cost (`b_cc`: the same two fields with the check on) | 1 | 0.8 min |
| 8 | spares: round 3 (`b_r3`); the wide path at b65, a warm-up and field 77777 (`w_65`, only if `x_w` passed) | 2 | 3.5 min |
| | **total** | | **≈ 20 min**, inside 45 with room for one re-run of each kind |

3. **Accept** a timing run only if `python3 $W/scripts/analyze_mo.py $W/out` shows it at the operating point
   (median ≥ 2,800 MHz and ≥ 270 W over the samples at ≥ 80 % busy: the card's point under G2 is 2.85 GHz at the
   304 W cap; main runs at 3.1 GHz at the same cap), survivors and checked equal field for field across rounds, and
   main's fields equal in survivors and checked to 11-18's runs.
4. **At the end:** copy `$W/out` to ivory (`G2/build4s/window_out/`), stop any sampler by its PID, report.

**Stop line.** No step starts after `END_AT` (44 minutes) or once `$W/stop` exists. The driver itself stops after
step 1 if any exactness run fails (below); after that, a failed bench run (an account or a guard: the library
refuses a field whose work it cannot prove) is reported and not retried.

## What the outcomes mean

`analyze_mo.py` prints: per round the fields' mean fs per admissible n; main's base mean, 4.707 fs × the bracket's
drift (fields 2 and 6 against 11-18); **ratio = base / median of the rounds**; the stage profile per slice against
the model's bands; the sampled check's wait.

| outcome | reading | next |
|---|---|---|
| **E1** a parity run fails | the library path is not exact at 64 lanes. With `plane N` errors (RADV ran planes other than the 64 the device reports), the driver runs `x_g1_w32` (`MIDOUT_FORCE_W=32`): if that passes, the W 32 path is exact on the card and a client would pin it (a code change, not a window decision); without plane errors, the failing kernel is in the panic message | stop; the logs come to ivory |
| **E2** the fault test fails | an account or the sampled check is silent at 64 lanes | stop |
| `x_w` fails, the rest passes | the wide path (b65+) is not exact at 64 lanes; base 64 is unaffected | continue the base-64 steps; skip `w_65` |
| **T1** ratio ≥ ×4.38 | inside or above the model's band: the library path keeps most of the prototype's ×5.1–5.5 here | the client route (piece F) on this card |
| **T2** ×4.0–4.38 | below the band, above the 3080's ×3.9: read which stage is above its band | the stage it names (BUILD-NOTES §12.5's list) |
| **T3** < ×4.0 | the library path loses more on the card than on CUDA | stop and report the stage profile |
| main kernel (3 − 2) above 3.35 ms | the child-list writes do not hide (135 MB per slice) | the u16 child list (§12.5) |
| `b_cc` waits more than ~5 s per field | the sampled CPU check (one slice on one host thread, 22 s on ivory) is slower than a field on this card (~18 s) | a client samples one slice every k fields, or runs the reference on more threads |
| the rounds differ by > 3 % | bimodal per-process timing (seen on the 3080 for the CubeCL kernel) | report median and minimum; the decision uses the median |

## Dry run [M] (ivory, lavapipe 26.0.8 in container `lvp26`, W 8, 2 threads)

`G2/build4s/window/dryrun_lvp.sh <workspace>`: `go_mo.sh` unchanged, at sizes lavapipe can finish (one slice per
parity process, the wide path at b40 only, fields of one slice through `--slices 1`, main's fields at 1e14,
`PAR=0`), binaries of `e34e4df7` (the library code of the head). **Ran end to end, 06:48–07:50 UTC** (log and
outputs `G2/build4s/window_dryrun/`, the analysis `analysis.txt`):

- exactness: `x_g1` 712012851, `x_g2` 0, `x_g3` 2^30 − 1 (device tops = host tops, lists n for n), `x_w` b40,
  `x_f` (every fault loud or caught) — all PASS, `EXACT narrow=1 wide=1 faults=1` (the plane-width line printed W 8, as lavapipe has);
- `b_r1`–`b_r3` (one slice of field 77777 each after a one-slice warm-up), equal survivors and checked across rounds;
  `main_f2` 698 s and `main_f6` 742 s at 1e14 (the harness's join route); the stage runs `s_1`–`s_6` and `b_cc`
  (the sampled check equal, CPU thread 22.0 s); `analyze_mo.py` printed every table and an outcome line.
- Not exercised: the AMD sysfs sampler (lavapipe has none; on the card check `$OUT/x_g1.gpu` fills, as the driver
  prints), the plane-error branch (`x_g1_w32`), and `w_65` (skipped off the card: a b65 field is hours on lavapipe).
- On lavapipe a "slice" of the stage profile is 28 s; nothing about the card's times follows from it.

## The window in three lines

1. Build `t_mo`, `mo_bench`, `mo_wide_bench` from `9b790647` on demoux beforehand; then `go_mo.sh`: exactness at W 64
   first (six b64 slices, the wide path at b65, the fault test; ~4 min) — any failure stops the window.
2. Two rounds of five whole b64 fields (pipelined, groups of 16) around main's bracket fields 2 and 6, then the
   stage profile and the sampled check's cost (~16 min); spares: a third round and one b65 field.
3. Predicted ×4.69 (×4.38–5.04) against main; below ×4.0 stop and report which stage exceeded its band.

