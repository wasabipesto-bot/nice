# T26B: the stride walk's survivor queues without full-plane and lane-0 assumptions (2026-11-14)

Branch **`pr/stride-queue-any-plane`** (fork): one commit **`85fe64af`** on upstream main `41b4b405` (main re-checked
at push time, 17:01 UTC: still `41b4b405`), tree `c32dd701`. Patch: `raw/0001-stride-queue-any-plane.patch`.

Box: Vast 60665092, RTX 3080 10 GB, **power cap 130 W** (default 320 W; the host's setting, not changed), driver
580.159.03, CUDA 12.8, Xeon E5-2630 v4 (20 threads), lavapipe = llvmpipe (LLVM 20.1.2, 256 bits, 8-lane subgroups),
rustc 1.100.0 (main's pinned toolchain).
Labels: **[M]** measured here today, **[D]** derived from measured numbers, **[R]** read in source, **[A]** assumed.
Raw: `raw/box/logs/` (every run, `<name>.log`; timing runs also `.smi`, NiceMark `.json`), `raw/box/out/` (builds,
timing chain), `raw/scripts/` (all box scripts), `raw/repro/` (test-only patches: `make_repro.py` = main + cube-size
override + the new test; `add_harness.py` = a CUDA stride-pipeline timing harness, only in the timing binaries;
`add_knobs.py` = investigation knobs, only in binary FSX), `raw/model/` (host model).

Binaries (all built on the box, each tree in its own target dir; `raw/box/out/builds.txt`):

| label | tree | features | md5 | use |
|---|---|---|---|---|
| M / MS | main `41b4b405` | gpu / gpu,cubecl-spirv | aacdc4a6 / a15a47b8 | (identity check) |
| R / RS | main + `make_repro.py` (tests only) | gpu / gpu,cubecl-spirv | 7c6f7115 / 7eb1e31d | reproduction |
| RT | main + `make_repro.py` + `add_harness.py` | gpu | 5a0206c8 | timing (main side) |
| F2 / F2S | the commit's tree `c32dd701` (verified by `git write-tree` on the box) | gpu / gpu,cubecl-spirv | faf328f4 / c20692b7 | exactness |
| F / FS | an intermediate tree: the same kernel and tests, but the new wgpu tests also ran the plane-scoped queue on lavapipe | gpu / gpu,cubecl-spirv | ae0a8f77 / cd49db53 | first runs, lavapipe finding |
| FT | the commit + `add_harness.py` + `add_knobs.py` (tests only) | gpu | 63a6d17f | timing (fix side) |
| FSX | same as FT | gpu,cubecl-spirv | f971f20c | llvmpipe investigation |
| MC / FC | `nice_client --features gpu`, release: main / the commit | | fdef7d3d / c757c0bb | NiceMark |

## Summary

- **Reproduced [M]** on main with a test-only cube size, one cube: on the RTX 3080 both queues lose survivors on a
  partly filled warp (plane-scoped: the missing lanes' share of every `PLANE_DIM` take; cube-scoped: the whole
  partial plane, never counted); on lavapipe (WGSL and SPIR-V) the cube-scoped queue loses the same. Planes without
  lane 0, non-linear layouts and holes: host model (main wrong in 36-100 % of launches per population, the fix in none of 12,000).
- **Fixed by construction:** ranks, counts, takes and queue offsets come from ballots (≤ 32 lanes) or scans over the
  running lanes, reservations by each plane's lowest running lane; nothing reads `PLANE_DIM`, `PLANE_POS` or lane 0.
- **Host check built:** per-field account (queued − checked, count and low-word sum), field fails if nonzero; fault
  tests prove it fires.
- **Exact [M]:** new tests (CUDA 64 runs, lavapipe 32 + 32), every `cubecl_backend` device test on CUDA and lavapipe
  with both compilers, host tests, fmt, clippy; other kernels' generated code identical to main's.
- **Cost [M]:** CUDA is *faster*: ballot form ×1.14 (plane-scoped) / ×1.26 (cube-scoped) on b54 stride fields,
  NiceMark (stride forced) ×1.21 (four rounds; ×1.23 over six); the scan form (64-lane devices) +0.6 % (plane-scoped) / −1.8 % (cube-scoped). One
  NiceMark scenario (b58 msd-strong, CPU-bound) had one round of six at ×0.94, inside its 8 % spread (median ×1.02).
- **llvmpipe** still cannot run the plane-scoped queue, with or without the fix (its subgroup barrier); stays off there.

## 1. Reproduction

### 1.1 On devices [M]

Harness (test-only, on main; `raw/repro/make_repro.py`): `CubeclNiceonlyRun` gets a cube-size override (units per
cube, at most `WORKGROUP_SIZE` = 256 so the shared arrays fit), and `repro_*` runs main's unchanged `niceonly_kernel`
in probe mode (every checked survivor is reported) on a b50 window (400,000 numbers from the base's start, certificate
bits 3 and 45; no prefilter, so every survivor the queue checks is reported) and a b40 window (same length, bits 5 and
39, with the low-digit prefilter), cut into one range per unit or per 4 units, so that every unit has candidates and
the launch is **one cube**; the survivor set is compared with a host mirror (cross filter, then prefilter). Cubes of
256, 100, 48 and 36 units.

| queue (forced), device | cube 256 | cube 100 | cube 48 | cube 36 | log |
|---|---|---|---|---|---|
| plane-scoped, RTX 3080 (CUDA) | exact | **1,064** of 30,449 lost (b40: 13-15 of 283) | **5,072** (b40: 54-61) | **2,958** (b40: 32-33) | `repro_cuda.log` |
| cube-scoped, RTX 3080 (CUDA) | exact | **1,217** (b40: 17) | **10,152** (b40: 107) | **3,382** (b40: 36) | `repro_cuda.log` |
| cube-scoped, lavapipe WGSL (binary R) and SPIR-V (RS) | exact | **1,217** (b40: 17) | exact | **3,382** (b40: 36) | `repro_lvp.log`, `repro_lvp_spirv.log` |
| plane-scoped, lavapipe SPIR-V (RS) | 333-468 lost | 717-765 | 57-86 | 1,730-1,733 | `repro_lvp_spirv.log` (see 1.3) |

24 of 32 CUDA runs and 8 of 16 lavapipe-WGSL runs wrong; never a duplicate or a foreign number, only losses. Both
lane counts per range give the same losses (the queue sees the same survivors per iteration either way).

**What goes wrong, exactly [R][D]:**

- *Plane-scoped, cube of 48 on CUDA:* warp 1 holds units 32-47 (16 lanes). Its queue takes `PLANE_DIM` = 32 entries
  per wave once 32 are queued, but only lanes 0-15 exist to check slots `qn-32 .. qn-17`; slots `qn-16 .. qn-1` are
  dropped and `qn -= 32` forgets them. At the end (`done`, `qn < 32`) the take is `qn`, again checked only by 16 lanes.
  Half of that warp's survivors (≈ 10,150 / 2) are lost: 5,072 [M]. At cube 100 the last warp has 4 lanes (28 of every
  32 lost of its ~1,217); at 36, 4 lanes of the second warp (28/32 of its ~3,380: 2,958 [M]).
- *Cube-scoped, cube of 100:* `num_planes = CUBE_DIM_X / PLANE_DIM` = 100/32 = 3 on CUDA (100/8 = 12 on lavapipe), so
  the last, partly filled plane's total is never added: its survivors are written past the queue's count and
  overwritten by the next iteration. Its whole share is lost: 4 of 100 units, 1,217 of 30,449 [M]; at 48 on CUDA, the
  16-lane warp's third: 10,152 [M]; at 36, 4 of 36 units: 3,382 [M]. On lavapipe 48 = 6 full subgroups, so 48 is exact
  there, and 100 and 36 lose exactly what CUDA loses.

**Smallest test-only launches that show each variant [M]:** plane-scoped: one cube of 36 units on CUDA (1 full warp +
4 lanes), 2,958 lost; cube-scoped: one cube of 36 units on CUDA or lavapipe (both compilers), 3,382 lost. Any cube
size that is not a multiple of the plane width shows both on CUDA.

**What CubeCL's CUDA lowering limits [R]:** `UNIT_POS_PLANE = AbsolutePos % PLANE_DIM`
(`cubecl-cpp-0.10.0/src/shared/dialect.rs:375`), the unit's position in the grid modulo 32. It is the lane only where
every cube starts a warp, so on CUDA a partly filled warp is only well-defined in a grid's first cube: every test here
launches one cube. `PLANE_POS` is `UNIT_POS_X / PLANE_DIM` there, and a partly filled warp is always lanes `0..r-1` of a
cube's last warp, so CUDA can show "partly filled", never "no lane 0" or "not linear in `UNIT_POS_X`": CUDA's plane
ops are `__*_sync(0xffffffff, ..)`, and a lane that sits out by divergence makes them undefined (T26 saw a hang). Those
two cases are shown by the host model (1.2).

### 1.2 Host model [M]

`raw/model/queue_model.py` (`queue_model.out`, summed in `queue_model_summary.txt`): both queues of main and of the fix,
lane by lane, over shared slots; populations: full and linear (control), partly filled last plane, full planes not
linear in `UNIT_POS_X`, planes without lane 0, and random holes with random sizes and layouts; widths 8, 32 and 64;
random survivor streams and range lengths; seeds 7, 1, 2, 200 rounds each (600 launches per population and queue).

| population | plane main | plane fix | cube main | cube fix |
|---|---|---|---|---|
| full, linear | 0 wrong | 0 | 0 | 0 |
| partly filled last plane | 217 of 600 wrong, 4,102 of 79,736 lost | **0** | 445 wrong, 7,680 lost | **0** |
| full, not linear in `UNIT_POS_X` | 599 wrong, 65,495 lost, 65,305 checked twice | **0** | 600 wrong, 139,694 lost | **0** |
| no lane 0 | 386 wrong, 9,318 lost | **0** | 600 wrong (the loop never sees every plane done: hangs, model cut-off) | **0** |
| holes, random sizes and layout | 591 wrong, 66,887 lost, 25,284 slot writes out of bounds | **0** | 595 wrong, 90,202 lost | **0** |

(Main's plane-scoped queue at `PLANE_POS * 2 * PLANE_DIM` writes out of the cube's `2 * 256` slots when a cube holds
more planes than `256 / PLANE_DIM`: in shared memory that would overwrite the digit scratch.)

### 1.3 lavapipe and the plane-scoped queue [M]

The plane-scoped queue is off on software rasterizers in production (`is_software_rasterizer`); main's comment says
llvmpipe "mishandles a subgroup-scope control barrier inside plane-divergent control flow". Measured here
(SPIR-V, binaries RS = main and FS/FSX = the fix, forced on):

- With **full** subgroups (cubes of 256 and 48), main and the fix lose **the same** survivors (b50: 333 / 468 / 57 / 86;
  b40: 2), so the loss is not the queue's arithmetic. With partly filled ones main loses more (cube 100: 717-765,
  cube 36: 1,730) and the fix the same small residue as with full ones (113-157, 40-43): the fix removes the
  partial-plane share and leaves llvmpipe's.
