# Review: `pr/top-slot-any-plane` (`f9a25017` on main `41b4b405`), the FD top kernel's append without lane 0 (2026-11-14)

Independent review. I read the diff, the kernel and the host code in a detached worktree
(`~/projects/nice/.worktrees/review-t26` at `f9a25017`), CubeCL 0.10.0, cubecl-opt 0.10.0 and the
wgpu/naga 29 sources in `~/.cargo/registry`, the author's raw logs and the integration branch
(`exp/integration-1114`, `8bcee21f`). I wrote my own model of both append forms and of main's
append (`T26/review-model/`) before reading the author's model. No GPU was used.

## Verdict: open after the listed fixes

The fixes are to the text: the PR body and the changelog line (F2, F3). The code is right. I found
no population of a plane, in either form, for which a kept top is lost, written twice or counted
in the wrong group, and no behaviour on full planes that anything downstream depends on. The
account is computed from the right quantities. It is checked on every production path that runs
the FD top kernel, and a mismatch always fails the field. One code change is recommended but not
required: a third account word, the sum of squares (F1). It closes a gap my model shows is wider
than the write-up says, for about one register. The merge with #251 needs the changes in F4,
whichever lands second. The integration branch already has them right for the order "#251 first".

## Findings

### F1: Low (robustness of the check, not of the append). The account can pass a wrong append, and more often than reported

- **Where:** `top_slot` (`common/src/cubecl_join.rs` 1829-1869), `top_complete` (4030).
- **What I found:** the account is a count and a sum mod 2^32, summed over the whole batch. Two
  kinds of wrong run pass it:
  - **One plane, sum preserved.** My model found a single plane that wrote record 6 three times
    and left records 0 and 12 unwritten. The count is 3 = 3 and the sum is 18 = 18.
  - **Several planes, errors cancelling.** One plane's error is +d and another's is −d, so the
    batch-wide sum sees nothing. With a 64-lane plane misreported as 32, lanes 32-63 mirror
    lanes 0-31. A mirrored lane also has rank 0, so it becomes a second leader that reserves its
    own block and then writes over the first leader's. Whole 32-record blocks are written twice
    and others left empty. Whether that error is +32k or −32k depends on which leader's atomic
    came first, so two planes can cancel.
