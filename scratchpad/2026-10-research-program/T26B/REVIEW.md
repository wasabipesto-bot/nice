# Review: `pr/stride-queue-any-plane` (`85fe64af` on main `41b4b405`), the stride walk's survivor queues without full-plane assumptions (2026-11-14)

Independent review. I read the diff and the kernel and host code in a detached worktree
(`~/projects/nice/.worktrees/review-t26b` at `85fe64af`), CubeCL 0.10.0, cubecl-wgpu 0.10.0 and wgpu-hal 29
sources in `~/.cargo/registry`, the author's write-up and raw logs, and CKF/T26's reviews. I wrote my own model of
both queues (`T26B/review-model/qmodel.py`) before reading the author's. On the RTX 3080 box I built every binary
I rely on myself from `git archive` trees of `85fe64af` and `41b4b405` in `/root/rv` (own target dirs), ran the
new tests, main's reproduction, extended and multi-cube variants of the new test, and two interleaved timing
pairs. Logs and binaries' md5s are in `T26B/review-box/`. I did not read the author's model.

## Verdict: open after the listed fixes

The fixes are to the text only (PR body: F1, F2, F3; changelog placeholder: F5). **The code is right.** I found no
population of a plane, in either queue or either rank form, for which a queued survivor goes unchecked, is
checked twice, is written over before it is checked, or is written outside its plane's reservation or the shared
arrays. The loops terminate, and the control flow that must be plane-uniform (plane-scoped) or cube-uniform
(cube-scoped, around both `sync_cube`s) is. The alternating-word argument of the cube-scoped queue holds, and my
model shows it is load-bearing (a single word fails in almost every launch when the units' operations between
barriers are interleaved). On full planes the checked set equals main's (only which lane checks which survivor
changes), and hits are sorted on the host, so nothing downstream sees a difference. The account is computed from
the two independent sides (registers at enqueue, the slot actually read at check), is read on every path that runs
the kernel, and fails the field like an output overflow. My builds of the commit are byte-identical to the author's
(F `faf328f4`, FS `c20692b7`).