- With **one subgroup per cube** (cube of 8 units) the fix's plane-scoped queue is **exact** on llvmpipe; with 2, 3, 4
  or 32 subgroups it loses survivors (cube 16: 2-18, 24: 17, 32: 15-90, 256: 333-468) (`FSX_lvp_plane_d*.log`).
- The fix's account did not catch it there (the skip fault went unnoticed with the plane-scoped queue on lavapipe,
  `FS_lvp_faults.log`) [M]; presumably because the account's last step is a cube barrier after the loop, which
  llvmpipe would then not honour either while other subgroups sit at subgroup barriers [A].

So llvmpipe's subgroup barrier interacts across subgroups (consistent with llvmpipe running a workgroup's subgroups as
coroutines and lowering a subgroup-scope barrier like a workgroup one, so subgroups at different barriers release each
other [A: mechanism inferred, not traced in Mesa]). The fix does not change that; the plane-scoped queue stays off on
software rasterizers, and the new tests skip it there (they print so).

## 2. The fix (commit `85fe64af`, `common/src/cubecl_backend.rs` and one CHANGELOG line)

Everything about positions, counts and takes now comes from the lanes that execute the plane operation; nothing
reads `PLANE_DIM`, `PLANE_POS`, `UNIT_POS_X % PLANE_DIM`, `UNIT_POS_X / PLANE_DIM` or `CUBE_DIM_X / PLANE_DIM`, and no
step needs a lane 0. Two rank forms, chosen per device by `ballot_append(plane_size_max)` (main's switch for
`top_slot`, `cubecl_join.rs`: planes of at most 32 lanes):