- **How I know** (`review-model/faults_seeds123.out`, `squares.out`, `why_undetected.out`): 20,000
  random multi-plane launches per fault and seed, seeds 1-3. "Undetected" means wrong with a zero
  account. Totals:

  | fault modelled | wrong launches | undetected now | undetected with a squares word |
  |---|---|---|---|
  | 64-lane plane misreported as 32 (ballot form) | 39,842 | **245 (0.6 %)** | 4 |
  | lane id ≠ ballot bit (CubeCL's `idxGlobal % 32` on cubes not a multiple of 32) | 42,570 | 52 | 0 |
  | shuffle returns garbage | 21,805 | 40 | 0 |
  | ballot carries inactive lanes' bits | 39,539 | 4 | 0 |
  | C++ butterfly sums read junk from inactive lanes (scan form) | 13,146 | 1 | 0 |
  | no reconvergence after the leader's `if` | 27,614 | 0 | 0 |
  | (no fault) | 0 | 0 false alarms | 0 false alarms |

  - In one re-run of the misreport case, 98 of 108 undetected launches had their errors in
    several planes.
  - The write-up gives 1 undetected in 15,643 for the misreport case (RESULTS §3/§8). My model
    interleaves all atomics of all planes freely, which is what makes cross-plane cancellation
    possible. So "1 in 15,643" understates the gap.
  - On real hardware, the two leaders of a misreported plane issue one `fetch_add` instruction.
    That probably serializes in lane order, which would give every plane an error of the same
    sign. Nothing guarantees it, though.
- **Impact:** none on any known device. Main has no check at all. It matters only for the claim
  "the account fails the field instead of losing tops" (F2).
- **Suggested fix (cheap):** add a third word, the sum of squares of the indices.
  - Leader: subtract `take·r0² + r0·take·(take−1) + (take−1)·take·(2·take−1)/6` (u32 wrapping;
    the last term is exact for take ≤ 64).
  - Per-lane path: subtract `at²`. Each kept lane: add `rec²`.
  - `RAN_WORDS = STAGES + 3`. Same shared-memory sum, one more `ensure!`.
  - This makes the {6,6,6} vs {0,6,12} case and most ±d cancellations fail. In my model the
    word, computed in this closed form mod 2^32 (`top_slot_review.py`), cuts undetected launches
    from 342 to 4 over the six faults and three seeds, with no false alarm (table above).
  - It costs one more loop-carried register (the FD kernel is at 109/115, no spills).
  - If it is not done, keep the PR body's wording as in F2.

### F2: Low (PR body). Three statements go beyond the evidence

`T26/PR-BODY.md`:

1. *"If a device broke one of these, or misreported a 64-lane plane as 32, the account fails the
   field instead of losing tops."* Not always (F1). Suggest: "…the account fails the field in
   every such case we modelled but rare coincidences of a count and an index sum" — or add the
   squares word (F1) and keep the sentence.
2. *"#251 removed the same assumption from the check kernel."* #251 is open. Say "#251 removes",
   or adjust once the merge order is known.
3. *"The number of plane operations is unchanged (4 with the ballot, 5 with the scans)."* True.
   But in the scan form two `plane_broadcast(·, 0)` become two `plane_sum` reductions: `g0`, and
   the leader's result. That form is the only one 64-lane devices (RADV wave64, HIP wave64) take,
   and it was never timed: the cost table is the RTX 3080's ballot form. A reduction is several
   steps where a broadcast is one read. Add one sentence: "the cost was measured on 32-lane
   planes (ballot form); the scan form used on 64-lane planes replaces two broadcasts by two
   sums and was not timed."

Everything else in the body matches the raw logs (see "Verified" below). The body does not
mention the research program, its directories, agents or a model name. It is exactly 700 words
outside the tables. The only "Claude" is the required footer line.

### F3: Low (changelog). It promises slightly more than the check delivers

`CHANGELOG.md` 23: "…and fail the field instead of losing a top if a device ever appends them
wrongly." The check catches wrong appends whose count or index sum is off, which is almost all of
them, not all (F1). Suggest: "…and fail the field if the tops it appends do not add up to the ones
it kept." It is one line and in the style of its neighbours.

### F4: Medium (merge procedure, not this commit). What the second of #251 and this PR to land must change

`ran` on main is `[0..4)`, the cube counts.

- #251 (`1f41d649`) adds the check kernel's work counter, entry count and index sum at
  `STAGES+0..3`, with `RAN_WORDS = STAGES + 3`. Its test-only smallest-take word is hard-coded
  as `ran[comptime!(STAGES_U32 + 3)]` in `take_entries` (two places). `run_check` allocates
  `RAN_WORDS + 1` and reads `ran[RAN_WORDS]`.
- This commit puts its account at `TOP_ACCOUNT = 4` (= `STAGES`), with `RAN_WORDS = STAGES + 2`
  and `const _: () = assert!(TOP_ACCOUNT as usize == STAGES)`.

The author's note (RESULTS §7 item 5) is correct. I add one hazard it does not mention.

**If #251 lands first and this PR second** (as on `exp/integration-1114`, which I checked at
`8bcee21f`):

- `TOP_ACCOUNT = STAGES_U32 + 3`; `RAN_WORDS = STAGES + 5`.
- Replace the assert with `TOP_ACCOUNT as usize + 2 == RAN_WORDS`.
- Move #251's smallest-take word to `RAN_WORDS` (the integration branch writes
  `TOP_ACCOUNT + 2`, which equals it).
