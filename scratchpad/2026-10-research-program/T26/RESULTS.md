# T26: the top kernels' append without a lane-0 assumption; the four open PRs together (2026-11-14)

Branch **`pr/top-slot-any-plane`** (fork): one commit **`f9a25017`** on upstream main `41b4b405`.
Integration branch **`exp/integration-1114`** (fork): variant 1 = `99b283ab` (main + #251, #255, #256, #259 merged),
variant 2 = its child `8bcee21f` (variant 1 + this fix, cherry-picked).

Box: Vast 60601437, RTX 3080 10 GB, power cap 260 W, driver 595.99.02, Ryzen 7 5700G (16 threads), lavapipe = llvmpipe
(LLVM 20.1.2, 256 bits, 8-lane subgroups, `plane_size_max` 8), rustc 1.100.0 (main's pinned toolchain).
Labels: **[M]** measured here today, **[D]** derived from measured numbers, **[R]** read in source, **[A]** assumed.
Raw: `raw/box/logs/` (every run, `<name>.log`; timing runs also `.smi`), `raw/box/out/` (builds, chains, lint, ident),
`raw/scripts/` (all box scripts), `raw/repro/` (the test-only reproduction: `make_repro.py`, `repro_tests.rs`, the
generated `cubecl_join.repro.rs`), `raw/model/` (host model), `raw/0001-top-slot-any-plane.patch` (the commit).

## 1. Where the assumption was, and only there [R]

Only `top_fd_kernel` appends through `top_slot`. `top_kernel` (all-`top_kernel` batches and the clipped blocks beside
the FD kernel) takes one atomic per kept top and has no plane operation. `top_slot` on main:
`g0 = plane_broadcast(g, 0)`; `one = plane_all(!kept || g == g0)`; ranks by ballot or scan over the active lanes (fine);
`if UNIT_POS_PLANE == 0 && n > 0 { a0 = fetch_add(n) }`; `at = plane_broadcast(a0, 0) + pre`. A plane that runs the
call without lane 0 reads `g0` and `a0` from an inactive lane (undefined on every backend) and no lane advances
`grp_cnt`. A *dead* lane 0 (its prefix past the layer, `kept = false`, `g = 0`) is harmless: lane 0 still runs the call
and takes the atomic, and a wrong `g0` only sends the kept lanes to per-lane atomics.

## 2. Reproduction [M]

Harness (test-only, on main `41b4b405`; `raw/repro/make_repro.py`): the top stage's cube size becomes a test setting
(`top_wg`), `top_fd_kernel` gets a comptime test bit `TOP_LANE0_OUT` (every plane's lane 0 appends its own top with its
own atomic and **does not run `top_slot`**, so the rest of the plane runs main's unchanged `top_slot` without lane 0),
and `repro_*` tests run the FD kernel against `top_kernel` on the 17 test windows and the six `PLAN_FIELDS` first slices
(b42-b64, 1e13-1e14), two batches each, and **count** per run: tops `top_kernel` keeps, tops the FD kernel counted in
`grp_cnt`, how many of its counted records are `top_kernel`'s tops (multiset), lost, unwritten.

| run | device | result | log |
|---|---|---|---|
| main's `top_slot`, planes without lane 0 (`TOP_LANE0_OUT`), cubes of 100/48/256, ballot and scan forms | lavapipe, WGSL | **FAILS: 84 of 276 lane-0-out runs wrong, 8,919,322 of 12,985,398 kept tops lost (68.7 %)**; all 276 runs with lane 0 present right | `repro_lvp_R.log` |
| same | lavapipe, SPIR-V (`cubecl-spirv`) | **FAILS: 84 of 276 wrong, 8,919,325 lost** | `repro_lvp_RS.log` |
| main's `top_slot`, partly filled warps (cubes of 100 and 48, one cube; 256), ballot form | RTX 3080 | right: 0 of 230 runs wrong | `repro_cuda_ballot.log` |
| same, scan form (CUDA never selects it) on partly filled warps | RTX 3080 | right: 0 of 184 wrong | `repro_cuda_scan_partial.log` |
| main's `top_slot`, lane 0 out, cubes of 256 | RTX 3080 | **hangs** (killed after 600 s): the plane ops are `__*_sync(-1, ..)`, which require every lane named in the mask; a diverged lane 0 makes them undefined | `repro_cuda_lane0_256.log` |

What goes wrong, exactly (b57 1e14 first slice, 4 slots, 80,906 prefixes, cubes of 256, ballot form, WGSL): `top_kernel`
keeps 110,484 tops; the FD kernel counts 36,057 in `grp_cnt` and loses **74,427**. The kept tops of every plane whose kept
tops are all of one group (the usual case: the layer is sorted by group) are never counted, because the only lane allowed to
take the plane's atomic (lane 0) is not running the call. They are written at `plane_broadcast(a0, 0) + rank`, i.e. at
the start of their group's segment (the value llvmpipe returns for the inactive lane 0 is that lane's never-set
register), where they overwrite records that per-lane atomics counted (every counted record still holds *a* kept top:
`found = counted` in every run). The join reads only `grp_cnt[g]` records per group, so it never sees them: lost
candidates, and nothing on the host counted the stage. Planes whose kept tops straddle groups take per-lane atomics and
are unaffected (why 192 of the 276 lane-0-out runs, mostly the windows' small layers, stay right).

**What a real device can show [M][R]:** on CUDA a partly filled warp is lanes 0..r-1 of a cube's last warp, so it
*always has lane 0*: main is right there in both forms (above). A plane without lane 0 can only be made by divergence,
which CUDA's full-mask `_sync` intrinsics do not define (the run hangs). CubeCL's CUDA lane id `AbsolutePos % 32` (CKF)
also limits CUDA tests of non-multiple-of-32 cubes to one cube; the CUDA tests below launch one cube there. So the loss
is reproduced on lavapipe (a real Vulkan implementation, both compilers) with a test-only divergence, and not on any
device running production launches; no production device is known to launch planes without lane 0.

**Host model [M]** (`raw/model/top_slot_model.py`, `top_slot_model.out`, seeds 1-3 in `top_slot_model_seeds123.out`):
random planes (full, prefix, no lane 0, holes; 1-6 planes per launch interleaved on shared counters; one / two / random
groups). Main's `top_slot` with the inactive lane-0 read returning lane 0's register: 9,398 of 20,000 launches wrong
(seed 7); with garbage reads: 242 wrong (a garbage `g0` mostly sends kept lanes to per-lane atomics).

## 3. The fix

`top_slot` takes everything from the lanes that run the call (`P`):

- **kept set:** `kb = plane_ballot(kept)[0]` (ballot form, `ballot_append`: planes of at most 32 lanes, as before), else
  `kc = select(kept, 1, 0)`. `n = popcount(kb)` / `plane_sum(kc)`; `rank = popcount(kb & ((1 << lane) - 1))` /
  `plane_exclusive_sum(kc)`.
- **leader** = the lowest kept lane: `lead = kept && rank == 0`. Ballot form: its lane `src = ctz(kb)`
  (`(kb ^ (kb-1)).count_ones() - 1`; with nothing kept each lane names itself, so no read of an inactive lane ever
  happens), `g0 = plane_shuffle(g, src)`. Scan form: `g0 = plane_sum(select(lead, g, 0))`.
- `one = plane_all(!kept || g == g0)`; if `lead && one`: `a0 = fetch_add(n)` on `g0`'s counter; the result reaches the
  plane by `plane_shuffle(a0, src)` / `plane_sum(a0)` (only the leader's term is nonzero); kept lanes write `a0 + rank`.
- `kept && !one` (the plane's kept tops straddle groups): one atomic per kept lane, as before.

Plane operations per call: ballot form 4 (ballot, shuffle, all, shuffle; main: broadcast, all, ballot, broadcast), scan
form 5 (sum, scan, sum, all, sum; main: broadcast, all, sum, scan, broadcast). "Almost always one atomic per plane" is
kept, and slightly improved: `one` now asks only that the *kept* lanes share a group (main also required lane 0's
group, kept or not). A plane straddling groups still takes one atomic per kept lane.

**Complete for every population (argument) [R]:** let P be the lanes executing one dynamic instance of the call.
(1) A ballot's word holds exactly P's kept lanes below 32 (inactive lanes' bits are clear on every backend, table below),
so for planes of at most 32 lanes `rank` is a bijection from P's kept lanes onto `0..n`; the scan form's exclusive sum and
sum are over the active lanes, so the same holds for any width. (2) Exactly one lane has `lead` (rank 0 and kept) when
`n > 0`; in the ballot form it is lane `src`, which is in P, so both shuffles read an active lane; in the scan form `g0` and
`a` are sums with one nonzero term. (3) `g0`, `one` and `a` are therefore uniform over P. If `one`: a single
`fetch_add(n)` on the counter of `g0`, which is every kept lane's group, reserves `[a0, a0+n)`, and kept lane of rank r
writes record `a0 + r`: distinct, inside the reservation. If not `one`: each kept lane reserves and writes its own record.
(4) Every lane of a cube runs `top_fd_kernel`'s slot loop and calls `top_slot` once per slot (`live` or not), so every kept
top takes part in exactly one call. Hence every kept top of every (slot, group) lands at a distinct record of its own
group inside `[0, grp_cnt[g])`, and `grp_cnt[g]` equals the group's kept tops, for any population: full, partly filled,
without lane 0, with holes, or a plane split across several calls. Nothing depends on `PLANE_DIM` or on lane 0.
Remaining assumptions (the same as main's `top_slot` and #251's `take_entries`): the lanes that ran the ballot (scan) run
the shuffle (sum) after the leader's `if` together; `UNIT_POS_PLANE` is the lane's ballot bit.

**Per backend [R]** (cubecl 0.10.0 / naga 29.0.4 sources, as CKF/REVIEW read them; rechecked here:
`cubecl-cpp-0.10.0/src/cuda/dialect.rs:581-623`):

| op | CUDA | HIP | Metal (cubecl-cpp MSL) | WGSL (naga: Vulkan, Metal, DX12) | SPIR-V (cubecl-spirv) |
|---|---|---|---|---|---|
| ballot | `__ballot_sync(-1, x)`: inactive lanes' bits clear | `__ballot` truncated to 32 bits (ballot form only on wave32) | `simd_ballot`, low 32 bits | `subgroupBallot`, word 0 = lanes 0-31 | `OpGroupNonUniformBallot` |
| shuffle (dynamic lane) | `__shfl_sync(-1, v, src)` | `__shfl` | `simd_shuffle` | `subgroupShuffle` | `OpGroupNonUniformShuffle` |
| all | `__all_sync(-1, x)` | `__all` | `simd_all` | `subgroupAll` | `OpGroupNonUniformAll` |
| sum, exclusive sum | butterfly shuffles over all 32 lanes | same over 64 | `simd_sum`, `simd_prefix_exclusive_sum` | `subgroupAdd`, `subgroupExclusiveAdd` | `OpGroupNonUniformIAdd` |
| lane id | `AbsolutePos % 32` | `AbsolutePos % 64` | `simd_lane_id` | `subgroup_invocation_id` | `SubgroupLocalInvocationId` |

- **CUDA (32-lane warps, ballot form):** production cubes are 256 units (8 full warps), where the lane id is right and
  every `_sync` mask is met. Partly filled warps (lanes 0..r-1) run correctly in one cube (tests below).
- **HIP wave64 / Metal on AMD / RADV (64-lane planes, scan form):** defined over the active lanes on Metal, WGSL and SPIR-V
  for any population; HIP's butterflies need full waves, which 256-unit cubes give. `plane_shuffle` is new to `top_slot`
  but not to the join (#251's check kernel uses it); wgpu exposes subgroups only with Vulkan's SHUFFLE capability.
- **A 64-lane plane misreported as 32 (SOUNDNESS gap 5):** wrong (lanes 32-63 are missing from the ballot and the shift
  masks to `lane mod 32`), as it was on main, but now caught by the account (§4); model: 15,643 of 20,000 launches wrong,
  1 of them with a zero account (seed 7; 0 in seeds 1-3, which have 15,529-15,712 wrong launches each).

**Model of the fix [M]** (`top_slot_model.out`, seeds 7 and 1-3, 20,000 launches each): ballot form at widths 8 and 32,
scan form at 32 and 64: **0 wrong** in every seed, no false alarms. Without reconvergence after the leader's `if`
(lanes read the atomic's result before it is written): 12,570-12,819 wrong per seed, **0 undetected** by the account.
Exhaustive single call (`exhaustive.py`): every population of an 8-lane plane, every kept subset, every two-group cut,
both forms: 118,080 calls, 0 wrong.

## 4. The host check (the account)

Cheap, so built: `top_fd_kernel` keeps two words per lane: (tops it wrote) − (records it reserved), and (indices of the
records it wrote) − (indices of the records it reserved), mod 2^32. The leader's reservation of `n` records from `r0`
counts `n` and `n·r0 + n(n-1)/2`; a per-lane atomic counts 1 and its record; each kept lane counts 1 and the record it
writes. A cube sums its lanes' words in shared memory (one barrier at the start, the existing one in `cube_done` at the
end) and unit 0 adds the cube's two words to `ran[TOP_ACCOUNT..+2]` (two new words after the cube counts:
`RAN_WORDS = STAGES + 2`). `JoinDevice::ensure_appended` → `top_complete` requires both to be zero after `ensure_ran`, in
every batch of `run_pass` and in `run_partition`; a nonzero account is an `anyhow` error (not `NotRun`), so the field
fails, the client exits non-zero and nothing is submitted. Because every `grp_cnt` atomic is mirrored in the account,
zero means: as many tops written as records counted, and the written indices sum like the counted ones, so a top
written outside the counted range, a counted record left unwritten or one written twice fails. Like #251's index sum it
cannot see a multiset with the same size and sum (needs two coinciding errors; the model found 1 such case among 15,643
misreport launches).

Tested [M]: `check_lost_tops` (in `check_all`, so on CUDA and every wgpu CI device) runs the first window whose planes keep
two tops with two test-only comptime bits: `TOP_SHORT_TAKE` (every plane's leader reserves one record fewer) and
`TOP_DUP_RANK` (a plane's second kept top is written to the leader's record); each must fail `run_field` and a partition's
re-run with its own message, and the field then runs as before. CUDA: "overlap join b20: the top stage kept 112 more tops
than it counted for the join" and "... the record indices the top stage wrote differ from those it counted by -94 (mod
2^32)". Host unit test `top_complete_wants_every_kept_top_once`. `run_tops` (every FD comparison test) also asserts a zero
account.

## 5. Exactness of the fix

All on the commit's tree (box worktree `fix` at `f9a25017`; ivory `t26/top-slot` = the same commit), binaries **F**
(`--features gpu`: CUDA + wgpu/WGSL, md5 2c8cb647) and **FS** (`gpu,cubecl-spirv`, md5 045edbf7). [M] unless marked.

| run | device | result | log |
|---|---|---|---|
| `top_fd_appends_every_top_on_partly_filled_planes` (new): FD vs `top_kernel`, 23 fields (17 windows + 6 `PLAN_FIELDS` first slices), 2 batches each, cubes 100/48/256, ballot and scan forms, with and without `TOP_LANE0_OUT`; account zero in every run | lavapipe WGSL / SPIR-V | ok, 552 runs each, 6,492,699 tops; the same harness on main fails (§2) | `fix_lvp_partial_F.log`, `fix_lvp_partial_FS.log`, `lvp_F.log`, `lvp_FS.log` |
| `cubecl_cuda_top_fd_appends_every_top_on_partly_filled_warps` (new): same, ballot form, one cube for 100/48 (layer cut to a window of 100 / 97 or 48 / 45 prefixes) | RTX 3080 | ok, 230 runs, 4,764,544 tops | `fix_cuda_partial_F.log`, `F_cuda_suite.log` |
| `check_lost_tops` (new, in `check_all`): `TOP_SHORT_TAKE` / `TOP_DUP_RANK` fail `run_field` and a partition's re-run with the account's two messages; the field then runs as before | RTX 3080; lavapipe WGSL and SPIR-V | ok (CUDA: 112 tops / -94; lavapipe: 447 tops (= the b20 window's 3,576 prefixes / 8-lane planes) / -44) | `F_cuda_suite.log`, `lvp_F*.log` |
| `cubecl_cuda_join_matches_the_cpu_reference` (b10, 17 windows, b57 frontier partitions, tight layouts, slices, refused layouts, production shape, lost tops) | RTX 3080 | ok | `F_cuda_suite.log` |
| `cubecl_cuda_top_certificates_match_the_lockstep_scan_and_the_cpu` | RTX 3080 | ok (102,365 intervals, 33,582 kept) | `F_cuda_suite.log` |
| `cubecl_cuda_top_fd_matches_the_top_kernel` (heavy: also the 1e16 fields), own process | RTX 3080 | ok (565 s; main 568 s) | `F_cuda_top_fd_matches.log`, `M_cuda_top_fd_matches.log` |
| the same in one process after the three tests above | RTX 3080 | **failed: CubeCL could not allocate a 2.59 GB buffer** for the b60 1e16 field (10 GB card) and the top kernel ran 0 cubes; passes alone (row above). Not a defect of the fix [A: CubeCL's memory pool keeps the earlier tests' buffers for the process; main was not run in one process]; every later CUDA run ran each test in its own process | `F_cuda_suite.log` |
| every wgpu test of `cubecl_join` (9 on main: CPU reference incl. lost tops, ticket, production sample, certificates, FD vs top, partial planes; three opt-in ones skip) | lavapipe WGSL / SPIR-V | 9 passed each (334 s / 593 s) | `lvp_F.log`, `lvp_FS.log` |
| dense compares vs the CPU join, 8 partitions of slice 0: b60 1e16 at `1447429612114824200908`; b62 1e17 at `7520566762397899821056`; b64 1e17 at `58557331862957161709568` | RTX 3080 | ok: 334,071,589 / 22,383,910; 170,247,827 / 10,384,896; 697,596,881 / 43,247,716 (survivors / checked, equal to the CPU join's) | `F_dense_b6*.log` |
| host tests, CI's command `cargo test --release -p nice_common --features gpu --lib` | box CPU | 248 passed, 55 ignored | `F_host_tests.log` |
| `cargo fmt --all --check`; `cargo clippy -p "*" --all-targets -- -D warnings`; the same with `--features nice_client/gpu,nice_client/cubecl-spirv` (`just lint`), rustc 1.100.0 | box | clean | `lint_fix.log` |
| timed fields (§6): survivors / checked / found identical between M and F in every round | RTX 3080 | identical | §6 |

**Generated kernels other than the top kernels: identical to main's [M]** (`raw/scripts/ident.sh`, `kdiff.py`,
`wdiff.py`; data `raw/box/ident/`). Inputs: CubeCL's full compilation log of a production run (the dense compare on one
partition of b60 1e16, `launch_batch` in hits mode) for CUDA, and CI's `wgsl_dump_for_lint` on lavapipe for WGSL; each
kernel compared after renaming CubeCL's numbered locals and shared arrays in order of first use, sorting declarations and
ignoring shared-array offsets. CUDA: `bucket_kernel`, `check_kernel`, `join_kernel`, `smoke_kernel`, `top_kernel`
identical; `top_fd_kernel` differs. WGSL (14 shaders, 10 kinds): all identical but `top_fd_kernel`. A second main process
(M2) against M: every kernel identical under the same normalisation; without ignoring shared-array offsets `join_kernel`
differs even M against M2 (CubeCL's per-process shared-memory layout, as CKF found), so that normalisation is needed and
not hiding a change.

Not run: whole-workspace `cargo test` (the commit touches `common/src/cubecl_join.rs` and `CHANGELOG.md` only); Metal, HIP,
RADV/any 64-lane device (none available); the scan form on CUDA partly filled warps in the fix's test (CUDA never
selects it; CubeCL lowers its sums over all 32 lanes, though main's ran right there, §2).

## 6. Cost

COST

## 7. Task 2: the four open PRs together

Branch `exp/integration-1114` on the fork (pushed): `41b4b405` → merge #251 `911305ec` → #255 `25ad18dd` → #256
`2189dc75` → #259 **`99b283ab` (variant 1)** → this fix cherry-picked **`8bcee21f` (variant 2)**. `git merge --no-ff` in
PR-number order (#251, #255, #256, #259), heads as briefed (`1f41d649`, `42d2afd9`, `0f6794a2`, `3b773708`).

**Conflict resolutions (for the director to reuse):**

1. **#251 into main:** clean.
2. **#255:** `CHANGELOG.md` only (both append to Unreleased): keep both, #251's line first.
   `common/src/cubecl_join.rs` merged automatically.
3. **#256:** `CHANGELOG.md` only: keep both (#251, #255, #256). Code merged automatically.
4. **#259:** `CHANGELOG.md` (keep all four, in PR order) and one hunk in `walk_pf_lean`'s body. Resolution: #255's
   four digits (`pow2 = base.is_power_of_two()`, `h = f >> (32 - s)`, `g = (f << s) >> (32 - s)` at b = 2^s, else the
   two `mul_hi`s), followed by #259's test unchanged (`if comptime!(count) { popcount } else { the compare form in its old
   statement order }`). The doc comment merged automatically and reads right (#255's "(at a power-of-two base, shifts of
   `F` give the same words)" sentence, then #259's count paragraph). `JoinDevice`'s fields merged automatically (#259's
   `pf_count` beside #251's `check` shape).
5. **This fix on top (variant 2)** conflicts only with #251, both extend `ran`: words `0..4` cube counts, `4..7` #251's
   check (work counter, entries checked, index sum), then this fix's account: `TOP_ACCOUNT = STAGES_U32 + 3`,
   `RAN_WORDS = STAGES + 5`. #251's test-only smallest-take word was hard-coded as `ran[STAGES_U32 + 3]` in
   `take_entries` (twice); it must move to `RAN_WORDS` (`TOP_ACCOUNT + 2`), the word `run_check` allocates and reads,
   or the test bit would write over the top account. Everything else is both sides: the `use super::{..}` list,
   `ensure_checked` and `ensure_appended`, `check_complete` and `top_complete`, the two thread-locals, `check_all` calling
   `check_skipped_entries` and `check_lost_tops`, both host unit tests; `run_partition` calls `ensure_appended` right after
   `ensure_ran` and #251's `ensure_checked` after reading the counts (`run_pass` merged automatically in that order);
   `ensure_ran` keeps #251's `&ran[..STAGES.min(ran.len())]`. Whichever of #251 and this fix lands second needs this.

TASK2_RUNS

## 8. Not done, caveats, what I would not sign off

- **No device was shown to lose a top on a production launch.** The loss is reproduced on lavapipe with a test-only mode
  in which every plane's lane 0 sits out of the append (§2), and modelled; on CUDA a partly filled warp always has lane
  0, and a lane that sits out leaves the `_sync` intrinsics undefined (the run hangs). Whether any shipping Vulkan driver
  runs a 256-wide workgroup with a subgroup lacking lane 0 is still unknown; the fix and the account make it either
  right or loud.
- **The account is a count and a sum (mod 2^32)**, like #251's check: a multiset of written records with the same size
  and index sum as the reserved one passes. No single mechanism I could build gives that; the model's 64-lane-misreport
  case gave 1 in 15,643 wrong launches (seed 7; 0 in 61,000+ wrong launches of seeds 1-3), with that model's small
  record indices. A sum of squares would close it for one more register; not done.
- **Remaining assumptions** (unchanged from main and #251): reconvergence between the ballot/scan and the shuffle/sum
  across the leader's `if` (nothing requests it on Vulkan; if it fails the account catches it in the model: 0
  undetected in ~51,000 wrong launches); `UNIT_POS_PLANE` = the ballot bit (CubeCL's CUDA/HIP lowering is right only for
  cubes that are multiples of the plane width, true in production).
- **Not run:** a 64-lane device (RADV, HIP wave64) or Metal, so the scan form ran only on lavapipe (8-lane planes) and
  CUDA full warps; whole-workspace `cargo test`; the CUDA test of planes without lane 0 (undefined there).
- **The CUDA suite in one process** ran out of the 3080's memory in the heavy FD comparison after the new partial-warp
  test (§5); each test passes in its own process. Someone running `cubecl_cuda_` tests in one process on a 10 GB card
  may hit it; not investigated further (CubeCL's memory pool is per process [A]).
- The account adds two loop-carried registers, a shared-memory pair, one barrier per cube and per-lane adds to
  `top_fd_kernel` (cost in §6).