- **ballot form:** `bp = plane_ballot(pf)[0]`, `bl = plane_ballot(true)[0]`, `lt = (1 << UNIT_POS_PLANE) - 1`:
  position `popcount(bp & lt)`, survivors `popcount(bp)`, rank `popcount(bl & lt)`, lanes `popcount(bl)`, lowest
  running lane `ctz(bl)` (as `(bl ^ (bl-1)).count_ones() - 1`, #260's spelling);
- **scan form:** one `plane_exclusive_sum` and one `plane_sum` of a packed word (plane-scoped: `pf | 1 << 16`;
  cube-scoped: `pf | have_range << 10 | 1 << 20`), the same number of plane operations as main.

**Plane-scoped queue** (CUDA, `cubecl-spirv`):
- Once, after one cube barrier at kernel start: each plane's lowest running lane takes `2n` slots (`n` = its running
  lanes) from a shared counter with one `fetch_add`; the base reaches the plane by `plane_shuffle(got, ctz(bl))`
  (ballot form) or `plane_sum(got)` (scan form: only rank 0's term is nonzero). The reservations are disjoint and
  sum to `2 * CUBE_DIM_X <= 2 * WORKGROUP_SIZE` slots however the cube is cut into planes (main's
  `PLANE_POS * 2 * PLANE_DIM` overflows the array as soon as a cube has more than `256 / PLANE_DIM` planes).
- Per iteration: survivors go to `qbase + qn + position`; a wave takes `n` entries if `qn >= n`, else `qn` once the
  plane is done; the lane of rank `r < take` checks slot `qbase + qn - take + r`. Control flow stays plane-uniform
  (`qn` from the plane's counts, `done` from `plane_all`), with main's two `sync_plane`s.

**Cube-scoped queue** (WGSL, and any device without plane barriers):
- Per iteration, after barrier 1: each plane's lowest running lane adds `survivors | lanes_with_ranges << 10` to a shared
  word with one `fetch_add`; the old value (the planes before it in this iteration) reaches the plane by `plane_shuffle`
  or `plane_sum`; survivors go to `qn + offset + position`. After barrier 2 every unit reads the word: `incoming` = its
  low field, `all_done` = its lanes field is zero. The word alternates between `q_acct[0]` and `q_acct[1]`; unit 0
  (always present: `UNIT_POS_X == 0` is a cube unit, not a plane lane) clears the other one after barrier 2. Ordering:
  word `w` of iteration `i` is read after barrier 2 of `i`, cleared by unit 0 after barrier 2 of `i+1`, and added to
  again after barrier 1 of `i+2`; each step is separated from the next by a barrier.
- The drain is main's (`CUBE_DIM_X` and `UNIT_POS_X` are cube quantities, exact); the serial walk over plane totals and
  the two plane-indexed shared arrays (2 KB) are gone.

**Is the cube-scoped change separate?** It is the same defect class in the same kernel with the same remedy and shares
the account, so it is in the same commit; split, either half alone would leave the stride walk's account half-built.

### Completeness, for every plane population [R]

Let `P` be the lanes that execute one dynamic instance of the rank step, `n = |P|`.
1. Ranks: in the ballot form, `bl` holds exactly `P`'s bits (inactive lanes' bits are clear on every backend, table
   below), so `popcount(bl & lt)` is a bijection `P -> 0..n` for planes of at most 32 lanes; the same holds for
   `popcount(bp & lt)` on `P`'s survivors. In the scan form, exclusive sum and sum run over the active lanes (fields
   do not carry: a plane has at most 128 lanes, < 2^10). So positions are distinct in `0..tot` and ranks in `0..n`.