- The `STAGES` doc comment lists all three regions.
- `ensure_ran` keeps `&ran[..STAGES.min(ran.len())]`.
- `run_pass` and `run_partition` call `ensure_appended` after `ensure_ran`, and #251's
  `ensure_checked` after reading the counts.

`8bcee21f` has all of this (lines 150-171, 3730/3743, 5006-5070).

**If this PR lands first and #251 second**, the hazard is quieter:

- `RAN_WORDS` conflicts textually, so someone will resolve it. But `TOP_ACCOUNT = 4` and
  `assert!(TOP_ACCOUNT as usize == STAGES)` merge cleanly and still compile, and #251's
  `ran[STAGES_U32]`, `ran[STAGES_U32 + 1]`, `ran[STAGES_U32 + 2]` merge cleanly too.
- A resolution that only bumps `RAN_WORDS` leaves the work counter and entry count on the same
  words as the top account.
- In production that fails every batch, loudly: the account is nonzero, and `ensure_checked`
  sees a count off by the account. It would be a fleet-wide stop, not a loss, and lavapipe and
  Metal CI would catch it before release.
- The hard-coded min-take word at `STAGES_U32 + 3` = 7 would then fall inside `ran`. That
  breaks only #251's test: CUDA asserts the smallest take, but wgpu only prints it, and would
  print "no partly filled plane ran" for every device.

**Recommendation for whichever lands second:**

- Name every word in one place: `CHECK_WORK = STAGES`, `CHECK_COUNT`, `CHECK_SUM`,
  `TOP_ACCOUNT`, `RAN_WORDS`, `MIN_TAKE_WORD = RAN_WORDS`.
- Use the names in the kernels instead of `STAGES_U32 + k`.
- Assert disjointness at compile time: `CHECK_SUM < TOP_ACCOUNT` and
  `TOP_ACCOUNT + 2 == RAN_WORDS`, or the reverse order.
- Then run `check_all` on lavapipe once before landing. It exercises both PRs' fault tests,
  which fail if the words overlap.

### F5: Informational. Test coverage the PR cannot get from CI

- **Where the defect shows:** only with the test-only `TOP_LANE0_OUT`, and only on wgpu devices.
  - Lavapipe in CI, both compilers. I re-summed `repro_lvp_R.log` / `repro_lvp_RS.log`: main
    with lane 0 out loses 8,919,322 / 8,919,325 of 12,985,398 tops in 84 of 276 runs. With lane
    0 present there are 0 wrong runs.
  - The macOS Metal job (WGSL and MSL), where the new test will run for the first time; the
    author did not run Metal.
- **Without `TOP_LANE0_OUT`:** the partly-filled-plane comparisons would pass on main, on every
  device available. A partly filled plane there always has lane 0.
- **Not run anywhere:**
  - the scan form on a 64-lane plane;
  - the scan form on CUDA partly filled warps in the committed test (a repro ran it on main:
    `repro_cuda_scan_partial.log`, 184 runs, right).
- **If Metal CI fails on the new test:** look at the test mode (divergent `simd_*` ops with lane
  0 sitting out) before the fix. The fix itself is uniform-control-flow code there.

### F6: Informational. Reconvergence and SPIR-V `Uniform`: unchanged dependence, now partly settled

- **Reconvergence:** the remaining assumption, as in main and #251. The lanes that ran the
  ballot (or scan) must run the shuffle (or sum) after the leader's `if` together.
  - My model of its failure (the leader's result read from an inactive lane in the ballot form,
    or summing to 0 in the scan form) gives 9,238 wrong launches and 0 undetected (seed 11).
  - Nothing in naga 29, cubecl-spirv 0.10 or wgpu-hal 29 requests maximal reconvergence (CKF).