**Required before opening (text only):**
1. Body, Exactness row 1: the RTX 3080 runs are exact for the ballot form; the scan form on partly filled CUDA warps
   is undefined (CubeCL's CUDA scans read every lane) and fails at other sizes, caught by the account (F1). Correct
   RESULTS §2's "both forms ran exact" bullet the same way.
2. Body, Cost: "the scan form, forced on the RTX 3080, costs about 0.6 %" (not "64-lane devices"); "not measured at
   the default power limit"; and that the stride walk is the join's fallback in production (F2).
3. Body, "Not in this PR", llvmpipe bullet: add that the account does not catch it there either (F3).
4. Changelog: replace `#NNN` after opening (F5).

Optional: F3's per-plane report for the plane-scoped queue, F4's squares word (only together with #260), F6's `lt`
placement, and Q6's wording for the generated-code claim.

## Findings

### F1: Low (PR body and RESULTS accuracy). The CUDA test's scan form is undefined on partly filled warps; "64 runs exact (ballot and scan)" holds only for the sizes chosen

- **Where:** PR body, Exactness table, first row ("one cube of 256/100/48/36, both queues, ballot and scan |
  64 runs exact"); RESULTS §2 per-backend bullet ("On partly filled warps in one cube both forms ran exact here");
  the test knob `NICE_TEST_QUEUE_SCAN` in `cubecl_cuda_queues_check_every_survivor_on_partly_filled_warps`
  (`common/src/cubecl_backend.rs` 4318).
- **What I found:** I ran the committed test with 15 cube sizes instead of 4 (256, 255, 200, 129, 100, 65, 63, 48,
  36, 33, 31, 17, 9, 2, 1; binary FX = the commit with only that list and a `max(1)` guard changed, test code only)
  on the RTX 3080 with `NICE_TEST_QUEUE_SCAN=1`: 240 runs, 36 wrong (`review-box/logs/FX_cuda.log`).
  - **Ballot form (production on CUDA): every one-cube run exact**, both queues, every size, both windows.
  - **Scan form, plane-scoped queue: 24 of 60 runs wrong** at 255, 63, 31, 17 and 9 units (last warp 31, 31, 31,
    17, 9 lanes; counts off by −2,960 … +12, one run with the count right and only the low-word sum off). The
    author's sizes leave last warps of 4 and 16 lanes, where CubeCL's `shfl_xor`/`shfl_up` butterflies happen to
    stay inside the present lanes; on other sizes they read absent lanes, which CUDA leaves undefined.
  - The remaining 8 wrong runs (both queues, both forms) are cubes of 1 and 2 units with 4 lanes per range, i.e.
    **multi-cube** launches with cubes that are not whole warps: CubeCL's CUDA lane id `AbsolutePos % 32` is wrong
    past the first cube (the known limitation the test's comment already names). Test artefact, not the fix.
  - **The account caught all 36** ("checked N fewer", both signs, and once "low words differ" with the count equal).
- **Impact on production:** none. CUDA always takes the ballot form (`ballot_append(32)`) and launches 256-unit
  cubes. Metal, WGSL and SPIR-V define their scans over the active lanes. HIP's butterflies have the same
  limitation as CUDA's but HIP gets full waves from 256-unit cubes. The finding is about what the body claims.
- **Fix (text):** in the body's first Exactness row, say "ballot form" for the RTX 3080 (or "ballot form; the scan
  form only on full warps: CubeCL's CUDA scans read every lane"), and correct RESULTS §2's bullet. Optionally add a
  one-line comment at the `NICE_TEST_QUEUE_SCAN` knob that the scan form is defined on CUDA only for whole warps.
  These 36 runs are also the best evidence the account works on real device faults; worth one sentence in the body
  ("on CUDA's scan form over partly filled warps, which is undefined and never selected, the account failed every
  wrong run").

### F2: Low (PR body). The cost section needs three qualifiers

- **Where:** PR body, Cost and "What a wgpu device should expect".
- **What I found:**
  1. "The scan form (64-lane devices) costs about 0.6 % on the plane-scoped queue" was measured by forcing the scan
     form on the RTX 3080's 32-lane warps, where CubeCL emulates both scans with shuffle chains. It is the cost of
     the fix's extra arithmetic and account at main's plane-operation count, which is the right quantity in kind, but
     not "the way a 64-lane device would run it" (hardware subgroup reductions, different register budget and
     occupancy, 4 planes per cube instead of 8 in the cube-scoped queue). The wgpu section says "as measured on
     CUDA", the Cost paragraph does not. **Fix:** "The scan form, forced on the RTX 3080, costs about 0.6 %".
  2. All timings are at the host's 130 W cap (the body says so) where main ran at 1,120-1,160 MHz and the fix at
     1,380-1,415 MHz: part of the ×1.14 is clock bought by fewer shuffles under the cap. Fleet cards run at their
     default limits; the gain there is not measured. **Fix:** add "not measured at the card's default power limit;
     part of the gain here is clock".
  3. Since the overlap join, the stride walk runs only for the fields the join does not take (`StrideReason`: base
     outside 40-64, field below the join's minimum size, digit-length change, too wide, device too small, no plane
     ops, hand-CUDA) or when forced; every timing here forces it with `NICE_JOIN_ROUTE=stride`. The body puts that in
     the method line but a reader of "×1.14 / NiceMark ×1.23" will read a client speed-up. **Fix:** one clause: "on
     the stride walk, which production uses only for fields the join does not take".
- My own interleaved pair (own builds, author's harness and field list) is in "What I verified", Q6.

### F3: Low (PR body; optional code). The account is not unconditional: on llvmpipe it missed the plane-scoped queue's losses

- **Where:** body "What" ("fails the field if a queue checks fewer survivors than it queued"), "Not in this PR";
  code `report_queue_account` (`common/src/cubecl_backend.rs` 1596-1616).
- **What I found:** the author's own `FS_lvp_faults.log` shows the skip fault passing unnoticed with the plane-scoped
  queue on llvmpipe (RESULTS §1.3, §3, §7). The account's last step is a cube barrier followed by unit 0's read of
  the shared sums; on a driver that releases that barrier early (llvmpipe's subgroup barrier interacting with its
  workgroup barrier, as the author infers) unit 0 reads partial sums. So the check fails open together with the
  queue there. Production never runs that combination (`is_software_rasterizer`), and nothing suggests RADV, NVIDIA
  or Apple drivers do this.
- **Fix (text, required):** the body's "Not in this PR" llvmpipe bullet should add that the account does not catch
  it there either (its report relies on the cube barrier that llvmpipe mishandles). One clause.
- **Optional code (not required):** in the plane-scoped queue a plane checks only what it queued, so its own sums
  are zero on a correct run. Its report could therefore be per plane and need no cube barrier: `plane_sum` of the
  two words after the loop, and the lowest running lane adds them to `nice_count[1..3]` if either is non-zero
  (still no global write on a correct run; two plane sums per plane per launch). That removes the plane-scoped
  kernel's final `sync_cube` and makes its check independent of how a driver orders a workgroup barrier after
  subgroup barriers. The cube-scoped queue moves survivors between planes, so it needs the cube sum; it already
  depends on cube barriers for the queue itself, and runs exact on llvmpipe. Worth doing only if a real driver
  shows llvmpipe's behaviour; not required for this PR.

### F4: Low (robustness of the check). Count and low-word sum, per field: cancelling errors pass

- **Where:** `report_queue_account`, `queue_complete` (3194).
- **What I found:** as CKF and T26 found for their accounts: a wrong drain that checks one entry twice and leaves
  another with the same low 32 bits unchecked passes; so do errors of opposite sign in different cubes or launches
  of one field, because the words accumulate over the field. T26 measured this gap at 0.6 % of wrong launches for
  its worst modelled fault and suggested a squares word; #260 kept count + sum. This branch is consistent with #260.
- **Fix:** none required. If #260 adopts a squares word, do the same here (one more register and word).

### F5: Nit. Changelog placeholder

- **Where:** `CHANGELOG.md` line 23, `([#NNN](https://github.com/wasabipesto/nice/pull/NNN))`.
- The line is accurate, one sentence and user-facing. Replace `NNN` with the PR number after opening (as #260's
  follow-up commit did).

### F6: Nit (code). `lt` is computed on every device, including 64-lane planes in the scan form

- **Where:** `let lt = (1u32 << UNIT_POS_PLANE) - 1u32;` at 957 (plane-scoped) and 1233 (cube-scoped).
- On a 64-lane plane in the scan form, lanes 32-63 shift by ≥ 32 (WGSL masks the amount; SPIR-V gives an undefined
  value; C++/HIP would be undefined behaviour). The value is dead in the scan form, so nothing reads it, and main's
  `top_slot` computes the same mask inside its ballot branch. **Fix (optional):** compute it inside the
  `comptime!(ballot)` branches, as `top_slot` does.

### F7: Informational. Scope, dependencies and merge

- One discrete change: the same defect class in one kernel, one remedy, one account shared by both queues. Splitting
  would leave the account half-built. It stands alone on main: it uses `ballot_append` (on main since `cubecl_join`'s
  `top_slot`) and nothing from #251 or #260.
- **The brief's premise about "as `top_slot`" does not hold:** main's `top_slot` already has the ballot form
  (`cubecl_join.rs` 1757-1776 at `41b4b405`: `#[comptime] ballot`, `plane_ballot`, `popcount(b0 & lt)`), gated on
  the same `ballot_append`. What main's `top_slot` lacks is the lowest-lane leader (it uses lane 0 and
  `plane_broadcast(.., 0)`); the body does not claim otherwise. "Remaining assumptions, as in `top_slot`" (reconvergence
  after the leader's `if`, lane id = ballot bit) is also true of main's `top_slot`. No wording change needed.
- `git merge-tree` of this branch with `fork/pr/check-d` (`1f41d649`) and with `fork/pr/top-slot-any-plane`
  (`9c27023b`): the only conflict is `CHANGELOG.md` (each adds a line at the same place), trivial either order. Both
  keep `ballot_append` with the same signature.

## What I verified, and how

### Q1: complete and non-overlapping by construction. Yes, both queues, both forms

**Argument (mine, from the code at 925-1195 and 1196-1458).** P = the lanes of a plane that run one dynamic instance,
n = |P|; `pf` is 0 or 1 per lane per iteration (one candidate ordinal per lane, 1068-1094).

- *Ranks.* Ballot form: on planes of at most 32 lanes word 0 of the ballot is exactly P (inactive bits clear on every
  backend, CKF/T26 tables, re-read below), so `popcount(bl & lt)` maps P onto 0..n and `popcount(bp & lt)` maps P's
  survivors onto 0..tot. `lead = (bl ^ (bl-1)).count_ones() - 1` is ctz(bl) (right for bit 31 too), a lane of P, so
  `plane_shuffle(got, lead)` reads an active lane. Scan form: fields do not carry (plane-scoped: survivors < 2^16,
  lanes above; cube-scoped: survivors in bits 0-9, lanes with ranges in 10-19, lanes from bit 20; at most 128 lanes per
  plane and 256 per cube, so every field stays below 1024 and `ex >> 20` < 2^12). `plane_sum(got)` has exactly one
  non-zero term.
- *Plane-scoped reservation.* After `clear_queue_account` and one `sync_cube`, each plane's rank-0 lane takes `2n`
  slots with one `fetch_add`: disjoint, summing to 2·CUBE_DIM_X ≤ 2·WORKGROUP_SIZE = 512 = the arrays' size, for any
  cut of the cube into planes (`cube_dim()` clamps the test override to 256).
- *Plane-scoped bound.* With n constant, qn < n at the top of every iteration (0 at start; a full wave leaves
  qn − n ≤ n − 1; `done` empties it), so the writes `qbase + qn + idx` < `qbase + 2n`. n is recomputed per iteration
  from the running lanes; it can only differ from the reservation's if lanes drop out (they cannot join: the
  reservation follows a cube barrier with every lane present). If it shrinks, qn + tot ≤ (previous bound) + n_i stays
  ≤ 2n₀ − 1, because qn never grows across an iteration in which tot ≤ take. So the queue cannot hold more than it
  reserved under any shrinking population either.
- *Plane-scoped drain.* A wave checks positions `qn − take .. qn − 1` once each (rank < take, ranks distinct), then
  forgets exactly those; the loop leaves only on `done && qn == 0`. `qn`, `take` and `done` are plane-uniform (from the
  plane's ballot/sum and `plane_all`), so both `sync_plane`s and the exit are plane-uniform. The only cube barriers are
  before the loop and in `report_queue_account` after it, both reached once by every unit.
- *Cube-scoped offsets.* Between barrier 1 and barrier 2 every plane's leader adds `tot | lanes_with_ranges << 10` to
  word w = it & 1; the old values cut [0, incoming) into disjoint per-plane ranges, so `qn + off + idx` fills
  `qn .. qn + incoming` without collision; qn < CUBE_DIM_X at the top, so qn + incoming ≤ 511.
- *Alternating words.* Word w of iteration i: cleared by unit 0 after barrier 2 of i−1 (or by `clear_queue_account`
  before barrier 1 of iteration 0), added to after barrier 1 of i, read after barrier 2 of i, next cleared after
  barrier 2 of i+1. Between each step and the next there is a barrier in every unit's program order: the clear in
  iteration i (of word 1−w) follows barrier 2 of i, the last reads of word 1−w were before barrier 1 of i, and its
  next adds follow barrier 1 of i+1. So no unit reads a word before every plane has added to it, and none after it has
  been reset. `incoming` and `all_done` come from one shared word read after a barrier, so the drain size and the
  exit are cube-uniform.
- *Termination.* Every iteration either advances some lane's cursor or has every lane done; with every lane done
  the queue drains by `take = qn` (cube) or `take = qn` per plane, and the loop leaves.

**Model (mine, `review-model/qmodel.py`, `qmodel_seed1.out`, `qmodel_seed2.out`).** Both queues as written, over a
512-slot array, cubes of 1-256 units cut into planes of 8/16/32/64 lanes; populations: full, last plane partial,
lanes not linear in `UNIT_POS_X`, planes without lane 0, random holes and sizes; per-unit range lengths 0-80 and
survivor densities 0-1; plane-scoped planes run independently with reservations in random order; in the cube-scoped
queue, every unit's operations between barriers (fetch_adds, writes; loads of the word, unit 0's clear, drain reads)
are interleaved at random. Checks: each survivor checked once, no write outside the array or into another plane's
reservation, no overwrite of an unchecked entry, uniform `qn`/`all_done`, termination.

| | full | partial | not linear | no lane 0 | holes |
|---|---|---|---|---|---|
| plane-scoped, the fix (500 launches each, seeds 1-2) | 0 wrong | 0 | 0 | 0 | 0 |
| cube-scoped, the fix | 0 | 0 | 0 | 0 | 0 |
| mutation: plane-scoped takes the plane width instead of its running lanes (control) | 403 wrong | 387 | 388 | 492 | 496 |
| mutation: cube-scoped with one word instead of two (control) | 497 | 493 | 500 | 498 | 499 |

The second control is the point of the alternating words: with one word, unit 0's clear races other units' reads
between barrier 2 and the next barrier 1, and `qn`/`all_done` stop being uniform.

### Q1 on the device: the new test, my builds, more sizes, more cubes

| binary (built here) | device | run | result | log |
|---|---|---|---|---|
| F (`85fe64af`, gpu; md5 `faf328f4` = author's F2) | RTX 3080 | new CUDA partial-warp test, `NICE_TEST_QUEUE_SCAN=1` | **64 runs, 0 wrong** | `cuda_partial.log` |
| F | RTX 3080 | CUDA fault test | each fault fails the field with its message ("41 fewer" / "6 fewer"; low words 439835 / 248052), clean run passes | `cuda_faults.log` |
| F | RTX 3080 | `cubecl_cuda_matches_cpu_niceonly` | pass | `cuda_parity.log` |
| F / FS (gpu,cubecl-spirv; `c20692b7` = author's F2S) | lavapipe WGSL / SPIR-V | new partial-plane test | **32 runs, 0 wrong** each | `lvp_partial.log`, `lvpS_partial.log` |
| F / FS | lavapipe WGSL / SPIR-V | fault test | pass | `lvp_faults.log`, `lvpS_faults.log` |
| F | host | `queue_complete_wants_every_queued_survivor_once` | pass | |
| R / RS (main `41b4b405` + author's `make_repro.py`, tests only, with `plane_queue_runs` replaced by `[false]`) | RTX 3080 | main, same test | **24 of 32 wrong**: plane-scoped 1,064 / 5,072 / 2,958, cube-scoped 1,217 / 10,152 / 3,382 lost at 100/48/36 (b50), exactly the author's numbers | `R_cuda.log` |
| R / RS | lavapipe WGSL / SPIR-V | main, cube-scoped | **8 of 16 wrong** each (1,217 and 3,382 lost at 100 and 36) | `R_lvp.log`, `RS_lvp.log` |
| FX / FXS (the commit, test only: 15 cube sizes 256…1 and a `max(1)` on the range count) | lavapipe WGSL / SPIR-V | cube-scoped, both forms | **120 runs, 0 wrong** each | `FX_lvp.log`, `FXS_lvp.log` |
| FX | RTX 3080 | both queues, both forms | ballot form: every one-cube run exact; scan form and multi-cube non-whole-warp runs: see F1 (36 wrong, all caught by the account) | `FX_cuda.log` |
| FY (FX + `NICE_REVIEW_CUBES=3`: three cubes per launch) | lavapipe WGSL | cube-scoped, both forms, 15 sizes, 3 cubes of partly filled subgroups | **120 runs, 0 wrong** | `FY_lvp3.log` |

The multi-cube runs matter because the committed test launches one cube only (for CUDA's lane id); on wgpu the lane
id is right in every cube, so partly filled subgroups in every cube of a launch are a legitimate population, and it
is exact.

### Q2: per backend

Re-read in `~/.cargo/registry` (cubecl-cpp/-spirv/-wgpu 0.10.0, wgpu-hal 29.0.4); the op table of CKF/T26 holds for
the ops this commit uses (`plane_ballot`, `plane_shuffle` with a runtime lane, `plane_sum`, `plane_exclusive_sum`,
`plane_all`, `sync_plane`, `sync_cube`, shared `Atomic<u32>` `fetch_add`/`load`/`store`):

- **CUDA:** `__ballot_sync(-1, ..)` (inactive bits clear, but the full mask needs the whole warp present),
  `__shfl_sync(-1, v, src)`, sums as `shfl_xor`/`shfl_up` loops over all 32 lanes (undefined with absent lanes: F1
  shows it), lane id `AbsolutePos % 32` (right only when every cube is whole warps). Production: 256-unit cubes,
  ballot form. Correctness rests on full warps, which production guarantees.
- **SPIR-V (`cubecl-spirv`, the 9070 XT's plane-scoped build):** `OpGroupNonUniformBallot/Shuffle/IAdd` over the
  active invocations; `sync_plane` = subgroup control barrier. Selection: wgpu-hal reports `maxSubgroupSize` from
  `VK_EXT_subgroup_size_control` (or 128 without it), RADV's is 64, so the scan form runs [A: not run on the card].
  Rests on reconvergence after the leader's `if` (as main's `top_slot`; nothing requests maximal reconvergence).
- **WGSL through naga (Vulkan, Metal, DX12; the cube-scoped queue):** `subgroupBallot` word 0, `subgroupShuffle`,
  `subgroupAdd`/`subgroupExclusiveAdd` over active invocations; workgroup atomics. Ballot form wherever the adapter's
  `subgroup_max_size` ≤ 32 (NVIDIA and Intel Vulkan, Intel DX12), scan form elsewhere (AMD 64, Vulkan without size
  control 128).
- **Metal:** cubecl-wgpu hard-codes `plane_size_max = 32` under `cfg(apple_silicon)` (`runtime.rs` 297-307; wgpu-hal's
  own Metal report is 4..64), so an M4 takes the ballot form: `simd_ballot` (low 32 bits), `simd_shuffle`. Apple GPUs'
  SIMD groups are 32 wide, so that is right; an Intel Mac with an AMD GPU would report 64 and take the scan form.
- **The choice is made at run time** from the device's reported maximum (`NiceonlyPlan::build`, 3021), and it is safe
  in the direction that matters: a device whose actual subgroups vary in size can only be given the ballot form if
  its maximum is ≤ 32, and the ballot form is right for any width ≤ 32.
- **Remaining assumptions, unchanged from main's `top_slot`:** reconvergence between a ballot/scan and the following
  shuffle/sum; `UNIT_POS_PLANE` is the ballot bit. A device that broke either would most likely trip the account
  (T26's model: 0 of 9,238 non-reconvergence launches undetected), except under F3's llvmpipe-like barrier behaviour.

### Q3: full planes (every production launch today)

On full, linear planes the ballot form's rank is `UNIT_POS_PLANE` = main's `UNIT_POS_X % PLANE_DIM`, positions and
counts equal main's scans, the plane-scoped take is n = PLANE_DIM as on main, and the cube-scoped drain is main's.
What changes is only where a plane's queue sits (atomic order instead of `PLANE_POS`) and, in the cube-scoped queue,
the order of the planes' regions (atomic order instead of plane index), so which lane checks which survivor changes,
not which survivors are checked. Hits are appended with an atomic and sorted on the host (`read_niceonly_hits`);
nothing downstream depends on order. The author's production-scale runs (120 b54 fields of 1e13 and 6 NiceMark
sweeps, found 0 on both sides, no account error) and my timing pair (found 0 on both sides, no error) agree.

### Q4: the account and the host check

- **Two independent sides:** +1 and +low word from registers (`cand_lo`) at enqueue; −1 and −low word read from the
  slot the drain actually reads (`q_lo[s]`), immediately before `candidate_check(q_lo[s], ..)`. An overwritten or
  re-read slot therefore changes the sum, a skipped one the count.
- **Read on every path:** the kernel has one launch site (3394) and one count buffer per field (`from_plan`, 3099,
  three words, zeroed); both readers, `CubeclPendingField::wait` (production, NiceMark, the harness) and `finish`
  (tests), go through `read_niceonly_hits`, which calls `queue_complete` before anything else. The error propagates
  through `complete_field` (`gpu_niceonly.rs` 1123-1129) like the overflow error: the field fails and reports
  nothing. The hand-CUDA kernel has its own one-word buffer and is untouched.
- **No false alarm** on a correct run: the sums are exact mod 2^32 whatever the wrap; an uncompacted dispatch never
  writes the words; a field with no survivors adds nothing; output overflow does not skip the account (the check is
  counted before `candidate_check`). No new reader collides with word 0.
- **What passes:** F4 (equal count and low-word sum, or cancelling errors across cubes/launches), and F3 (a driver
  that releases the report's cube barrier early).

### Q5: tests, knobs, CI

- New tests fail on main and pass on the branch (Q1 table), on CUDA and on lavapipe with both compilers.
- Knobs: `ballot_override`, `cube_dim_override`, `test_bits` are `#[cfg(test)]` fields; `cube_dim()` and
  `test_bits()` return `WORKGROUP_SIZE` and 0 outside `cfg(test)`; `test_bits` is comptime, so production code has
  no fault branch; `NICE_TEST_QUEUE_SCAN` is read only inside a `#[test]` fn. Nothing reaches a release build or a
  user's environment. The pre-existing production knob `NICE_CUBECL_PLANE_COMPACT` is unchanged (still refused on
  software rasterizers).
- CI (`.github/workflows/gpu-parity.yml`): lavapipe runs all ignored `nice_common` tests (WGSL, line 62) and
  `cubecl_` with `cubecl-spirv` (103); macOS runs WGSL unfiltered (119) and MSL with `cubecl_` (126). Both new wgpu
  tests match. The CUDA tests are manual, as before. On lavapipe the plane-scoped queue is skipped (`plane_queue_runs`)
  and says so; on Metal with MSL, if CubeCL reports plane sync there, Metal CI will be the first run of the
  plane-scoped queue on partly filled simdgroups (not run by the author or me).

### Q6: speed and cost claims

- **Against the raw logs:** every b54 time in RESULTS §5 and the body (`s54_*`, `s54scan_*`, `c54_*`: 73.441 …
  93.421 s, found 0) matches its log, with the binary md5 named in each log's first line; NiceMark scores and
  per-scenario ratios recompute from `nm_*_r*.json` (scores 94.13 … 118.69; ×1.261, 1.210, 1.214, 1.192, 1.270,
  1.248; medians of six 95.10 / 117.36 = ×1.234). NiceMark's API address was `127.0.0.1:9` in every JSON (no
  production contact).
- **b58 msd-strong:** per-round ratios 1.062, 1.020, 0.942, 0.984, 1.079, 1.034. The "×1.02 median" is the ratio of
  the medians; the median of the per-round ratios is ×1.027. Either way the body's account ("CPU rejection; rounds
  spread 8 % on both sides, one of six at ×0.94") is fair: main's own six rounds span 8 %, and the GPU has almost no
  work in that window.
- **Scan-form cost:** see F2.1. Measured fairly for what it is (interleaved, cooled, five rounds, inside main's 5 %
  spread), but on a 32-lane CUDA warp with emulated scans.
- **"Every other kernel's generated code is identical to main's":** the method (CubeCL's full CUDA compile log of a
  production join run and CI's WGSL lint dump, per-kernel diff after renaming numbered locals and shared arrays in
  order of first use and sorting declarations) is sound for identity of what it compared: six CUDA join kernels and
  14 WGSL shaders. It did not compare SPIR-V, MSL, or CUDA's detailed kernels; for those the evidence is that their
  sources are untouched (the diff changes `niceonly_kernel` and adds four helpers it alone calls). Suggested body
  wording: "The other kernels' sources are untouched; their generated CUDA (join kernels) and WGSL (CI's lint
  shaders) compare identical to main's."
- **My interleaved pairs** (own builds MT = main + the author's `add_harness.py`, FTH = the commit + the same harness,
  no knobs; the author's b54 field list, 40 × 1e13 from `2778136280153679229`, `NICE_JOIN_ROUTE=stride`, card at
  ≤ 40 °C before each run, no builds or tests running, 130 W cap; `review-box/out/timing.out`, `logs/t_*`, `c_*`):

  | queue | run order | main s | fix s | main / fix | SM MHz, util (main → fix) |
  |---|---|---|---|---|---|
  | plane-scoped (CUDA default) | M F F M | 81.398, 83.412 | 72.438, 72.398 | ×1.124, ×1.152; **×1.138** of medians | 1,110-1,140, 82-83 % → 1,410-1,425, 60-61 % |
  | cube-scoped (`NICE_CUBECL_PLANE_COMPACT=0`) | F M | 94.202 | 73.555 | **×1.281** | 1,245, 84 % → 1,328, 78 % |

  Found 0 on every run, no account error. Both reproduce the author's ×1.14 and ×1.26 within run-to-run spread. The
  fix's runs leave the GPU idle 40 % of the time, so on this box the b54 stride walk is now partly bound by the CPU's
  MSD filter: the GPU-side gain is larger than the wall-clock one, and part of the wall-clock one is clock under the
  130 W cap (F2.2).

### Q7: scope

F7. One change; stands alone on main; only a CHANGELOG conflict with #251 and #260.

### Q8: the PR body and the changelog

- **No program references:** no scratchpad paths, agents, directors, review names or model names. The closing line
  is the standard attribution line. #251 and #260 appear once, as open PRs, under "Not in this PR".
- **wgpu expectations and what was not measured:** present ("What a wgpu device should expect": not measured, M4
  ballot, 9070 XT scan if CubeCL reports 64), plus the llvmpipe bullet; add F2's and F3's clauses.
- **Numbers checked:** the reproduction table (1,064 / 5,072 / 2,958; 1,217 / 10,152 / 3,382; lavapipe 1,217 / 0 /
  3,382) matches my own runs of main exactly; the exactness table matches the logs (with F1's correction for the
  CUDA scan form); the cost table matches (F2's qualifiers).
- **Changelog:** accurate, one sentence, user-facing; `#NNN` to fill (F5).

## What could not be verified here

- **Any 64-lane device** (RX 9070 XT on RADV, either build): the scan form's correctness on real partly filled or
  odd subgroups, its cost, and that CubeCL reports 64 there (it should: wgpu-hal passes RADV's `maxSubgroupSize`).
- **Metal** (M4, WGSL through naga and CubeCL's MSL): the new tests' first run will be macOS CI. If CubeCL's MSL
  backend reports plane sync, CI will also be the first run of the plane-scoped queue on partly filled simdgroups.
- **Drivers that release a workgroup barrier early** after subgroup barriers (F3): seen only on llvmpipe, where
  production never runs the plane-scoped queue.
- **Default power limits:** all timing here, the author's and mine, is at this host's 130 W cap.
- Planes without lane 0 and non-linear layouts on a device: no device available produces them; they rest on the
  argument and the two models (mine and the author's), which agree.

## Box use

Builds and runs only in `/root/rv` (own `git archive` trees, own target dirs; the author's trees untouched).
NiceMark was not run. No contact with the production API, fleet, server, demoux or mayalaran. Everything I produced
on the box is in `T26B/review-box/` (logs, `out/builds.txt` with md5s, `out/timing.out`,
`out/test_only_tree_diffs.patch` = every change I made to a tree, all in tests; scripts).