2. Exactly one lane of `P` has rank 0, and in the ballot form it is `ctz(bl)`, a lane of `P`, so the shuffle reads an
   active lane; in the scan form the broadcast is a sum with one nonzero term.
3. Plane-scoped: the queue holds `qn < n` entries at the top of every iteration (initially 0; a full wave leaves
   `qn - n <= n - 1`), so `qn + tot <= 2n - 1` fits the `2n` reserved slots. A wave checks entries
   `qn - take .. qn - 1`, one per rank `< take`, then forgets exactly those; the loop ends only when `done` and `qn = 0`.
   So every queued entry is checked exactly once.
4. Cube-scoped: the planes' `fetch_add`s cut `[0, incoming)` into disjoint ranges, one per plane, each as long as that
   plane's survivors, so the iteration's survivors fill `qn .. qn + incoming` without collision; the drain is
   main's cube-uniform wave over `CUBE_DIM_X` units. `all_done` is true only when no running lane has a range left.
Nothing depends on `PLANE_DIM`, on lane 0, on the lanes being consecutive in `UNIT_POS_X`, or on how many planes a cube
has. **Remaining assumptions** (the same as main's `top_slot` and #251's `take_entries`): the lanes that run a ballot or
scan also run the shuffle or sum after the leader's `if` (reconvergence); the set of running lanes of a plane does not
change between the reservation and the end of the loop (it is the same set under plane-uniform control flow);
`UNIT_POS_PLANE` is the lane's ballot bit (CubeCL's CUDA/HIP lowering is right in cubes that are whole warps, true in
production).

### Per backend [R] (cubecl 0.10.0 sources, as CKF and T26 read them; `plane_shuffle` with a dynamic lane is new on main)

| op | CUDA (cubecl-cpp) | HIP | Metal (cubecl-cpp MSL) | WGSL (naga: Vulkan, Metal, DX12) | SPIR-V (cubecl-spirv) |
|---|---|---|---|---|---|
| ballot | `__ballot_sync(-1, x)`: inactive lanes' bits clear | `__ballot`, first 32 bits (ballot form only on wave32) | `simd_ballot`, low 32 bits | `subgroupBallot`, word 0 | `OpGroupNonUniformBallot` |
| shuffle | `__shfl_sync(-1, v, src)` | `__shfl` | `simd_shuffle` | `subgroupShuffle` (dynamic id allowed) | `OpGroupNonUniformShuffle` |
| sum / exclusive sum | butterfly / shfl-up over all 32 lanes | same over 64 | `simd_sum`, `simd_prefix_exclusive_sum` | `subgroupAdd`, `subgroupExclusiveAdd` | `OpGroupNonUniformIAdd` |
| lane id | `AbsolutePos % 32` | `AbsolutePos % 64` | `simd_lane_id` | `subgroup_invocation_id` | `SubgroupLocalInvocationId` |

- CUDA (32 lanes) takes the ballot form; production cubes are 256 units = 8 full warps. On partly filled warps in one
  cube both forms ran exact here (the scan form's butterflies read missing lanes, which CUDA leaves undefined; it is
  never selected there).