- **SPIR-V `Uniform` (CKF's open point):** cubecl-opt 0.10's `Uniformity` analysis is
  plane-scoped ("Whether a variable is plane uniform", `analyses/uniformity.rs`).
  - `Sum`, `All` and `Ballot` are marked uniform only in uniform blocks.
  - `ExclusiveSum` is never marked uniform. `Shuffle` is marked uniform only when its value
    operand is.
  - So `rank` is never decorated. `g0` in the ballot form (a shuffle of the non-uniform `g`) is
    not decorated either. Only per-dynamic-instance subgroup-uniform values can be.
  - Whether some driver reads `Uniform` at workgroup scope I did not establish. That predates
    this commit.

## What I verified, and how

### Q1: complete and non-overlapping by construction. Yes, in both forms.

**Argument (mine, from the code at 1778-1870).** Let P be the lanes running one dynamic instance.

- **Ballot form:**
  - `kb` is exactly P's kept lanes (planes ≤ 32 lanes; inactive bits clear on every backend,
    see Q3).
  - `rank = popcount(kb & ((1<<lane)−1))` is a bijection from P's kept lanes onto `0..n`.
  - `lead` holds for exactly one lane when `n > 0`. That lane is `src = ctz(kb)`, computed as
    `(kb ^ (kb−1)).count_ones() − 1`, which is right for bit 31 too. It is in P, so both
    shuffles read an active lane.
  - With `n = 0`, every lane reads itself, so no inactive lane is ever read.
- **Scan form:**
  - The sum and the exclusive sum are over P, so the same bijection holds.
  - `g0` and `a` are sums with exactly one nonzero term, the leader's. `a0` is 0 on every other
    lane, including when `one` is false, and the leader's own `a0` may legitimately be 0.
- **Both forms:**
  - `g0` is uniform over P, so `one = plane_all(!kept || g == g0)` is uniform.
  - If `one`: the leader is kept and of group `g0`, and every kept lane is of `g0`. Their
    `goff`, which is `tlay` word 3 = `goff[g]` (`join_plan.rs` 500), is the leader's, and one
    `fetch_add(n)` on `grp_cnt[slot·nb + g0]` reserves `[a0, a0+n)` of exactly that group.
  - If not `one`: each kept lane takes its own atomic on its own group.
  - The leader's own check `g == g0` is inside `one`. So a wrong `g0` can only send the plane to
    per-lane atomics. It can never count a top in another group's counter while it is written
    to its own segment.
  - Every unit runs the slot loop the same number of times (`slot`/`slot_end` from
    `CUBE_POS_Y`, 2842-2848). Nothing returns early, and dead lanes call with `kept = false`.
    So every kept top takes part in exactly one call. Splitting a plane across several
    instances is harmless, since each instance has its own leader.

