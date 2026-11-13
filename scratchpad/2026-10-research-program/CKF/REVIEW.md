# Review: the fix to PR #251's check-kernel hand-out (`bc9d87c7..8d11e0be`), 2026-11-13

Reviewer: independent; not involved in writing the fix. Worktree `~/projects/nice/.worktrees/review-ckf`
(detached at `8d11e0be`, clean). Line numbers refer to `common/src/cubecl_join.rs` at `8d11e0be` unless marked
`main` (`origin/main` = `a7a59c11`).

## Verdict

**Ready again after the listed fixes. None of them is in the kernel or in the host check's logic.** The hand-out
is complete and non-overlapping by construction in both forms, for any population of a plane. One assumption remains,
and the author names it: the lanes that run a take's ballot or scan also run its shuffle or sum, so they reconverge
after the leader's `if`. If that assumption fails, my model shows a loud failure (an index-sum mismatch or a hang),
never a silent loss. The host check sits on every production path that launches the check kernel. A mismatch there
always becomes a field error and the client exits. The fix touches nothing else.

What to fix before calling it ready:

1. **(Low–Medium, tests)** No test makes the index-sum half of `ensure_checked` fail (F1).
2. **(Low, write-up)** The PR body's work-distribution bullet has stale numbers, and one sentence is ambiguous (F4).

Optional: give the regression test evidence that it really hit a partly filled plane on a CI device (F2).

Separately, outside this PR, main's niceonly stride kernels carry the same full-plane / lane-0 assumption as
`top_slot`, and in a sharper form (F6). That belongs on T2's list, not on #251.

## Findings, by severity

### F1 — Low–Medium (tests): no test makes the index-sum comparison fail

- Where: `check_skipped_entries` (5161) and `CHECK_SKIP_FIRST` (133; kernel 3336-3339).
- What: the test mode skips **entry 0**. Its index contributes 0 to the sum, so the sum still matches and only the
  count fails. The logs show this directly:
  - CI Metal and lavapipe: "checked 138 of the 139 … index sum Some(9591), want 9591".
  - b10: "checked 0 of the 1 … index sum Some(0), want 0".
- Why it matters: the sum is the half that catches "one entry checked twice, another skipped", where the count
  matches. That is the failure mode of the misreported-width case (RESULTS §2) and of a reconvergence failure (my
  model, below). Today that half is verified only by reading: no test fails if, say, the sum word were never
  compared or were read from the wrong index.
- Fix: add a second test-only bit, e.g. `CHECK_DUP_FIRST`. The lane whose entry is 1 checks entry 0 instead
  (`i = select(i == 1, 0, i)` before the work). The count then matches and the sum is short by 1. Assert the same
  error on both paths. Better still, also add a pure host unit test of `ensure_checked`'s comparison: factor it
  into a free function of `(ran, checked, list_cap)` and cover count-wrong, sum-wrong, the `listed = list_cap`
  (overflowed) case, and the u64→u32 wrap at `listed ≥ 92,682`.

### F2 — Low (tests): no CI device is shown to exercise a partly filled plane

- Where: `check_partial_planes` (5942) and `run_check` (5560).
- The old hand-out is **demonstrated** to fail only on CUDA, one cube (`repro_cuda2.log`: 34,296 of 218,772
  entries never checked; I re-summed the 63 lines). CUDA tests are manual, not in CI.
- lavapipe runs a cube's last subgroup with every lane taking part, so it cannot show the defect (`repro_lvp.log`:
  0 of 218,772).
- The macOS paravirtual Metal device may well run a partly filled simdgroup for 100- and 48-unit threadgroups. That
  would make CI catch a regression of either form. Nothing records that it did, though: the CI log only says
  "168 runs … ok".
- Consequence: a regression of the hand-out could pass CI unseen. The host count would still catch it in
  production, so the failure would be loud, not silent.
- Fix (cheap): have the kernel also `fetch_min` the take sizes into a spare test word. Have `run_check` print the
  smallest take seen, and assert `< PLANE_DIM` for the 100/48-unit runs on devices that are not lavapipe. Or at least
  print it, so a CI log shows whether a partial plane happened.