- 64-lane planes (RADV wave64, HIP wave64, Metal on AMD) take the scan form, defined over the active lanes on
  WGSL/SPIR-V/Metal for any population; HIP's butterflies need full waves, which 256-unit cubes give.
- A 64-lane plane misreported as 32 lanes (`plane_size_max`) would take the ballot form wrongly (as `top_slot` on main
  would); the account below then fails the field unless count and low-word sum both happen to balance.
- `plane_shuffle` reaches the kernels through wgpu only on devices with Vulkan's SHUFFLE subgroup feature, which wgpu
  requires before it exposes subgroups at all (CKF, `wgpu-hal-29 src/vulkan/adapter.rs:876-886`).

## 3. The host check (the account) [M]

Cheap, so built. Each lane keeps two registers: survivors it queued minus survivors it checked, and the same for the
survivors' low 32 bits (mod 2^32). After the queue loop the cube adds them in shared memory (`q_acct[2..4]`, one shared
atomic per nonzero lane), one cube barrier, and unit 0 adds the cube's two words to `nice_count[1..3]` **only if they
are not zero**, so a correct launch writes nothing more to global memory. The count buffer grows from 1 to 3 words;
`read_niceonly_hits` (the one read of a field's hits, production and tests) calls `queue_complete`, which requires both
words to be zero and otherwise returns an error, the same path as the existing output-overflow error: the field fails
and nothing is reported for it. It is per field (the words accumulate over the field's launches), not per launch:
reading per launch would add a device sync per batch.

Tested [M]: `queue_faults` (CUDA: `cubecl_cuda_queue_faults_fail_the_field`; wgpu: `cubecl_queue_faults_fail_the_field`)
runs b50 with two test-only comptime bits (`test_bits`, 0 in production): `QUEUE_SKIP_FIRST` (the entry at a queue's
first slot is neither checked nor counted) and `QUEUE_DUP_FIRST` (the lane reading the second slot checks the first);
each must fail `finish()` with its message, then the field runs clean. CUDA: "stride walk b50: the survivor queues
checked 41 fewer survivors than they queued" (plane-scoped), "6 fewer" (cube-scoped), "... (low words differ by 439835
mod 2^32)" / "by 248052" for the duplicate. Host unit test `queue_complete_wants_every_queued_survivor_once`.
What it cannot see: a multiset of checked survivors with the same size and low-word sum as the queued one (two
coinciding errors), and llvmpipe's plane-scoped path (1.3), which production never runs.

## 4. Exactness

### 4.1 Runs (binaries F2 / F2S = the commit's tree, unless marked) [M]

| run | device | result | log |
|---|---|---|---|
| **new** `cubecl_cuda_queues_check_every_survivor_on_partly_filled_warps` (b50 + b40 windows vs host mirror, one cube of 256/100/48/36, 1 and 4 lanes per range, both queues; with `NICE_TEST_QUEUE_SCAN=1` both rank forms) | RTX 3080 | **64 runs, 0 wrong**, account zero in every run (main, same harness: **24 of 32 wrong**, §1) | `F2_cuda_partial.log`, `F2_suite_*partly_filled_warps.log` (ballot form only, 32 runs) |
| **new** `cubecl_queues_check_every_survivor_on_partly_filled_planes` (same, cube-scoped queue, ballot and scan forms; the plane-scoped queue is skipped on software rasterizers) | lavapipe WGSL (F2) / SPIR-V (F2S) | **32 runs, 0 wrong** each (main: 8 of 16 wrong on each compiler) | `F2_lvp_partial.log`, `F2S_lvp_partial.log` |
| **new** `cubecl_cuda_queue_faults_fail_the_field` / `cubecl_queue_faults_fail_the_field` (§3) | RTX 3080; lavapipe WGSL and SPIR-V | ok: each fault fails the field with its message, then the field runs clean | `F2_cuda_faults.log`, `F2_lvp_faults.log`, `F2S_lvp_faults.log` |
| every ignored test of `cubecl_backend` (CUDA: 6; wgpu: 11, incl. CPU parity `cubecl_matches_cpu_niceonly` / `cubecl_cuda_matches_cpu_niceonly` at b10-b80, `finds_69`, cross-filter and prefilter survivor mirrors, near-miss read-back, detailed parity), each in its own process | RTX 3080; lavapipe WGSL and SPIR-V | all pass | `F2_suite_*.log`, `F2S_suite_*.log`, `raw/box/out/suite_*.out` |
| production-scale account: 3 × 40 b54 fields of 1e13 (4e14 numbers per run) and 6 NiceMark runs (b58/b60/b62 stride windows, 28-7,036 repetitions each) through `begin_niceonly`/`finish` | RTX 3080 (FT, FC) | no account error in any field (an error fails the harness's `finish().unwrap()` and NiceMark's scenario); hits equal main's (0) | `s54_F_r*.log`, `nm_F_r*.json` |
| the same with the cube-scoped queue and with the scan form forced (§5) | RTX 3080 (FT2) | no account error | `s54scan_*`, `c54_*` |
| host tests: CI's `cargo test --release -p nice_common --features gpu --lib` (incl. `queue_complete_wants_every_queued_survivor_once`) | box CPU | **248 passed**, 57 ignored, 0 failed | `F2_host_tests.log` |
| `cargo fmt --all --check`; `cargo clippy -p nice_common --all-targets --features gpu,cubecl-spirv -- -D warnings`; `cargo clippy -p "*" --all-targets -- -D warnings` and with `--features nice_client/gpu,nice_client/cubecl-spirv` (`just lint`), rustc 1.100.0 | box | **clean** (fmt; all three clippy runs; the only warning is the existing `web-sys` manifest note of `nice-wasm-client`) | `raw/box/out/lint_F2.log` |
| the same clippy (`nice_common`, gpu,cubecl-spirv, `-D warnings`) on ivory before each push | ivory | clean | |

Intermediate binaries F/FS (same kernel, wgpu tests then also forcing the plane-scoped queue on lavapipe): CUDA 64
runs exact, lavapipe WGSL 32 exact, CUDA suite pass (`F_*`, `FS_*` logs); FS's lavapipe plane-scoped runs are §1.3.

Not run: whole-workspace `cargo test` (the commit touches `common/src/cubecl_backend.rs` and `CHANGELOG.md`); Metal,
HIP, RADV or any 64-lane device (none available; the scan form ran on lavapipe's 8-lane subgroups and on CUDA, partly
filled warps included); CI's WGSL lint script (`scripts/wgsl-lint.py`) — the lint shaders are identical to main's (4.2).

### 4.2 Generated kernels other than `niceonly_kernel`'s queues: identical to main's [M]

`raw/scripts/ident.sh` (`raw/ident_summary.txt`; data on the box in `/root/t26b/ident/`): CubeCL's full compilation log
of a production CUDA run (the dense CPU-join comparison on one partition of b60 1e16) and CI's `wgsl_dump_for_lint` on
lavapipe, for M (main) and F2, compared per kernel after renaming CubeCL's numbered locals and shared arrays in order of
first use and sorting declarations (`kdiff.py`, `wdiff.py`). CUDA: `bucket_kernel`, `check_kernel`, `join_kernel`,
`smoke_kernel`, `top_fd_kernel`, `top_kernel` identical. WGSL (14 shaders): `bucket`, `check`, `detailed_fd` (4),
`detailed_fd_u32` (2), `detailed`, `detailed_u32`, `join`, `niceonly_kernel` (the lint's variant is the uncompacted
walk, whose code is unchanged), `top_fd`, `top` identical. Not compared: CUDA's detailed kernels (source untouched)
and the compacted `niceonly_kernel` variants, which are the change.

## 5. Cost (CUDA, RTX 3080 at the host's 130 W cap)

**Method [M].** Binaries RT (main + test-only harness) and FT (the commit + the same harness + test-only knobs), MC and
FC (release `nice_client`), each built in its own tree and target dir before any timing; nothing else ran on the box
during the chains (`raw/box/out/timing.out`, `timing2.out`; `TIMING START ... builds running: 0`), card back to ≤ 40 °C
before every run (`cool.sh`; this card idles at 34-35 °C), nvidia-smi every second (`.smi`), power cap 130 W in every
run (the box's setting; default 320 W), SM clock and power taken over samples with utilization ≥ 30 % (`analyze.py`,
`raw/box/out/analyze.out`).

- **Stride harness** (`add_harness.py`, `cubecl_cuda_stride_throughput_fixed_fields`): `NICE_JOIN_ROUTE=stride`, b54,
  40 consecutive 1e13 fields from `2778136280153679229` (the field of the stride pipeline's own throughput harness;
  b54 fields took the stride walk in production before the join), through `begin_niceonly` / `finish` as the client
  runs them (MSD filter on 20 CPU threads, CubeCL CUDA, plane-scoped queue, production plan: ballot form on CUDA),
  after one untimed warm-up of 1e12. Rounds M F / F M / M F.
- **NiceMark** (`nice_client --benchmark --benchmark-json --benchmark-secs 60 niceonly --gpu --gpu-backend cubecl-cuda
  --threads 20`, API base a closed local port, `NICE_JOIN_ROUTE=stride`): its four nice-only GPU scenarios then time
  their stride windows (1e12 at the start of each field: b58 msd-weak, b58 msd-strong, b60 msd-weak, b62 msd-weak).
  Rounds M F / F M / M F / F M, then 5-6 (M F / F M).

**b54 stride fields (40 × 1e13) [M]:**

| round | main s | fix s | main / fix | main SM MHz, util | fix SM MHz, util |
|---|---|---|---|---|---|
| 1 (M F) | 80.276 | 73.441 | 1.093 | 1159, 82 % | 1393, 60 % |
| 2 (F M) | 83.861 | 73.583 | 1.140 | 1132, 81 % | 1380, 59 % |
| 3 (M F) | 84.342 | 74.228 | 1.136 | 1123, 82 % | 1415, 58 % |
| median | 83.861 | 73.583 | **×1.140 (−12.3 % time)** | | |

Power 129.6-130.0 W median in every run (at the cap); found 0 in every run (both sides).

**NiceMark, stride forced [M]** (score and per-scenario rate, fix / main per round):

| round | main score | fix score | score | b58 msd-weak | b58 msd-strong | b60 msd-weak | b62 msd-weak |
|---|---|---|---|---|---|---|---|
| 1 (M F) | 94.13 | 118.69 | ×1.261 | ×1.451 | ×1.062 | ×1.177 | ×1.394 |
| 2 (F M) | 96.88 | 117.23 | ×1.210 | ×1.334 | ×1.020 | ×1.123 | ×1.403 |
| 3 (M F) | 96.05 | 116.59 | ×1.214 | ×1.468 | **×0.942** | ×1.124 | ×1.397 |
| 4 (F M) | 97.36 | 116.01 | ×1.192 | ×1.311 | **×0.984** | ×1.129 | ×1.385 |
| medians of 1-4 | 96.46 | 116.91 | **×1.212** | ×1.377 | ×1.004 | ×1.127 | ×1.395 |
| 5 (M F, `timing5.sh`) | 93.25 | 118.41 | ×1.270 | ×1.462 | ×1.079 | ×1.190 | ×1.385 |
| 6 (F M) | 94.16 | 117.49 | ×1.248 | ×1.483 | ×1.034 | ×1.146 | ×1.380 |
| medians of 1-6 | 95.10 | 117.36 | **×1.234** | ×1.461 | ×1.018 | ×1.133 | ×1.388 |

**b58 msd-strong is below ×0.98 in round 3 [M]:** that window is the field whose first 8e14 the MSD certificates reject
outright, so its stride window is CPU rejection with almost nothing for the GPU. Two more rounds (5, 6) were run for
it: over six rounds main spans 4.81-5.21e14 (8 %) and the fix 4.80-5.22e14, per-round ratios 1.062, 1.020, 0.942, 0.984,
1.079, 1.034, medians ×1.018. It is that scenario's run-to-run spread, not the kernel [D]; reported as measured against
the brief's "no scenario below ×0.98" (one of six rounds). Mean SM clock over busy samples: main 883-1016 MHz, fix
1153-1243 MHz, power 129.3-129.7 W in every run (`raw/box/out/analyze.out`).

**Why faster, and what the fix itself costs [M][D].** The fix's production plan on CUDA ranks by ballot (2 ballots
and popcounts per iteration) where main ran CubeCL's exclusive scan and sum (each a chain of 5-6 warp shuffles) on
every iteration of the queue loop, whatever the filter passed. The device is busy 58-60 % of the time with the fix
against 81-82 % on main, at a higher clock under the same power cap (1380-1415 MHz against 1123-1159): busy cycles
(time × utilization × clock) about 0.80 of main's [D, coarse: nvidia-smi's utilization is sampled]. To separate the
fix's own cost from the ballot's gain, the fix was timed with the **scan form forced** (FT2 = FT with a test-only
`NICE_TEST_QUEUE_FORM=scan` knob in the plan; `timing2.out`, rounds M Fs / Fs M / M Fs, then rounds 4-5 Fs M / M Fs):