**My model** (`review-model/top_slot_review.py`, output `top_slot_review.out`; written from the
kernel source, not from the author's model):

- **Exhaustive, one call, 8-lane plane:**
  - Every active subset (255) × every kept subset of it × every 2-group assignment of the
    lanes plus every sorted 3-group cut, both forms.
  - **3,949,120 calls, 0 wrong, 0 nonzero accounts.** I also verified completeness directly:
    each group's counted records are written exactly once, with tops of that group, and nothing
    is written outside a counted range.
- **Full 8-lane planes, fix vs main:**
  - Every kept subset × every assignment of 3 groups to lanes (any order), both forms:
    3,359,232 calls.
  - Fix wrong 0, main wrong 0; **per-group sets of tops identical in every case**.
  - The record each top gets differs in 1,965,776 of them: Q2.
- **Random multi-plane launches:**
  - Widths 8/16/32/64; both forms (scan only at 64); 1-6 planes on shared counters; all atomics
    of all planes interleaved at random.
  - Populations: full, prefix, without lane 0, holes, 30 % of launches with planes split across
    up to 4 instances.
  - Group layouts: one, two, sorted cuts, random. Record offsets near 0, 7, 3·10^9 and
    2^32 − 3·size, so the u32 sums wrap.
  - Seed 11: **20,000 launches, 0 wrong, 0 false alarms.**
- **Sanity:** main's append on populations without lane 0 is wrong in 7,048 of 20,000 launches,
  and right on full and prefix populations (0 of 20,000).
- **Faults** (does the account catch them): F1 and F6. Seeds 1-3 in `faults_seeds123.out`.

### Q2: full planes, the changed choice of group. Nothing downstream depends on it.

- **The difference on a full plane:** main tested lane 0's group, kept or not. If lane 0 is not
  kept and lies in a different group from the plane's kept lanes, main gave every kept lane its
  own atomic. The fix gives the plane one atomic. Both put the same tops in the same groups (model
  above). Only the record order within a group, and the number of atomics, differ.
- **The join reads a bucket's tops** as `top_rec[slot·ntlay + goff[g]..][..grp_cnt]`
  (`join_kernel` 595-683) and processes them in batches of `TOP_CAP`.
  - The per-top data (mask, clipped-range words, `dm`, seed) travels with the record, so no
    computation depends on a top's position.
  - Survivors, `checked`, the overflow decision (a count), `nt >= TRANSPOSE_MIN` (a count) and
    the hits do not depend on order.
- **Record order is already nondeterministic on main:** planes' atomics interleave in any order,
  and straddling planes take per-lane atomics. The comparison tests sort entries (`run_tops`,
  6680) and fill records with a sentinel first.
- **Telemetry:** no counter derives from record order.
- **Determinism:** the box runs give identical survivors / checked / found for M and F in all
  20 timed processes. I re-read all 20 logs.

### Q3: per backend (CubeCL 0.10.0, read here)

| op (this commit uses) | CUDA (`cuda/dialect.rs`) | HIP (`hip/dialect.rs`) | Metal, cubecl-cpp MSL (`metal/dialect.rs`) | WGSL (`wgsl/subgroup.rs`) → naga | SPIR-V (`cubecl-spirv subgroup.rs`) |
|---|---|---|---|---|---|
| `plane_ballot` | `__ballot_sync(-1,x)` → `{b,0,0,0}` (623; `shared/warp.rs` 108-121) | `uint(__ballot(x))`, 32 bits (555) | `uint(uint64_t(simd_ballot(x)))` (1037) | `subgroupBallot` (148) | `OpGroupNonUniformBallot` (83) |
| `plane_shuffle` (runtime lane) | `__shfl_sync(-1,v,src)` (581) | `__shfl(v,src)` (504) | `simd_shuffle` (990) | `subgroupShuffle` (184) | `OpGroupNonUniformShuffle` (189) |
| `plane_all` | `__all_sync(-1,x)` (609) | `__all` (540) | `simd_all` (1022) | `subgroupAll` (91) | `OpGroupNonUniformAll` (26) |
| `plane_sum` / `plane_exclusive_sum` | `shfl_xor` / `shfl_up` loops over `warpSizeChecked` (`shared/warp.rs` 270-345) | same, 64 lanes on wave64 | `simd_sum` (64) / `simd_prefix_exclusive_sum` (120) | `subgroupAdd` / `subgroupExclusiveAdd` (150-157) | `OpGroupNonUniformIAdd` Reduce / ExclusiveScan (105-108) |
| `UNIT_POS_PLANE` | `uint(idxGlobal) % warpSize` (`shared/dialect.rs` 375-380) | same | `simd_lane_id` (650) | `subgroup_invocation_id` | `SubgroupLocalInvocationId` |

- **Inactive lanes:**
  - WGSL, SPIR-V and Metal define all of these over the active invocations. A shuffle from an
    inactive lane is undefined, and the fix never does one.
  - CUDA's `-1` masks force the warp together. `__ballot_sync` gives inactive lanes 0 bits.
  - The C++ sums shuffle from every lane, so CUDA and HIP need full planes for the scan form.
    Production's 256-unit cubes give that; CUDA never takes the scan form (`ballot_append(32)`).
- **Ballot gating:** `ballot_append(plane_size_max) = plane_size_max <= 32` (156).
  `plane_size_max` comes from wgpu's `subgroup_max_size` (32 forced only under
  `cfg(apple_silicon)`, `cubecl-wgpu runtime.rs` 297-307), so RADV (max 64) takes the scan form.