### F3 — Informational: the single remaining assumption (reconvergence inside a take)

- Where: `take_entries` (3499-3522).
- In both forms, `if rank == 0 { got = fetch_add(..) }` sits between the ballot/scan and the shuffle/sum.
  Correctness needs the lanes that ran the first op to run the second together.
- Nothing requests this:
  - naga 29, wgpu-hal 29, cubecl-spirv 0.10 and cubecl-wgpu 0.10 never emit `MaximallyReconvergesKHR` or
    `SubgroupUniformControlFlowKHR` (grep, none).
  - So on Vulkan it rests on driver behaviour, not on the spec.
- The old kernel had the same dependence (lane 0's atomic, then a broadcast), and so does `top_slot` on main.
- It is not silent if it fails:
  - **Scan form:** non-leaders sum to 0 and re-check from entry 0. The index sum is wrong (or the loop never ends).
  - **Ballot form:** the shuffle reads an inactive lane. My model (`noreconv_*`, 0 undetected in 7,700 wrong runs)
    shows the host check catches it.
- A branch-free variant could remove the assumption: every participant does `fetch_add(select(rank == 0, n, 0))`.
  It costs n same-address atomics per take, so I do not recommend it without a measurement. Leave as is.

### F4 — Low (write-up): stale and ambiguous text in `PR-BODY-DELTA.md`

- The "Work distribution" bullet is stale. It still says "at its ~40 registers (a 3080 holds 408, an H100 792)".
  At the measured 47 registers that becomes 5 cubes per SM: 340 on a 3080 (68 SMs) and 660 on an H100 (132 SMs).
  The conclusion (2048 cubes is more than the GPU holds) still stands.
- The sentence "with them, b62 is 72.019 s against 72.108 s" reads as if this head took 72.019 s. The raw logs give:
  - previous head, all 6 processes: median 72.0195 s;
  - this head: median 72.108 s.

  Say "this head 72.108 s against 72.019 s" (RESULTS.md has the right order).
- Nothing else to fix. The delta does not mention the research program, its directories, agents or a model name.
  The commit's `Co-Authored-By` trailer is the normal attribution, not body text.

### F5 — Informational: the CI failure on the PR head is unrelated

The "Rust Cross-Platform Build" workflow failed only in Windows-x86_64. rustup could not download
`channel-rust-1.99.1.toml.sha256` (connection reset). Every GPU-parity job passed on `8d11e0be`, including
`cubecl_check_takes_every_entry_on_partly_filled_planes` on lavapipe (WGSL) and on Metal (WGSL and MSL). Re-run the
job.

### F6 — Same assumption elsewhere (question 7; not in this PR, do not fix here)

**`top_slot` (main 1749-1785; branch 1772).** I agree it has the dependence, and it is narrower than the old check
kernel's:

- It does **not** need full planes:
  - `n` and `pre` come from a ballot or a sum and scan over the active lanes;
  - every lane calls it (the slot loop at 2773 runs the same count for every lane of a cube, and nothing returns
    early).
- It **does** need lane 0 to be present:
  - `g0 = plane_broadcast(g, 0)`;
  - only `UNIT_POS_PLANE == 0` takes the group atomic;
  - `at = plane_broadcast(a0, 0) + pre`.
- If lane 0 is absent:
  - **If `one` comes out false** (the undefined `g0` differs from the kept lanes' group), every kept lane takes its
    own atomic. That is correct.
  - **If `one` comes out true**, no lane advances `grp_cnt` and the kept tops are written at `undefined + pre`.
    That means overwritten records and tops the join never reads: silent loss.
  - Nothing on the host counts kept tops, so `ensure_checked` does not cover this stage.
- Devices where it could matter: only Vulkan drivers (wgpu WGSL or cubecl-spirv) that split a 256-wide workgroup into
  a subgroup without lane 0. No such driver is known. CUDA, HIP and Metal give full planes for 256-thread cubes. The
  lowest-set-bit leader plus `plane_shuffle` from this fix would close it.

**Other places that depend on lane 0 or full planes:**

- **Join kernel survivors count** (1066-1068 on the branch; main 1043): `plane_sum(nand)`, then lane 0 adds it.
  Without lane 0 the count is lost. That is telemetry (`survivors`) and the tests' CPU comparison, not candidates.
- **Niceonly stride kernels, main `cubecl_backend.rs` (same on the branch). This is the sharper case.**
  - *Plane-scoped queue* (934, 1040-1080). It is on by default for cubecl-spirv, i.e. the 9070 XT with the SPIR-V
    build, and for CUDA. The drain lane is `UNIT_POS_X % PLANE_DIM`, and each wave drains `PLANE_DIM` entries
    (`if qn >= PLANE_DIM { take = PLANE_DIM }`, then `qn -= take`). On a partly filled plane, the queued survivors in
    the missing lanes' slots are dropped unchecked.
  - *Cube-scoped queue* (1110-1230), the WGSL default. Lane 0 writes the plane's total, and the plane identity is
    `UNIT_POS_X / PLANE_DIM`. A plane without lane 0 leaves a stale total, and a subgroup layout that is not linear
    gives wrong offsets. Either way, survivors are overwritten or skipped.
  - Neither path has an end-to-end count.
  - The new `take_entries`, by contrast, uses only the subgroup ops and the subgroup's own lane id. It never
    identifies planes by `UNIT_POS_X`, so it also does not depend on the subgroup ↔ local-index mapping, which Vulkan
    leaves to the implementation.
  - Exposure: theoretical, like gap 2. Same fix pattern. Suggested as T2 follow-ups.

## What I verified, and how

### Q1: complete and non-overlapping by construction. Yes, in both forms.

**Argument.** A take's participants P are the lanes that execute that dynamic instance of `take_entries`.

- **Ballot form:**
  - word 0 of the ballot is exactly P, provided every lane id is below 32;
  - `rank = popcount(P ∩ [0, lane))` is a bijection P → [0, |P|);
  - the leader is the lane with rank 0, i.e. the lowest set bit, which `(lanes ^ (lanes-1)).count_ones() - 1`
    computes, including bit 31 (0x80000000 ^ 0x7FFFFFFF has 32 ones, so the lead is 31);
  - the leader is in P, so the shuffle source is active.
- **Scan form:** the exclusive scan of 1 is a bijection P → [0, |P|) in lane order, and the sum of 1 is |P|. The sum
  of `got` is the leader's value, since only rank 0 sets it.
- **Both forms:**
  - one `fetch_add(|P|)` per take cuts the counter into disjoint, consecutive ranges, one lane per entry;
  - `cur` is the same for every lane of a take, so a take's lanes stay in the loop or leave it together;
  - a take that starts below `count` checks every entry of its range that lies below `count`;
  - no range is lost, because every lane's last take starts at or past `count`;
  - nothing depends on `cur` being shared across takes, so lanes of one plane that split between calls, or that merge
    from different earlier takes into one call, are handled.
- I agree with the author's argument (RESULTS §2), and I checked it independently.

**My own model** (`CKF/review-model/takes.py`; output `takes.out`).

- Setup:
  - planes of width 4-128 with random populations: full, prefix, no lane 0, random holes;
  - at every take point, a plane's waiting lanes are cut into random groups, and lanes from different earlier takes
    are randomly merged into one group;
  - the groups of all planes interleave randomly on the shared counter;
  - lists of 0 to 3,000 entries;
  - the host check is modelled exactly (count, and index sum mod 2^32).
- Results, 5,000 trials each, seed 7:

  | variant | wrong hand-outs | wrong but passed the host check | other |
  |---|---|---|---|
  | ballot form, widths 4-32 | 0 | 0 | |
  | scan form, widths 4-128 | 0 | 0 | no false alarms |
  | ballot form on a 64-lane plane misreported as 32 (shift masked mod 32 as in WGSL, word 0 only) | 3,446 | 0 | 15 hangs (all participants ≥ 32: `lanes` = 0, `fetch_add(0)`, an endless loop) |
  | scan form, no reconvergence after the leader's `if` | 2,946 | 0 | |
  | ballot form, no reconvergence after the leader's `if` | 2,852 | 0 | |

  Seeds 1-3 agree.
- `exhaustive.py`, for the ballot form's single take:
  - every population of a 16-lane plane (65,535 of them), 200,000 random 32-lane populations, and the edge cases
    {0}, {31} and full;
  - ranks are exactly 0..n-1, there is one leader, and the lead is the leader's lane.

**Can a wrong run pass the host check?** In principle, yes. Any multiset of indices with the same size and the same
sum mod 2^32 as `0..listed` passes, e.g. {0, 0, 3, 3} for {0, 1, 2, 3}. That needs at least two duplicates and two
skips with equal sums. None of the mechanisms I could construct (wrong take size, rank collisions, a misreported width,
missing reconvergence) produces that. Each yields only one-sided errors or a nonzero sum difference. The check also
cannot see a lane that reaches the right index and then computes wrongly. That is audit gap 1 and out of scope.

### Q2: the plane ops per backend (read in `~/.cargo/registry/src/*/`, cubecl 0.10.0 / naga 29.0.4 / wgpu-hal 29.0.4, the `Cargo.lock` versions)

| op | CUDA (`cubecl-cpp` CudaDialect) | HIP | Metal (`cubecl-cpp` MSL) | WGSL (`cubecl-wgpu`) → naga | SPIR-V (`cubecl-spirv`) |
|---|---|---|---|---|---|
| ballot | `__ballot_sync(-1, x)` → `{b,0,0,0}` (`cuda/dialect.rs:623`, `shared/warp.rs:108`) | `uint(__ballot(x))`, truncated to 32 bits (`hip/dialect.rs:555`) | `uint(uint64_t(simd_ballot(x)))`, truncated (`metal/dialect.rs:1037`) | `subgroupBallot` → vec4, word 0 = lanes 0-31 (`wgsl/subgroup.rs:146`) | `OpGroupNonUniformBallot` |
| shuffle (runtime lane) | `__shfl_sync(-1, v, src)` | `__shfl(v, src)` | `simd_shuffle(v, src)` | `subgroupShuffle` | `OpGroupNonUniformShuffle` (always; `Broadcast` with a uniform id is the only one that becomes `OpGroupNonUniformBroadcast`, `subgroup.rs:86-101`) |
| sum / exclusive sum | butterfly `shfl_xor` / `shfl_up` loop over all lanes (`shared/warp.rs:285-345`) | same, over 64 on wave64 | `simd_sum` / `simd_prefix_exclusive_sum` (active lanes) | `subgroupAdd` / `subgroupExclusiveAdd` | `OpGroupNonUniformIAdd` Reduce / ExclusiveScan |
| lane id | `AbsolutePos % warpSize` (`shared/dialect.rs:375`) | same | `simd_lane_id` | `subgroup_invocation_id` | `SubgroupLocalInvocationId` |

- Inactive lanes:
  - excluded on WGSL, SPIR-V and Metal by definition ("non-uniform" ops over the active invocations);
  - on CUDA, `__ballot_sync` clears the bits of inactive lanes;
  - the C++ butterfly sums are defined only on full warps or waves (they shuffle from every lane). That is why CUDA
    and HIP need full planes for the scan form. Production's 256-unit cubes give them, and since CUDA's `-1` masks
    force the warp to converge, all lanes share every take.
- Ballot width:
  - every backend returns only lanes 0-31 in the word the kernel reads;
  - the ballot form is therefore gated on `ballot_append(plane_size_max) = plane_size_max <= 32` (157);
  - `plane_size_max` comes from: CUDA `warp_size` (`cubecl-cuda runtime.rs:151`); HIP `prop_warp_size` (wave32 on
    RDNA, 64 on CDNA); wgpu the adapter's `subgroup_max_size`, hard-coded 32 only under `cfg(apple_silicon)`
    (`cubecl-wgpu runtime.rs:297-307`).
- wgpu enables `SUBGROUP` only with Vulkan's SHUFFLE and SHUFFLE_RELATIVE (`wgpu-hal-29 vulkan/adapter.rs:872-886`),
  as the author says.
- No `REQUIRE_FULL_SUBGROUPS` is set anywhere in wgpu-hal.
- `cubecl-opt` does not number, fold or hoist plane ops (`gvn/numbering.rs:124` treats them as opaque), so the two
  `take_entries` calls cannot be merged or hoisted out of the loop.

**The AMD Vulkan device (64-lane planes, scan form): what its correctness rests on.** It was never run there.

1. *Selection.* RADV reports `maxSubgroupSize` = 64, so `ballot_append` is false and the scan form runs **[A]**. The
   scan form uses no lane id and no width, so it is right for wave32 or wave64 alike. Only a device that reports 32
   while running 64 would be wrong; that would be caught by the sum or would hang (F3, model).
2. *Meaning.* naga emits `subgroupExclusiveAdd` / `subgroupAdd` as `OpGroupNonUniformIAdd` with the subgroup scope.
   Vulkan defines these over the active invocations of the dynamic instance, for any width and any holes **[R]**.
3. *Driver implementation.* ACO and AMDVLK compute subgroup scans and reductions with the inactive lanes set to the
   identity (whole-wave mode). This is the standard technique and is needed for any partial wave **[A, not read
   here]**.
4. *Reconvergence after the leader's `if` (F3).* Nothing requests it. On AMD, structured divergence is EXEC-mask
   based, and the pre-`if` mask is restored at the merge, so it holds in practice **[A]**.
5. *Exercised:*
   - the scan form on lavapipe, 8-lane, WGSL and SPIR-V, effectively full planes;
   - the scan form in the partial-plane test on the macOS Metal VM, 32-lane, where whether a plane was partial is
     unrecorded (F2);
   - CUDA on full warps.

   Never on a 64-lane plane, never on RADV.
6. *If any of 2-4 fails:* my model and the host check give a field error or a hang, not a silent loss.

### Q3: the host check

- Comparison:
  - `ensure_checked` (4200) compares `ran[STAGES+1]` with `min(checked, list_cap)` and `ran[STAGES+2]` with
    `listed·(listed−1)/2 mod 2^32`, computed in u64;
  - the kernel compares the same quantities on its side: `count = min(surv_count, surv_cap)` with
    `surv_cap = list_cap`, read from the same per-batch `checked` buffer (3998-3999);
  - the kernel's sums wrap mod 2^32 on every backend (u32 add and atomic add).
- Every production launch is covered:
  - `launch_check` is reached in production only from `launch_batch`;
  - `launch_batch` is called only from `run_pass` (4671) and `run_partition` (4751), and both call `ensure_checked`
    after `ensure_ran` (4697, 4757);
  - in `run_pass` that includes overflowed batches (listed = `list_cap`); batches that failed `ensure_ran` are skipped
    and re-run, and their counts are not trusted;
  - the test helpers call it too (5035, 5835), and `run_check` asserts the same quantities (5617-5624).
- A mismatch is always an error:
  - it is an `anyhow` error, not `NotRun`, so `rerun_partition`'s `downcast::<NotRun>()?` passes it through
    (4622) and `refit` never sees it;
  - `run_field` → `finish_on` → `finish_niceonly` → client `main.rs:986-991` logs it and `exit(1)`s;
  - there is no retry, no empty result, and no partial hits submitted.
- Nothing is read before the kernel finishes. `run_pass` reads every batch's three handles in one `read_async` after
  all launches, and `run_partition` uses `read_one`. Both are ordered after the submitted work on the client's queue.
  The kernel's `fetch_add`s happen before `cube_done`.
- The skip mode cannot leak into a production build:
  - the bit is ORed in only under `#[cfg(test)]` (4092-4097), from a `cfg(test)` thread-local;
  - production modes are `CHECK_HITS` or `CHECK_PROBE`, and `skip_first` is comptime, so the skip code is not even
    emitted;
  - `mode` is shadowed with the bit cleared (3303), so the mode comparisons are unaffected.

### Q4: nothing else changed

- `git diff bc9d87c7 8d11e0be` touches one file. In the kernel it touches only the hand-out (take, loop header,
  `live`, `done` / `isum`, the final adds).
- The digit arithmetic, the gate, the hit path and the join, bucket and top kernels are unchanged. The other kernels
  get a longer `ran` (`RAN_WORDS`), which `ensure_ran` slices to `STAGES`.
- `launch_check` gains a `wg` argument, which is `JOIN_WG` in production.
- Cost: 39/40 → 47 registers at b62/b64 (`ptxjit.out` confirms), with no measurable effect on a field.

### Q5: the tests

- `check_partial_planes` fails on the old hand-out **on CUDA**. The author's repro patch is the same lists, cube
  sizes and assertions; I re-summed `repro_cuda2.log`: 63 runs, 218,772 entries, 34,296 skipped.
- On CI devices that is not shown (F2).
- The assertions match the write-up:
  - zero words mean an unchecked entry in count mode;
  - the kernel's count and index sum are compared;
  - the work-counter bounds are `[cap + cubes·wg, cap + 128 + cubes·round128(wg))`, with `cubes` forced to 1 for
    non-multiple-of-32 cubes on CUDA and HIP.
- The skip-first test fails the field on both paths, but only through the count (F1).

### Q6: the write-up against the raw evidence

- Speed table: every number re-derived from `raw/box/logs/*.log` `device=` values.
  - b62 spill-free medians: B 71.965 (r1-r4, r6), F 72.030 (r1, r2, r5, r6).
  - Spill runs: B r5 73.751; F r3 73.755 and r4 73.807.
  - b60 9.197 / 9.216 / 10.082; b64 149.730 / 149.393 / 158.327. All match.
- Registers: 39 → 47 (b62), 40 → 47 (b64), 39 → 39 (b60), confirmed in `out/ptxjit.out`.
- Exactness claims checked against the logs:
  - CUDA check counts: "64 lists, 1168717 list entries … 84652 synthetic n over 22 shapes (3047 past the gate),
    [(256, true), (100, true), (256, false)]" ✓;
  - CUDA partial warps: 84 runs ✓;
  - lavapipe WGSL and SPIR-V partial planes: 168 runs, 10 passed each ✓;
  - dense b62 ok ✓;
  - the per-shape repro counts (896 at 100 units; 1,008, or 1,011 at b60, at 48 units) ✓.
- Fairness about untested hardware: RESULTS §6 and the delta's own text say plainly that the scan form never ran on a
  64-lane device, that Metal and HIP were not run by the author, and that the misreport case is argued, not run. The
  Metal CI run was not mentioned (it now exists, see F5).

### Host-side checks run here

- `cargo fmt --all --check`: clean.
- `nice -n 19 cargo clippy -p nice_common --all-targets --features cubecl -- -D warnings`: clean.
- `cargo test -p nice_common --features cubecl --lib cubecl_join`: 7 passed, 10 ignored (they need a device).
- All with `CARGO_TARGET_DIR=~/projects/nice/.worktrees/rebase-1112/target`.

## What could not be verified without hardware

- The scan form on any 64-lane device (RADV/AMDVLK on RDNA, HIP wave64), and in particular on a real partial wave.
- Whether any shipping Vulkan driver ever splits a 256-wide workgroup into partial subgroups, or into one without
  lane 0. This decides whether the original defect, `top_slot`, and the niceonly queues (F6) are ever live.
- Reconvergence at the take's internal merge on each driver (F3). It was argued, not observed.
- Whether the macOS Metal VM's 100- and 48-unit runs contained partial simdgroups (F2).
- One possible problem I could not settle: CubeCL's SPIR-V backend decorates values its uniformity analysis calls
  uniform with `Decoration::Uniform` (`cubecl-spirv instruction.rs:466`). That analysis treats a plane reduction as
  uniform in uniform blocks, and subgroup reductions differ across the subgroups of a workgroup. I did not establish
  whether that decoration lands on the take's sum or ballot, or whether any driver acts on it. This predates the fix:
  the old `plane_broadcast` result had the same marking.

Artifacts: `CKF/review-model/takes.py`, `exhaustive.py`, and their outputs `takes.out` and `exhaustive.out`.