| round | main s | fix, scan form s | fix / main |
|---|---|---|---|
| 1 | 82.244 | 84.426 | +2.65 % |
| 2 | 84.215 | 84.249 | +0.04 % |
| 3 | 83.662 | 84.407 | +0.89 % |
| 4 (`timing4.sh`, Fs M) | 83.910 | 83.889 | −0.03 % |
| 5 (M Fs) | 84.185 | 84.520 | +0.40 % |
| median of 5 | 83.910 | 84.407 | **+0.59 %** |

Main's eight b54 runs on this queue span 80.28-84.34 s (5 %); utilization 82 % on both sides, clock 1085-1104 MHz
(fix) against 1102-1140 (main). So the scan form, which 64-lane devices take, costs **about +0.6 %** on this card, under
the 1 % bar and within main's own run-to-run spread [M][D].

**The cube-scoped queue (the WGSL default), forced on CUDA [M]** (`timing3.out`; production knob
`NICE_CUBECL_PLANE_COMPACT=0`; FT2 with its form knob for both forms; same b54 harness; rounds M Fb Fs / Fb Fs M /
Fs M Fb; utilization and clock over busy samples, `raw/box/out/smi_summary.txt`):

| round | main s | fix, ballot form s | fix, scan form s |
|---|---|---|---|
| 1 | 91.234 | 74.352 | 91.109 |
| 2 | 93.078 | 73.899 | 91.358 |
| 3 | 93.421 | 73.913 | 91.399 |
| median | 93.078 | 73.913 (**×1.26**) | 91.358 (**−1.8 % time**) |
| util, SM clock | 82-83 %, 1259-1295 MHz | 74-75 %, 1328-1365 | 83 %, 1228-1235 |