- **The 64-lane device's correctness** rests on three things:
  - (a) RADV/ACO computing `OpGroupNonUniformIAdd` Reduce and ExclusiveScan over the active
    lanes, which is the Vulkan definition [R spec; driver implementation A];
  - (b) reconvergence after the leader's `if` (F6);
  - (c) that device reporting `maxSubgroupSize` = 64 [A].
  The scan form uses no lane id and no width. (a) and (b) are the same reliance as main's scan
  form and #251's.
- **This commit's scan form vs main's on a full plane:**
  - Main: broadcast(`g`, 0), all, sum(`kept && one`), scan(`kept && one`), broadcast(`a0`, 0).
  - Fix: sum(`kept`), scan(`kept`), sum(`g` of the leader), all, sum(`a0`).
  - Same tops per group; on a full plane only the leader's identity and `one`'s strictness
    differ.
  - On SPIR-V main's broadcasts were `OpGroupNonUniformBroadcast` (uniform id 0). The fix's are
    reductions: cost unmeasured (F2.3).
- **HIP wave64** (opt-in feature): the scan form's butterflies are fine for 256-unit cubes.
  HIP's lane id is `idxGlobal % 64`, also fine there.

### Q4: the account and the host check

- **Computed from what was written and reserved, not from one quantity twice:**
  - Written side: each kept lane adds 1 and `rec`, the very index it then writes `top_rec` at
    (3029-3037; `rec` is only produced by `top_slot`).
  - Reserved side: the leader subtracts `take` (what it passed to `fetch_add`) and the indices
    `r0..r0+take` derived from the atomic's return.
  - The plane path's two sides meet only through the plane ops (ballot/scan, shuffles/sums),
    which is exactly what can go wrong.
  - The per-lane path's account is identically zero (it subtracts and adds the same `rec`). That
    is fine: it has no plane op. A `one` that disagrees between lanes shows up as a count error,
    because the leader reserves `n` and the others reserve their own.
- **Summation:**
  - Per lane in registers, then per cube through `s_acct` (zeroed before a `sync_cube` at
    2758-2763). Lanes `fetch_add` after the slot loop, `cube_done`'s `sync_cube` orders that
    before unit 0's loads, and unit 0 adds to `ran[4..6)` (3042-3058).
  - Every unit reaches `cube_done`; nothing returns early.
  - The host reads `ran` only after the kernels finish (`read_async` after all launches in
    `run_pass`, `read_u32` in `run_partition`).
- **Coverage:**
  - `launch_batch` is the only production caller of `launch_top` (3814), besides `warm_top`,
    whose counters are scratch.
  - `launch_batch` is called only from `run_pass` (4427) and `run_partition` (4507). Both call
    `ensure_appended` after `ensure_ran` (4451, 4511), and `run_pass` does so before the
    overflow check, so overflowed batches are checked too.
  - Batches that fail `ensure_ran` are skipped (`continue`) and re-run, and their account is
    rightly not trusted. A re-run goes through `run_partition` or a new pass, which check again.
  - The clipped blocks go to `top_kernel`: one atomic per top, no plane ops, no account. Its
    reservations interleave with the FD kernel's on the same counters, but the account only
    nets the FD kernel's own reserve/write pairs, so it is unaffected.
  - `fd = false` batches leave both words 0.
- **False alarms:**
  - None in my model: 0 in 80,000 random launches (seeds 11 and 1-3) plus the exhaustive single
    calls, including u32 wrap of the sums.
  - Overflow, retries and wrap are harmless. The account depends only on the top stage. `ran`
    is created fresh per batch (3802) and per re-run. Sums are exact mod 2^32 on both sides.
  - The u32 multiply `take·r0` wraps identically in the kernel and in the model.
  - `take·(take−1)/2` is exact (take ≤ 64).
