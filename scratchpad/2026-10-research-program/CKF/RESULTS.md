# CKF: the check kernel's hand-out, complete on partly filled planes (2026-11-13)

Branch `pr/check-d` (PR #251), head before: `bc9d87c7`. Fix: one commit on top, **`8d11e0be`**, pushed to fork `pr/check-d` as a fast-forward (`bc9d87c7..8d11e0be`) at about 08:50 UTC.
Box: Vast 60460107, RTX 3080 10 GB, host power cap 180 W, driver 580.159.03, i7-6850K (12 threads), lavapipe =
llvmpipe (LLVM 20.1.2, 256 bits, 8-lane subgroups), rustc 1.99.1 (the branch's pinned toolchain).
Labels: **[M]** measured here today, **[D]** derived from measured numbers, **[R]** read in source, **[A]** assumed.
Raw logs: `raw/box/logs/` (`<name>.log`; timing runs also `.smi`), build/chain outputs `raw/box/out/`, scripts
`raw/scripts/`, reproduction patch generator `raw/repro/make_repro.py`, commit as a patch `raw/0001-fix.patch`.

## 1. Reproduction (bc9d87c7, test-only patch)

`raw/repro/make_repro.py` patches bc9d87c7's `cubecl_join.rs` in tests only: `launch_check` takes the cube's unit
count, and `repro_{cuda_,}check_partial_planes` runs the unchanged check kernel in count mode over a synthetic list of
each of the 7 distinct shapes of the b10 band and the six `PLAN_FIELDS` (b42-64), on cubes of 256, 100 and 48 units, and
reports the entries whose four output words stay zero (never checked).

**CUDA (RTX 3080), one cube [M] (`raw/box/logs/repro_cuda2.log`):** the test fails.

| cube | partly filled warp | skipped per production shape (≈4,040 entries) | b10 (53 entries) |
|---|---|---|---|
| 256 units | none | 0 | 0 |
| 100 units | warp 3: lanes 0-3 of 32 | **896** (28 of every 128) | 0 (the list ends inside warps 0-1's first take) |
| 48 units | warp 1: lanes 0-15 of 32 | **1,008-1,011** (16 of every 64) | 5 (entries 48-52) |

In all **34,296 of 218,772 entries never checked**, the work counter ending at the same place it would with full
warps, which is why the PR's own end-value check could not see it. The skipped entries are exactly the missing lanes'
(first skipped: 68.. or 100.. at 100 units, 48.. at 48), as the audit's model predicts (28/32 of a 4-lane warp's take).

**Why one cube on CUDA [R][M]:** CubeCL 0.10's C++ backends (CUDA, HIP) lower `UNIT_POS_PLANE` as
`AbsolutePos % PLANE_DIM` (`cubecl-cpp-0.10.0/src/shared/dialect.rs:375`), the unit's position in the *grid* modulo 32.
That is the lane only where every cube starts a warp. With 100-unit cubes the lanes of every cube but the first are
shifted, and the old kernel then hangs (a partly filled warp with no unit that believes it is lane 0 never advances
the counter; `raw/box/logs/repro_cuda.log`, killed after 10 min at cubes=3, wg=100). The fixed kernel hangs the same
way there (`fix_partial_cuda_1.log`, generated source in `raw/box/logs/dbg/F1_wg100_cuda_source.log`). So on CUDA a
partly filled warp is only well-defined in cube 0; the tests launch one cube there. Production's cubes are 256 units,
a multiple of 32 and 64, where the lowering is right.

**lavapipe [M] (`repro_lvp.log`):** 0 of 218,772 skipped at 256, 100 and 48 units, so it is not a reproduction on
lavapipe. (Corrected in §7: my reading that llvmpipe runs the last subgroup full was wrong. The fixed kernel's
smallest-take record shows takes of 4 lanes there, so the subgroup ops do see a partly filled plane. Why the old
kernel still got those entries checked was not investigated.)

## 2. The fix

`take_entries` (new, in `kernels`) replaces "lane 0 takes `PLANE_DIM`, lane i checks `cur + i`". The lanes that run a
take decide it among themselves; nothing depends on `PLANE_DIM` or on lane 0 existing:

- **Ballot form** (`ballot_append(plane_size_max)`, planes of at most 32 lanes; the same switch `top_slot` uses):
  `lanes = plane_ballot(true)[0]` is the set of lanes taking part. `rank = popcount(lanes & ((1 << lane) - 1))`,
  the leader is the lane with rank 0 (the lowest set bit), it does `fetch_add(popcount(lanes))`, and the value
  reaches the others by `plane_shuffle(got, lowest_set_bit(lanes))`.
- **Scan form** (wider planes): `rank = plane_exclusive_sum(1)`, `n = plane_sum(1)`, the rank-0 lane does
  `fetch_add(n)`, and the value reaches the others as `plane_sum(got)` (every other lane adds 0).
- The kernel keeps the prefetch (the next take before this entry's work); each lane's entry is `start + rank`.

**Complete for any population (argument) [R]:** a take's participants are exactly the lanes that execute its plane
ops together. Both forms give them distinct ranks `0..n-1` and one `fetch_add(n)`, so the counter is cut into
disjoint, consecutive ranges `[start, start+n)`, each handed out once with one lane per entry. A lane leaves the loop
only when its own take starts at or past `count`; so for any entry `j < count` the range containing it was started by a
take whose `start ≤ j < count`, and the lane of rank `j - start` in that take checks `j` (it is still in the loop,
`live = i < count`). Hence every `j < count` is checked exactly once, whatever the number of lanes per take, whether a
lane 0 exists, and even if a plane's lanes split between takes (each take is consistent among the lanes that run it;
the loop condition is uniform within a take). The one assumption, shared with the old kernel and with `top_slot` on
main, is that the lanes that run a take's ballot or scan also run its shuffle or sum together (they reconverge after
the leader's `if`).

**Per backend [R]:**

| op | CUDA (cubecl-cpp) | WGSL via naga (Vulkan, Metal, DX12) | SPIR-V (cubecl-spirv) | Metal (cubecl-cpp) | HIP |
|---|---|---|---|---|---|
| ballot | `__ballot_sync(-1, 1)`: inactive lanes' bits clear (documented) | `subgroupBallot`, active invocations; `vec4`, word 0 = lanes 0-31 | `OpGroupNonUniformBallot`, active | `simd_ballot`, active, cast to the low 32 bits | first word only (gap 5): ballot form only on wave32 |
| lane id | `AbsolutePos % 32`: right in production (256-unit cubes) and in cube 0 | `subgroup_invocation_id` | `SubgroupLocalInvocationId` | `simd_lane_id` | as CUDA, `% 64` |
| shuffle (new op here) | `__shfl_sync(-1, v, lead)`: lead is active, so defined | `subgroupShuffle`, dynamic id allowed (naga requires a constant only for `subgroupBroadcast`, `naga-29.0.4/src/valid/function.rs:745`) | `OpGroupNonUniformShuffle` (CubeCL adds the capability) | `simd_shuffle` | `__shfl` |
| scan form: exclusive sum, sum | shfl-up/xor over all 32 lanes: only on full warps; CUDA never takes this form in production (32 lanes) | over active invocations, any width to 128 | over active invocations | `simd_prefix_exclusive_sum`, `simd_sum`, active | butterfly over 64 lanes: needs full waves, which 256-unit cubes give |

`plane_shuffle` is new to the kernels. wgpu exposes subgroups only on devices with Vulkan's `SHUFFLE` and
`SHUFFLE_RELATIVE` subgroup operations (`wgpu-hal-29 src/vulkan/adapter.rs:876-886`), so every device the join already
runs on through wgpu has it; CUDA, Metal and HIP have it natively.

**64-lane planes:** a device reporting `plane_size_max` > 32 takes the scan form, which is defined over the active lanes
on Vulkan/SPIR-V/Metal for any width and holes, and on HIP needs full waves (256-unit cubes are four full wave64s). A
device that *misreports* 64-lane planes as 32 (gap 5's concern; only wgpu could, CUDA and Apple are 32) would run the
ballot form wrongly: lanes 32-63 are outside word 0, and WGSL masks the shift `1 << lane` to `lane mod 32`, so lane 32
also gets rank 0. Two leaders each take 32 entries, every lane starts from the lowest leader's range, and the second
range is never checked while the first is checked twice. The entry **count** then still matches (64 checks per 64
entries taken), which is why the host also compares the **index sum**: each such take is 32·32 = 1,024 short, and the
sum stays wrong unless a batch held a multiple of 2^22 such takes, while the largest list (2^26 entries) holds at most
2^20 [D]. So the field fails loudly. Not run (no such device). [R][D]

## 3. The host sees an incomplete check

The kernel counts its checked entries (`done`, per lane, one `fetch_add` per lane at the end) into `ran[STAGES+1]` and
their indices' sum mod 2^32 into `ran[STAGES+2]` (`RAN_WORDS = STAGES + 3`). `JoinDevice::ensure_checked` compares both
with the list: `min(checked, list_cap)` entries and `Σ_{i<listed} i mod 2^32`. It runs after `ensure_ran` in every
batch of `run_pass` (also batches that overflowed: their list's entries must still all be checked) and in
`run_partition` (the re-run path), and in the device tests that launch batches directly. The index sum makes "one entry
twice, one skipped" fail too; the count alone would pass that.

**On a mismatch:** an `anyhow` error, not `NotRun`: a device that runs every cube but skips entries is not helped by a
smaller layout, so it does not go to `refit`. The error propagates out of `run_field` (and out of `rerun_partition`,
whose `downcast::<NotRun>()` passes it through), so the field fails, the client exits non-zero and nothing is
submitted (audit §4) — never a field with fewer candidates.

**Tested [M]:** `check_skipped_entries` (in `check_all`, so on CUDA and every wgpu CI device) sets a test-only
`CHECK_SKIP_FIRST` mode bit (the kernel leaves entry 0 unchecked and uncounted) and runs b10 [47,100) and the first
window (b20) through `run_field` and through `run_partition`: both must be errors containing "the check kernel
checked"; then the same fields run again and must equal the first run. CUDA: `overlap join b20: the check kernel
checked 138 of the 139 survivors the join listed (139 found, room for 67108864; index sum Some(9591), want 9591)`.

## 4. Exactness

All on the pushed commit's tree (box tree `58fc38fa` = ivory `8d11e0be`, same tree `0a4165c9`), binaries F3
(`--features gpu`: CUDA + wgpu/WGSL) and FS (`--features gpu,cubecl-spirv`). [M] unless marked.

| run | device | result | log |
|---|---|---|---|
| repro (bc9d87c7 + test-only patch), CUDA one cube | RTX 3080 | **FAILS**: 34,296 of 218,772 entries never checked | `repro_cuda2.log` |
| `cubecl_cuda_check_takes_every_entry_on_partly_filled_warps` (same lists, cubes of 100/48/256, ballot form) | RTX 3080 | ok, 84 runs over 7 shapes (24,308 synthetic n) | `F3_cubecl_cuda_check_takes_every_entry_on_partly_filled_warps.log` (also F2) |
| `cubecl_check_takes_every_entry_on_partly_filled_planes` (both forms, cubes 100/48/256, 1/3/2048 cubes) | lavapipe WGSL / SPIR-V | ok, 168 runs over 7 shapes, forms ballot + scan, each | `lvp_F3.log`, `lvp_FS.log` |
| `cubecl_cuda_check_counts_match_the_cpu` (count, gated, probe; groups 256-ballot, 100-ballot (1 cube), 256-scan) | RTX 3080 | ok: 64 lists, 1,168,717 list entries, 84,652 synthetic n, 22 shapes, 3,047 past the gate (= the PR's totals) | `F3_cubecl_cuda_check_counts_match_the_cpu.log` |
| `cubecl_check_counts_match_the_cpu` (groups 256 and 100, ballot) | lavapipe WGSL / SPIR-V | ok: 65 lists, same entry totals | `lvp_F3.log`, `lvp_FS.log` |
| `cubecl_cuda_join_matches_the_cpu_reference` (incl. b10's 69, windows, refused layouts, slices, production shape, **skipped-entry test**) | RTX 3080 | ok | `F3_cubecl_cuda_join_matches_the_cpu_reference.log` |
| every wgpu test of `cubecl_join` (10: check counts, partial planes, CPU reference incl. skipped-entry test, ticket, certificates, FD vs top, production sample; three opt-in ones skip) | lavapipe WGSL / SPIR-V | 10 passed each (236 s / 392 s) | `lvp_F3.log`, `lvp_FS.log` |
| `cubecl_cuda_top_fd_matches_the_top_kernel` | RTX 3080 | ok (347 s) | `F3_cubecl_cuda_top_fd_matches_the_top_kernel.log` |
| dense compare vs CPU join, b60 1e16 (`1447429612114824200908`), 8 partitions of slice 0 | RTX 3080 | ok: 333,861,119 / 22,369,705 | `F3_dense_b60.log` |
| dense compare, b62 1e17 (`7520566762397899821056`), 8 partitions | RTX 3080 | ok: 170,247,827 / 10,384,896 | `F3_dense_b62.log` |
| dense compare, b64 1e17 (`58557331862957161709568`), 8 partitions | RTX 3080 | ok: 697,596,881 / 43,247,716 | `F3_dense_b64.log` |
| host tests, CI's command `cargo test --release -p nice_common --features gpu --lib` | box CPU | 252 passed, 58 ignored | `host_tests_F3.log` |
| `cargo fmt --all --check`; `cargo clippy -p "*" --all-targets -- -D warnings`; same with `--features nice_client/gpu,nice_client/cubecl-spirv` (`just lint`), rustc 1.99.1 | box | clean | `raw/box/out/lint_F3.log` |
| CI's WGSL lint (`wgsl_dump_for_lint` on lavapipe + `scripts/wgsl-lint.py` with the workflow's requires) | lavapipe | 14 shaders, 0 flagged | `wgsl_lint_F3.log` |
| every timed field (§5): survivors / checked / found identical across B, F3, M in every round | RTX 3080 | identical | §5 |

Not run: `cargo test` for the whole workspace (CI's `test-workspace`; the change touches only `nice_common`'s
`cubecl_join.rs`, whose host tests ran), Metal/HIP (no device).

## 5. Speed (CUDA, RTX 3080 at 180 W)

Method [M]: binaries B = `bc9d87c7` (the PR head), F3 = the fix (`8d11e0be`'s tree), M = upstream main `a7a59c11`,
each built in its own tree and target dir before any timing (`raw/scripts/build.sh`). Harness
`cubecl_cuda_join_throughput_fixed_fields`, one untimed 1e14 warm-up field per process, then b62 1e17 at
`7520566762397899821056` (1 field), b64 1e17 at `58557331862957161709568` (1 field), b60 1e16 at
`1447429612114824200908` (2 fields, both in flight). Rounds 1-3 interleaved with the order rotated (B F3 M / F3 M B /
M B F3, `chain.sh`); b62 rounds 4-6 added (`chain4.sh`, `chain56.sh`: F3 B M, F3 B, B F3) because two F3 processes had
compiled the join kernel's spill variant. Before every run the card cooled to ≤ 40 °C (`cool.sh`); nothing else ran on
the box (lavapipe and dense tests ran after round 3 and before round 4). Per process: nvidia-smi every 1 s (`.smi`),
mean SM clock and median power over ≥ 90 % utilisation samples; every process's CubeCL PTX cache replayed through the
driver's JIT (`ptxjit.py`, `raw/box/out/ptxjit.out`) for registers and spills. "device" = `device=` (mean
`run_field` device seconds per field). All 42 processes: survivors / checked / found identical per field across B, F3
and M (b62 1,097,114,812,011 / 66,862,268,894 / 0; b64 3,092,989,872,066 / 191,683,594,021 / 0; b60 two fields
300,577,278,826 / 20,147,700,650 / 0). Power 179.5-179.9 W median in every run (the 180 W cap).

**Join kernel register variant:** the driver JIT gives the (unchanged) join kernel 46-48 registers, or in some processes
a 40-register variant with 24 bytes of spills. That happened in 3 of 42 processes, on both sides (b62_F3_r3,
b62_F3_r4, b62_B_r5), and each cost ≈ 2.4 % of the field (73.75-73.81 s against 71.4-72.3 s). Like L53, the table
uses the spill-free processes. The all-process numbers are given too.

| field | B = bc9d87c7 s/field (spill-free rounds) | F3 = fix | M = main a7a59c11 | fix vs B (median) | fix vs main |
|---|---|---|---|---|---|
| **b62 1e17** | **71.965** (71.386, 71.965, 72.312, 71.896, 72.074) | **72.030** (71.948, 72.175, 72.041, 72.019) | 78.089 (78.048, 77.784, 78.130, 78.264) | **+0.09 %** (all 6+6 processes: 72.019 vs 72.108, +0.12 %) | ×1.084 |
| **b60 1e16** (2 fields) | **9.197** (9.197, 9.259, 9.185) | **9.216** (9.216, 9.219, 9.190) | 10.082 (10.051, 10.111, 10.082) | **+0.21 %** | ×1.094 |
| **b64 1e17** | **149.730** (149.835, 149.191, 149.730) | **149.393** (149.271, 149.554, 149.393) | 158.327 (158.327, 161.789, 158.118) | **−0.23 %** | ×1.060 |

Per round (B / F3, > 1 = fix faster), time and cycles (s × mean MHz) [D]: b62 0.992, 0.997, (0.980 spill F3), (0.974
spill F3), (1.024 spill B), 1.001; cycles 0.994, 1.006, 0.987, 0.981, 1.000, 1.006. b60 0.998, 1.004, 0.999; cycles
0.997, 1.008, 1.004. b64 1.004, 0.998, 1.002; cycles 0.999, 0.997, 1.000. Mean SM clock per side: b62 1423 / 1422 MHz,
b60 1476 / 1472, b64 1443 / 1447.

**Cost of the fix: ≤ 0.2 % of a field, within the rounds' spread (±0.5 %) [M]; well under the 2 % bar.** The check
kernel's registers rose from 39 to **47** at b62 and from 40 to 47 at b64 (39 → 39 at b60) [M, ptxjit]: the take's
loop-carried state (rank, the next take, the count and the index sum). The PR body had measured that 47 registers
(5 cubes per SM instead of 6) cost about 7 % of the *check* in its 1-vs-4-entries experiment. Here it does not show at
the field level. The check is a small part of the field and waits on memory. It may matter on other GPUs; it was not
tried to bring it back to 39.

## 6. Not done / caveats

- **No real device reproduced the loss on its own.** The CUDA reproduction needs a test-only cube size, and lavapipe
  runs a cube's last plane full. The defect stays theoretical for production. The fix and the host check make it
  impossible to pass silently either way.
- **A CubeCL CUDA/HIP lowering bug found on the way [R][M]:** `UNIT_POS_PLANE = AbsolutePos % PLANE_DIM`
  (`cubecl-cpp-0.10.0`, `shared/dialect.rs:375`). It is wrong whenever a cube's unit count is not a multiple of the
  plane width, in every cube but the first. Both the old and the new check kernel hang on CUDA with 100-unit cubes
  beyond cube 0 (killed; logs kept). It does not affect production (256-unit cubes) and is worth an upstream issue
  to CubeCL. Metal uses `simd_lane_id` and WGSL/SPIR-V the subgroup invocation id, which are right.
- **Related, not fixed here (main, production) [R]:** `top_slot` (the FD kernel's append, upstream main) has the
  same kind of assumption. It broadcasts lane 0's `a0`, and only lane 0 takes the atomic. On a Vulkan plane that has
  no lane 0 the broadcast reads an inactive lane, and the kept tops' slots are garbage. That means overwritten tops,
  so lost candidates. Partly filled planes with full counts are fine there (ballot and scan over active lanes), but
  "no lane 0" is not. Nothing in the new host count covers the top stage. Worth a follow-up with the same leader
  election (`lowest set bit` + `plane_shuffle`). This is a delivery item for T2 (gap 2's sibling).
- The check kernel uses 47 registers at b62/b64 (was 39/40), see §5. It is not measurable on the 3080 and was not
  measured elsewhere.
- Not run: the scan form on a real 64-lane device (RDNA/RADV, HIP wave64), Metal, HIP. The scan form ran on lavapipe
  (WGSL and SPIR-V) and with full warps on CUDA. The misreported-width case (§2) is argued, not run.
- CUDA scan form on partly filled warps is undefined (CubeCL lowers the sums over all 32 lanes); CUDA never selects
  it (32-lane warps → ballot form).
- Whole-workspace `cargo test` (CI `test-workspace`) not run. The commit touches only `common/src/cubecl_join.rs`.
- The PR body still says the check has 39-40 registers ("Code" and "Registers" paragraphs). The delta corrects that
  (47 at b62/b64).

## 7. Review fixes (2026-11-13, afternoon): commit `1f41d649`

The independent review (`REVIEW.md`) found the hand-out complete and the host check sound. Fixed here: F1, F2 and F4.
Box 60499346 (RTX 3080, 260 W cap, 16 threads). An earlier box (60478814) expired before its logs were copied; its
results, on a binary byte-identical to an intermediate state (md5 66b63094), are transcribed in
`raw/box2/lost-box-60478814-summary.txt`. Logs: `raw/box2/logs/`, scripts `raw/box2/scripts/`, identity check
`raw/box2/ident-summary.txt`.

**What was added (tests only; production behaviour unchanged):**
- **F1, host unit test:** `check_complete` is now a free function of `(done, sum, checked, list_cap)`. `ensure_checked`
  calls it and adds the base to the message. Count errors and sum errors have distinct messages. The unit test
  `check_complete_wants_every_listed_entry_once` covers:
  - an exact count and sum;
  - an overflowed list (`listed = list_cap`);
  - one entry skipped (fails on the count);
  - one entry checked twice in place of another (count right, fails on the sum);
  - missing words;
  - the sum past its wrap (100,000 entries → 704,982,704 = 4,999,950,000 − 2^32);
  - the largest list, 2^26 entries, summed with wrapping u32 as the device sums it, and that sum minus 1.
- **F1, device test:** a second test-only mode bit, `CHECK_DUP_FIRST`. The lane whose entry is index 1 checks and
  counts index 0, so the count is right and the sum is short by 1. `check_skipped_entries` now runs both bits; each
  must fail `run_field` and the partition re-run with its own message.
  - b10's single survivor runs the skip mode only.
  - b20 runs both. Its dup error reads "the indices of the 139 survivors the check kernel checked sum to 9590
    (mod 2^32), not 9591".
- **F2:** a third test bit, `CHECK_MIN_TAKE`. Each take's leader `fetch_min`s its size into an extra `ran` word that
  only `run_check` allocates. `check_partial_planes` prints the smallest take per (form, cube size), and asserts it
  on CUDA (4 at 100 units, 16 at 48, 32 at 256).
  - **lavapipe shows takes of 4 lanes at 100 units**, so partly filled subgroups do run there. That corrects §1's
    inference.
- The test bits are comptime mode bits. `launch_batch` adds them only under `#[cfg(test)]`, from a thread-local.
  - The dup index is a comptime `if` *expression*. A first version used `let mut i`, which added a variable copy to
    the production kernel; the check below caught it.

**Production kernels byte-identical? Yes, up to CubeCL's own per-process noise [M]** (`raw/scripts/ident.sh`,
`kdiff.py`). Inputs:
- the full compilation log of a production run of 8d11e0be and of this head (the dense compare, one partition of
  b60 1e16, so `launch_batch` in hits mode);
- the WGSL of CI's `wgsl_dump_for_lint`.

Each kernel's compilation block was compared after renaming CubeCL's numbered variables in order of first use and
sorting the declarations.
- CUDA `check_kernel`, `bucket_kernel`, `top_kernel`, `top_fd_kernel` and `smoke_kernel`: identical.
- All 10 WGSL shader kinds (14 shaders): identical.
- CUDA `join_kernel` differs only in its shared-memory layout order. 8d11e0be against itself (two processes) differs
  the same way, so it is per-process nondeterminism in CubeCL, likely also behind the per-process spill variant of §5.
- The first version (with `let mut i`) showed as DIFFER in the CUDA and WGSL check kernel, so the comparison is
  sensitive.

**No speed runs needed.**

**Runs on `1f41d649`'s tree (`674ce759`) [M]:**

| run | result |
|---|---|
| CUDA `cubecl_cuda_check_takes_every_entry_on_partly_filled_warps` | ok, 84 runs; smallest take 4 / 16 / 32 at 100 / 48 / 256 |
| CUDA `cubecl_cuda_join_matches_the_cpu_reference` (incl. both test bits on both paths) | ok |
| CUDA `cubecl_cuda_check_counts_match_the_cpu` | ok, 64 lists, 1,168,717 entries, 84,652 synthetic n |
| lavapipe WGSL, all 10 wgpu tests of `cubecl_join` | 10 passed; smallest take 4 at 100 units (both forms), 8 at 48 and 256 |
| lavapipe SPIR-V (`gpu,cubecl-spirv`), same | 10 passed, same |
| host tests `cargo test --release -p nice_common --features gpu --lib` | 253 passed (one new) |
| `cargo fmt --all --check`; clippy `-D warnings` default and `nice_client/gpu,nice_client/cubecl-spirv` (1.99.1) | clean |

**Pushed:** `1f41d649` on fork `pr/check-d` (fast-forward `8d11e0be..1f41d649`).

**PR body:** `PR-BODY.md` is the complete replacement body, ready to paste. It is built by
`raw/scripts/make_pr_body.py` from `raw/pr251-body-before.md` and `PR-BODY-DELTA.md`. F4 is fixed:
- the register sentence uses 39–47 registers;
- at 47 registers (b62, b64) a cube needs 47 → 48 × 256 = 12,288 registers, so 5 cubes fit in 65,536 per SM: a
  3080 holds 5 × 68 = 340, an H100 5 × 132 = 660. The original 408/792 were 6 cubes per SM at ≤ 40 registers.
- the all-process b62 sentence now reads "72.108 s for this head against 72.019 s".

Not addressed: F3 (informational) and F6 (main's `top_slot` and niceonly stride queues: T2 follow-ups), as the review
recommends.