Here even the scan form is a little faster than main: it drops main's per-iteration serial walk over the plane
totals (8 planes × 2 shared loads per lane) for one shared atomic per plane and one more plane sum.

**Registers / generated code:** not inspected per kernel (no PTX JIT replay this time). Kernels other than
`niceonly_kernel`: see 4.2.

## 6. What a wgpu device should expect [R][D][A]

Nothing here ran on a wgpu GPU (none available: no AMD or Apple GPU; lavapipe timings are not evidence of speed). Which
code a device runs: `ballot_append(plane_size_max)` picks the form (≤ 32 lanes: ballot), and the plan picks the queue
(plane-scoped on `cubecl-spirv`/CUDA, cube-scoped otherwise, and always cube-scoped on software rasterizers).

| device (as the fleet runs it) | queue | form | what was measured nearest to it |
|---|---|---|---|
| RX 9070 XT, `cubecl-spirv` build (RADV) | plane-scoped | scan if CubeCL reports `plane_size_max` 64 (RADV's maximum subgroup size with size control), else ballot [A: not checked on the card] | CUDA, plane-scoped, scan form: +0.6 % (median of 5); ballot: ×1.14 |
| RX 9070 XT, WGSL build | cube-scoped | same | CUDA, cube-scoped, scan: −1.8 %; ballot: ×1.26 |
| Apple M4 (wgpu → naga MSL, 32-lane SIMD groups) | cube-scoped | ballot | CUDA, cube-scoped, ballot: ×1.26 |

The direction should carry (fewer subgroup operations per iteration in the ballot form; no serial walk in the
cube-scoped queue), but the size does not: the 11-09 batch gained ×1.37 on CUDA and ×1.17 on the 9070 XT, and the
CUDA numbers here are at a 130 W cap where fewer shuffles also bought clock. The scan form's cost on a 64-lane RDNA
plane (shift/mask on packed words, two more registers for the account, one atomic per plane per iteration in the
cube-scoped queue) is unmeasured; it should be measured in a demoux window or from telemetry after a deploy.
`plane_shuffle` is new on main (first use in the kernels); every wgpu device with subgroups has it (§2).

## 7. Not done, caveats

- **No production launch loses survivors on any device available here.** The defect is reproduced only with
  test-only cube sizes (CUDA, lavapipe) and modelled for the populations no device here can produce (no lane 0,
  non-linear layouts, holes). Whether any shipping Vulkan driver runs a 256-wide workgroup with such subgroups is
  unknown; with the fix they are either right or the field fails.
- **The account is a count and a low-word sum (mod 2^32)**, like #251's and #260's: two coinciding errors with the same
  count and sum would pass. It is per field, not per launch.
- **llvmpipe's plane-scoped queue** loses survivors with or without the fix (§1.3); the account did not catch it there
  because its final cube barrier is not honoured either [A: mechanism]. Production never runs that combination.
- **Cost at the 1 % bar:** the scan form (64-lane devices) costs about +0.6 % on CUDA's plane-scoped queue, inside
  main's own run-to-run spread; the cube-scoped scan form is 1.8 % faster than main. The ballot form (CUDA, M4) is
  much faster than main (×1.14-1.26 on b54 fields, NiceMark ×1.21), at the 130 W cap only; not measured at the card's
  default 320 W. One NiceMark scenario (b58 msd-strong) had one round of six at ×0.94, inside its 8 % spread; its
  median is ×1.02.
- **Remaining assumptions** (shared with `top_slot` and #251): reconvergence between a ballot/scan and the following
  shuffle/sum; a plane's running lanes stay the same through the loop; `UNIT_POS_PLANE` = the ballot bit (CubeCL's
  CUDA/HIP lane id is right only in cubes that are whole warps; production launches 256-unit cubes).
- **Not run:** Metal, HIP, any 64-lane device; whole-workspace `cargo test`; register counts of the new kernel (no PTX
  replay); CUDA detailed kernels' identity (source untouched).
- **Where it would share code later:** the ballot/scan rank, leader and broadcast steps are the same pattern as #251's
  `take_entries` (fork `pr/check-d`) and #260's `top_slot`; once those land, a common `#[cube]` helper returning
  (rank, count, leader) could serve all four sites. On main today no such helper exists (`top_slot` still uses lane 0),
  so this branch stands alone and inlines it.
- **Two queue fixes in one commit:** they are the same defect class in the same kernel and share the account; split,
  either half would leave the account covering one queue only. The brief allowed a second branch if they were two
  independent changes of real size; I judged them one.