- **A mismatch is an error, never a retry:**
  - `ensure_appended` returns an `anyhow` error (not `NotRun`), propagated by `?` from
    `run_pass` and `run_partition`. `rerun_partition`'s `e.downcast::<NotRun>()?` passes it
    through (4376).
  - The production `JoinPipeline` thread returns it from `run_field` (4585). The client's
    `finish_niceonly` error path logs and `exit(1)`s (`client/src/main.rs` 986-991). Nothing is
    submitted.
- **Wrong runs that pass:** sum-preserving multisets, in one plane or summed over planes (F1). A
  top whose `kept` is wrong (the certificate) or whose record content is wrong is outside the
  account's scope (audit gap 1), as on main.

### Q5: scope, cost and the identity claim

- **Scope:** `git diff 41b4b405 f9a25017` touches `CHANGELOG.md` and `common/src/cubecl_join.rs`
  only:
  - in kernels: `top_slot` and the FD kernel's account / test-bit call site;
  - on the host: `RAN_WORDS`, `top_wg` (always `JOIN_WG` outside tests), `ensure_ran` slicing,
    `ensure_appended`, `top_complete`, the two call sites;
  - tests.
  Within scope.
- **Cost:** I re-derived every number from `raw/box/logs/*.log` (`device=`) and
  `raw/box/out/ptxjit*.out`.
  - b62 spill-free (join kernel at 46-48 registers): M r1/r2/r3 = 67.381 / 67.269 / 67.226,
    median 67.269. F r1/r3/r4/r5 = 67.651 / 67.452 / 67.391 / 67.253, median 67.422: **+0.23 %**.
    The spill variant appears in F r2 and M r4/r5 (40 registers, 24 B spills). All 5+5:
    67.452 vs 67.381, +0.11 %.
  - b64, all spill-free: M median 138.026, F 138.485: **+0.33 %**.
  - `top_fd_kernel` registers 108→109 (b62), 112→115 (b64), no spills.
  - Survivors / checked / found are identical in all 20 processes.
  - All as reported. The method (interleaved, rotated, card cooled, spill variant separated) is
    sound. The one caveat is F2.3: only the ballot form was timed.
- **Identity claim:** I checked it myself on the author's raw compilation logs, with my own
  comparator (`review-model/kident.py`, `kident.out`).
  - It renames locals and shared arrays by first use, carries each shared array's element count
    on its new name, and compares the KernelId's comptime info verbatim. It also checks for
    overlapping shared arrays (aliasing).
  - CUDA: `bucket`, `check`, `join`, `smoke` and `top_kernel` are identical M↔F and M↔M2 (body,
    comptime info, 17/17 shared arrays with matching sizes, no aliasing on either side).
    `top_fd_kernel` differs: the `test: 0` comptime arg, the 2-word shared array and the account.
  - WGSL: I ran the author's `wdiff.py` on the logs, since no normalised WGSL result is saved
    under `raw/`; `ident.out` only has the raw "DIFFER (9 only in M…)" line. Every shader is
    identical M↔F except `top_fd_kernel`, and identical M↔M2.
  - The method is sound for what it covers. The offsets it ignores really do vary per process
    (M↔M2 raw diff), and sizes and non-aliasing are still compared in mine.
  - Coverage: one compiled configuration per kernel (b60 dense, hits mode, CUDA; the lint dump,
    WGSL); no SPIR-V or MSL. The source diff leaves every other kernel's source untouched, so
    identity is expected by construction and the comparison confirms it.

### Q6: the tests

- **Would they fail on main?**
  - `top_fd_appends_every_top_on_partly_filled_planes` on wgpu: yes, through `TOP_LANE0_OUT`.
    The author ran the equivalent harness on main (`raw/repro/`). I re-summed its logs (above),
    and its assertions (group counts equal, sorted entries equal, sentinel-filled records)
    would catch the lost tops.
  - Without the bit, no available device shows the defect (F5).
  - The CUDA variant cannot fail on main; the author says so. A diverged lane 0 hangs CUDA's
    `_sync` intrinsics, and partly filled warps always have lane 0.
- **`check_lost_tops`:** `TOP_SHORT_TAKE` must fail on the count and `TOP_DUP_RANK` on the
  index sum, both in `run_field` and in `run_partition`. The field then runs as before.
  - Logs: CUDA 112 / −94, lavapipe WGSL and SPIR-V 447 / −44, as reported.
  - A short take cannot write out of bounds: a plane's last write is below the group's kept
    count, so stays inside its segment.
- **`top_complete_wants_every_kept_top_once`:** a host unit test including the wrap. It ran here
  (see below).
- **Leakage into production:**
  - `test` is `0` under `#[cfg(not(test))]` (3686), and the bits only come from a `cfg(test)`
    thread-local.
  - They are comptime, so production code has no test branch. The generated CUDA's only
    `test`-related change is `test: 0` in the KernelId info.
  - Production runs `run_field` on the `JoinPipeline` thread, which would see the thread-local's
    default (0) even in a test build.
- **CI:**
  - The lavapipe job runs `--ignored` for all of `nice_common` (WGSL) and with the filter
    `cubecl_` (SPIR-V). The macOS job runs WGSL unfiltered and MSL with `cubecl_`.
  - The new wgpu test's path `cubecl_join::tests::top_fd_appends…` matches `cubecl_`.
    `check_lost_tops` runs inside `check_all`, which every device's CPU-reference test calls.
  - CUDA tests are manual.

### Q7: the PR body and the changelog

F2 and F3. Numbers in the body checked against the logs:

- 84 of 276 runs, 8.9 M of 13.0 M kept tops lost (8,919,322 / 12,985,398);
- 552 runs, 6,492,699 tops on lavapipe WGSL and SPIR-V;
- 230 runs, 4,764,544 tops on CUDA;
- the dense counts;
- both cost tables.

### Q8: interaction with #251

F4. The author's note is right, and `exp/integration-1114` variant 2 resolves it correctly for
the order "#251 first".

### Host-side checks run here

All with `CARGO_TARGET_DIR=~/projects/nice/.worktrees/rebase-1112/target`, `-j1`, `nice -n 19`,
on the worktree at `f9a25017`.

- `cargo fmt --all --check`: clean.
- `cargo clippy -p nice_common --all-targets --features cubecl -- -D warnings`: clean
  (`review-model/clippy.log`).
- `cargo test -p nice_common --features cubecl --lib cubecl_join`: 8 passed, 9 ignored (they
  need a device), including the new `top_complete_wants_every_kept_top_once`
  (`review-model/hosttests.log`).

## What could not be verified without hardware

- **The scan form on any 64-lane device** (RADV/AMDVLK wave64, HIP wave64): correctness and
  cost. It is argued from the specification and modelled, and has only run on lavapipe (8-lane)
  and CUDA full warps (main's, in a repro).
- **Metal:** the new tests have not run on Metal, MSL or WGSL. CI will be the first run (F5).
- **Whether any shipping Vulkan driver** runs a 256-wide workgroup's subgroup without lane 0.
  This decides whether main's defect is ever live.
- **Reconvergence at the leader's `if`** on each driver (F6). Argued and modelled, not observed.
- **Whether two leaders of one `fetch_add` instruction always serialize in lane order.** This
  decides whether F1's cross-plane cancellations can occur in the misreport case on real
  hardware.

Artifacts in `T26/review-model/`:

- `top_slot_review.py`, the model. Its output `top_slot_review.out` (exhaustive + seed 11) was
  produced before the squares word and the lane-id fault were added; the two-word results are
  unchanged by them.
- `faults_only.py` → `faults_seeds123.out` (seeds 1-3).
- `squares.py` → `squares.out` (seeds 1-3, with the suggested word scored).
- `why_undetected.py` → `why_undetected.out`.
- `kident.py` → `kident.out`.
- `clippy.log`, `hosttests.log`.
