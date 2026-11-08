# L47 review: `pr/check-d` (0f3332d), the overlap join's check in base-b² limbs (2026-11-08)

Independent review of fork `pr/check-d` = one commit on `pr/top-fd-round2` d813aea (`git diff d813aea
fork/pr/check-d`: `common/src/cubecl_join.rs` +832/−107, new `common/src/join_check.rs` 777 lines, `lib.rs`,
`CHANGELOG.md`, `gpu-parity.yml`). Read against SCOPING §3–4, PROTO-BRIEF, RESULTS, raw/, PR-BODY. Line numbers
are the PR head's.

## Verdict: merge with small fixes

I found no correctness defect in the kernel. The arithmetic is exact for every shape the join can produce: I
re-implemented the kernel from its text (not from the host mirror) and ran it against Python big-int digits on
every production band at bases 40–64 (f0 = 3, k2 = 8), including band edges the PR's tests do not reach, and on
the 18 test-window shapes (narrow and wide H). Every limb, the gate, the mask and the distinct count matched,
and every u32 intermediate was overflow-checked. The work counter hands out every list entry once, and nothing
downstream depends on the old grid. The CI change is necessary and keeps the lint covering the kernel.

The small fixes are in the new device test, which is the only thing that checks this kernel against the CPU,
and in the PR body's wording:

- **M1:** the count test can pass without checking anything for a batch the device dropped.
- **M2:** its synthetic n miss the production bands' top edges at four of the six production shapes. At b64 no
  adversarial n is kept at all.
- **M3:** it runs the b57 frontier field twice. It has 25 lists and 22 distinct shapes, not the 26 shapes the
  body and RESULTS claim.
- **D1:** the body states the instruction counts in two different units.
- **D2:** the body cites the A/B's identical counts as exactness evidence, but the check does not produce them.

None of these hides a known bug. I would fix M1–M3 and D1–D2 before opening the PR; the rest can be follow-ups.

## Findings

### Medium

**M1. The count test passes without checking anything on a batch the device did not run**
(`cubecl_join.rs:5587`, `read_list` at :5384).
- **What happens:** `check_counts` calls `launch_batch` and then reads the list. It never calls `ensure_ran`,
  and it never compares `checked` with anything. If the device drops the join, the list is empty, and count
  and probe mode compare nothing for that field.
- **Why it matters:** the only guard is the global floor at :5658 (`entries > 10_000`, against 1,413,630
  expected). The macOS runner's paravirtual GPU is documented to drop dispatches silently in large layouts
  (`launch_batch`'s own comment). That runner is the first place CI will run this kernel on Metal (both naga-MSL
  and CubeCL's MSL compiler), so this is the test's weakest point on the backend that matters most. `check_all`
  does not have this problem: it compares survivors with the CPU.
- **Fix:**
  - After `launch_batch`, call `dev.ensure_ran(&dev.read_u32(&rec.ran).expect("ran"), &rec.expect).expect(..)`.
    The test module is a child module, so it can reach the method.
  - Assert `ns.len() as u32 == dev.read_counts(&rec).unwrap().1` (no overflow). Or reuse `read_checked`, which
    already `ensure!`s the cap, unsorted.
  - Require a non-empty real list for every `PLAN_FIELDS` field.

**M2. The synthetic lists miss the production bands' edges; at b64 they have no adversarial n at all**
(`synthetic` :5486, `join_check::tests::adversarial` :663).
- **What happens:** `adversarial(b, l)` is built around `b^l − 1` and `b^(l−1)` and then filtered to the
  field's (s2, s3) band. I computed what survives at the six production shapes:
  - **b42, b57, b62:** only the low-end set survives: `low`, `low+1`, `low+b^i−1`, `alt1`, the f0/k2
    boundaries.
  - **b50, b60** (s2 = 2l): only the top-end set survives, including `b^l − 1`, which is the band's last n
    there.
  - **b64** (l = 13, s2 = 26, s3 = 38): 0 of 34. Its band starts at ∛(64³⁷) ≈ 3.78e22, above 64¹², and ends
    below 64¹³ − 1.
- **What is never tested on the device:** at b42, b57, b62 and b64 the device lists get neither the band's last
  n (`hi − 1`) nor any n whose square or cube sits just below a power of b. That is where the high digits of n²
  or n³ run to b − 1 and the carry normalisation's longest chains reach the top limbs. b50 and b60 get both,
  through `b^l − 1`. The task named "carries propagating through every limb" and "b64 edge" as the cases to
  cover. At b64, which is also the one base where every quotient is a shift, the synthetic list is 4,000 random
  n.
- **Why it is Medium and not High:** my independent simulation covers exactly these n (below) and they are
  exact. Real lists and random n exercise the same code. So this is a gap in the test, not a suspected bug.
- **Fix:** in `synthetic`, push `lo`, `lo + 1`, `hi − 1`, `hi − 2`, `⌈√(b^s2)⌉ − 1` and `⌈∛(b^s3)⌉ − 1` (when
  they lie in [lo, hi)), plus `hi − 1` with its low i digits set to b − 1 for each i. `root_above` already
  computes the roots. That is about 20 n per shape.

**M3. The b57 frontier field runs twice, and the "26 field shapes" claim is wrong** (`cubecl_join.rs:5559`).
- **What happens:** `PLAN_FIELDS` already holds `(57, FRONTIER_57, 1e14)`, and `check_counts` pushes it again.
  The box log (`raw/box/fin_counts.log`) shows the same line twice.
- **Effect:** the test runs 25 lists over 22 distinct `CheckShape`s, not 26 shapes. About 4 % of its time is a
  repeat, on runners where it takes 1–2 minutes (lavapipe) and on the macOS job, which has a 30-minute limit.
  The b20 and b57 windows also share shapes, and therefore identical synthetic lists (same seed), which is
  harmless.
- **Fix:** drop the push, and correct the count in PR-BODY and RESULTS §5.

### Low

**L1. The gated path that production runs is checked against a hit only at b10.**
- **What happens:** with `mode == CHECK_COUNT`, `if pass || comptime!(mode == CHECK_COUNT)` (:3396) folds to
  `if true`. So count mode never runs the divergent `if pass` block that hits mode runs, and the device test
  exercises the same arithmetic but not that control flow. Only `check_all`'s b10 [47, 100) → [69] runs it
  with a hit, at a shape where the rest of n³ is one limb.
- **Fix (cheap):** add a fourth comptime mode that runs the rest only under `pass` and writes `uniq`. Compare it
  with the CPU on the entries that pass (3,599 in the current lists).

**L2. The work counter assumes full planes** (:3308, :3315, `i = cur + lane`).
- **What happens:** each take is `PLANE_DIM` entries, and lane j handles entry `cur + j`. A plane with inactive
  lanes would silently skip their entries. With 256-thread cubes and power-of-two subgroup sizes, every
  implementation I know runs full subgroups, and CUDA, lavapipe (8 lanes) and Apple are tested or about to be.
  The existing `top_slot` (:1765) does the same job with `plane_sum`/`plane_exclusive_sum` over the active
  lanes.
- **Fix:** either take `plane_sum(1)` per take and offset by `plane_exclusive_sum(1)` (two plane ops per 32
  survivors), or state the full-plane assumption in the kernel's doc comment.

**L3. The loop is covered only by accident, and the counter assertion is near-vacuous** (:5432–5436).
- **The assertion:** `ran[STAGES] >= cap` is always true for the test's lists. Every plane takes at least once:
  16,384 planes × 32 lanes ≥ 524,288 on CUDA, which is more than any list here (about 130k at most).
- **The loop:** whether a plane goes round more than once depends on list size against resident planes. On a
  3080, takes 1–2 of every resident plane cover about 209k entries, so the 1e14 lists exercise a second
  iteration only in part. Lavapipe exercises it heavily.
- **Fix:** give `launch_check` a test-only cube count and run count mode once with a tiny grid (1 and 3 cubes),
  so every plane loops many times on every backend. Drop or replace the `>= cap` assertion.

**L4. One shared atomic counter may be a limit on HBM GPUs (unmeasured).**
- **The numbers:** the kernel issues one same-address atomic per 32 survivors, 1.96e9 per b62 1e17 field.
  - **3080:** 0.6e9/s at 3.19 s, about 0.4 per clock. Not limiting (K = 1 beat K = 4).
  - **A100:** its gather floor (2.5 TB at 1.55 TB/s, about 1.6 s) would need about 1.2e9/s.
  - **H100:** about 2.6e9/s.
- **Why it might matter:** published microbenchmarks put same-address L2 atomics near one per clock. So the
  counter may co-limit the check on an A100 and cap it on an H100, still far below the old kernel's time.
- **Fix:** none needed for this PR. Note it in "Not in this PR", or measure on an A100. K = 2 halves the
  atomics if needed.

**L5. The kernel and `CheckShape` compute the same values twice** (`check_kernel` :3289–3301 against
`join_check.rs:146–188`).
- **What happens:** the kernel recomputes `gl`, `hwide`, `hz`/`hinv` and the parts' digit ranges from its
  comptime arguments, while `CheckShape::{gl, h_wide, h_div, part}` compute the same for the mirror and the
  tests. The device test would catch any drift, but that is two sources of truth.
- **Fix:** build `let sh = comptime!(CheckShape { b: base, l, s2, s3, f0, k2, g })` inside the kernel and use its
  methods. The struct's fields are `pub`.

**L6. Code used only by tests sits in the library's public API** (`join_check.rs:52, 61, 166–188, 193, 235, 385`).
- **What happens:** `magic_bound`, `qdiv`, `wide_div`, `Mirror`, `mirror` and `CheckShape::{part, h_wide, h_div}`
  are `pub` in a module that is not gated behind a feature, but only the tests (and one `println!`) use them.
  The runtime needs only `magic`, `inverse_mod_2_64`, `CheckShape::{new, gl}` and `GATE_DIGITS`.
- **Fix:** put the mirror behind `#[cfg(test)]` (or `pub(crate)`), keeping the docs.

**L7. `read_list` duplicates `read_checked`** (:5384 against :4200).
- **What happens:** `read_list` is `read_checked` without the sort, and it clamps an overflow with `.min`
  instead of the `ensure!`. That silent clamp is part of M1.
- **Fix:** factor out one unsorted reader.

### Docs, PR body, CHANGELOG, CI

**D1. The body states the instruction counts in two units for the same quantity.**
- **What it says:** "Why" says "a warp issued about 1,050 instructions per 32 survivors". "Code" says "Per
  survivor at b62, a warp issues 330 instructions on the common path".
- **The problem:** both are per warp-iteration (32 survivors, one per lane). Read literally, the second is a
  10× regression.
- **Fix:** write "per warp-iteration (32 survivors, one per lane)" in both places.

**D2. The A/B's identical counts are not evidence for the check** (Exactness, "Every timed field above has the
base's survivors and full checks"; RESULTS §5–6 "exact counts").
- **What happens:** survivors and `checked` are the join's and the prefilter's counts. They are written before
  the check kernel runs, so they validate the join and not the check. The hit lists are empty on both sides.
- **Fix:** say so in one clause, so a maintainer does not count the A/B toward the check's exactness. The
  Soundness section already says it of the hit comparisons.

**D3. The b57 1e14 gain coincides with a clock difference.** `ab.py` on the raw logs gives P a mean clock of
1905 MHz against B's 1635 for b57 1e14 (×1.078; per round 1.005, 1.090, 1.078). The body already marks the
1e14 rows as within their spread at b62 and b64. Extend that to b57, or drop the row's emphasis.

**D4. The lint change (`gpu-parity.yml:85`) is correct.**
- **Why the requirement had to go:** `--require` fails unless the kernel shows at least one constant division,
  and the new kernel has none (`CheckKernel b57: 0 constant divisions` in `wgsl_lint_P.log`).
- **The lint still covers the kernel:**
  - `wgsl_dump_for_lint` still compiles `CheckKernel`, and the lint still scans it.
  - In the WGSL, every quotient is `u32((u64(x)·u64(m)) >> 32) >> s` followed by a multiply and a subtract.
  - The direct MSL compiler's `__umulhi` helper is `static_cast<uint32_t>((uint64_t)a*b >> 32)`.
  - So the Apple pattern (a division whose dividend is a half shift or a high word) cannot occur. The same
    `u32::mul_hi` is already in the join's prefilter (#246, still open), and #246's PR CI passed the macOS Metal
    job (10m56s), so CubeCL's MSL lowering of it compiles and runs there.
- **What is lost:** nothing now asserts that the dump still contains `CheckKernel`. An optional `--present
  KERNEL@BASE` flag in `scripts/wgsl-lint.py` would restore that.
- **Both compilers still run the new test:**
  - lavapipe: step 1 runs `--ignored` with naga, step 3 runs the `cubecl_` filter with cubecl-spirv.
  - Metal: the wgpu step and the cubecl-metal step.
  - `magic_quotients_are_exact_everywhere` also matches step 1's `--ignored`. It returns at once without
    `NICE_TEST_CHECK_EXHAUSTIVE`, so CI never runs the exhaustive check (fine: the closed-form bound test
    covers it).

**D5. What CI exercises first.**
- **The first Metal run:** the macOS job will be the kernel's first run on Metal, twice. The paravirtual GPU does
  not reproduce the M4 compiler bug, so a green run there says nothing about real Apple silicon.
- **Recommended before merge:** the one Apple check available is `cubecl_check_counts_match_the_cpu` (wgpu and
  cubecl-metal) on mayalaran (M4). It needs the user's per-task permission. The kernel has no division, so the
  known bug class should not apply, but this is the cheapest real-Apple evidence there is.
- **Runtime budget:** the new test adds roughly 1–3 minutes per compiler to the lavapipe and macOS jobs. The
  macOS job took 10m56s on #246's PR and 15m34s on #249's, against a 30-minute limit. Watch the first run; M3
  trims a little.

**D6. The CHANGELOG line is fine.** It is one sentence and user-facing, in the style the user trimmed #178 and
#154 to; `#NNN` is to be filled in. Optionally drop "taken straight from its top's record".

**D7. Nits.**
- "the tests' smaller windows, where H reaches 2^41": real lists reach 2^40 at the b64 window, synthetic n up to
  2^42.
- The test name `gate_is_a_necessary_condition_of_the_full_check` oversells it. Its necessity assertion is
  vacuous except at 69 (no other nice n exist in its range). What it really checks is that the gate equals its
  definition on n with distinct squares, which is the useful part.

## Check by check (the brief's list)

**1. Exactness**
- **The limb split.** Word 6 is `tl_mod·pdiv + v` in both top kernels (:1965, :2934), with `P = p0·pdiv + v`
  (:1849, :2768) and `tl_mod = p0 mod b^(k2−f0−p)` (host `sorted_layer`, :3631). So w6 = P mod b^(k2−f0)
  exactly, below 2^32 by `FieldSetup::new`'s `mid` rule. #249's FD-against-top test compares word 6 between the
  two kernels.
  - **H.** (P − w6) = H·2^z·o, so `u32(x >> z)·o⁻¹ mod 2^32` = H whenever H < 2^32. The kernel needs H < 2^31
    for its quotients, and `hwide` (b^(l−k2) > 2^31) routes every other H to the 64-bit path. Production:
    l ≤ 13, k2 = 8, H < b⁵ ≤ 2^30. b64 is a pure shift (z = 30, o = 1).
  - **The parts.** `part_limbs` covers digits [0, f0), [f0, k2), [k2, l), with the odd-boundary pending digit
    and the clipped cases (k2 > l, l ≤ f0) handled the same as in the mirror. Every limb of `nn` is written.
- **Schoolbook bounds.** A column has at most nl products of limbs ≤ b² − 1. The carry is below nl·b² by
  induction: c' < nl(b²−2+1/b²) + c/b² < nl·b². So a column is below nl·(b⁴+b²).
  - Production maximum: 7·(64⁴+64²) = 1.17e8 < 2^27. Observed maximum in my simulation: 1.006e8.
  - Over every n < 2^96 at every base ≤ 64: below 2^28.
  - Columns at index ql and above (cl and above for n³) hold no product, since n² < b^(2ql) and every partial
    product is non-negative, so the uncomputed top is zero and the last column is the top limb (< b²).
- **Magic quotients.** m = ⌈2^(32+s)/d⌉ with s = ⌊log₂ d⌋ and e = md − 2^(32+s) ∈ (0, d) is the
  Granlund–Montgomery round-up for 31-bit dividends: x·e < 2^31·2^(s+1) gives exactness for every x < 2^31.
  - **Every dividend the kernel forms:**
    - r0 < b^f0 and w6 < b^(k2−f0), both checked below 2^31 by `CheckShape::new`.
    - Narrow H < 2^31; the quotients of all three are smaller still.
    - Wide-H chunks < d·2^16 ≤ 2^28.
    - Columns < 2^28.
    - Limb splits < b² ≤ 4096. The top limbs of n² and n³ are < b² (or < b when the digit count is odd).
  - All are below 2^31. The 114 divisors are b and b² for the 57 non-power-of-two bases from 3 to 64; the powers
    of two use shifts.
  - **The host tests:** the closed-form `magic_bound ≥ 2^31` for every divisor; a block-worst enumeration over
    the actual input ranges (sound, since the quotient is monotone and never low); and the opt-in exhaustive
    test, which I ran (below).
- **The gate.** `pass ⇔ popcount(mask over n² and n³'s low 2·gl digits) = s2 + 2gl ⇔ those digits are
  distinct`. That is implied by niceness, because they are a subset of the s2 + s3 = b digits.
  - Every lane with `pass` runs the rest of n³ (:3396). The rest is not skipped per plane: the `if` is per lane.
  - gl = min(5, cl − 1) never includes n³'s top limb.
- **Decision.** The old kernel: no duplicate and popcount = b. That needs s2 + s3 = b, which holds on every
  test window (all 18 are in band, which I checked) and every production field. The new kernel:
  `s2 + s3 == base` (comptime) and pass and uniq = b. The two are equivalent. The `pass &&` is redundant but
  harmless (a partial mask has at most s2 + 2gl < b bits).
  - There is no near-miss output on the nice-only path, before or after.
  - The output format (n as 4 words, `NICEONLY_STRIDE`) is unchanged; `put_n` rebuilds n from the limbs, so
    probe and hits also check the limbs.

**2. The work counter.**
- **Behaviour:**
  - Takes are disjoint ranges [a, a + PLANE_DIM). The broadcast `cur` and the plane-uniform `count` keep the loop
    and the broadcast in uniform control flow.
  - A plane stops only when its current take is at or past `count`, so every range below `count` is processed
    by its owner, and `i < count` trims the last one.
  - On an empty list each plane takes once and exits.
  - Overflow is impossible: the counter ends near count + 2·planes·PLANE_DIM, about count + 2^21, with
    count ≤ list_cap ≪ 2^32.
- **Types and buffers:**
  - `Atomic<u32>` with `fetch_add(subgroup_size)` (WGSL `atomicAdd(…, subgroup_size)`), `PLANE_DIM` = 8 on
    lavapipe, 32 on CUDA and Apple.
  - The counter lives in a fresh per-batch `ran` word 4: `launch_batch` :3982, test :5417.
  - `ensure_ran` slices the first 4 words (:4138), and `launch_top` still binds 4 of the 5 (harmless).
  - `expect[3]` follows `CHECK_CUBES` (2048); the only other user of `CHECK_CUBES` is the test-only
    `fill_sentinel` (any grid works).
  - The cube barrier in `cube_done` is reached by every unit after the loop.
- **Order and grid:**
  - Stage order is unchanged: the check reads `checked` after the join on the same stream.
  - A dropped check cube still shows as `NotRun`. Other planes take its work, so the re-run is merely
    conservative.
  - Plane ops were already required for the join (`StrideReason::NoPlaneOps`), so `plane_broadcast` adds no
    new device requirement.
- **Untested here:** HIP wave64 and DX12.

**3. The tests.**
- **Independence:** count and probe compare against an independent CPU. n comes from record words 0–1 and r0
  only (not w6, not the kernel's limbs). The digits come from malachite, the count from the client's
  `get_num_unique_digits`, and the gate from its own definition. The host mirror is not used in the device test.
- **Real lists:** they come from production-shaped fields (`PLAN_FIELDS` at 1e14, f0 = 3, k2 = 8: b42, b50,
  b57 frontier, b60, b62, b64) and every window (f0 0–3, k2 3–7, wide H at b57, b58, b60, b64). Totals:
  1,413,630 real entries and 96,042 synthetic n; 3,599 entries pass the gate. Lavapipe, naga and SPIR-V
  reproduce the CUDA totals (`lvp_*_P.log`).
- **Would they catch these?**
  - **A wrong magic constant:** yes, through the host tests for every divisor and the device masks for the
    tested bases.
  - **A dropped carry:** yes (masks).
  - **A gate that rejects a nice number:** yes, if the predicate differs from its definition on any of 1.5M
    entries (3,599 pass). The gated control flow itself is covered only at b10 (L1).
  - **A counter that skips an entry:** yes, because count mode leaves zeros, which never equal the reference
    count. **One that duplicates an entry:** yes in probe mode (a multiset compare, or an out-of-range panic).
- **Gaps:** M1, M2, M3, L1, L3.
- **Near-nice numbers:** the real lists' 3,599 gate-passers are the near-misses. Optionally, a few published
  high-uniqueness numbers per base (uniq = b − 1 or b − 2) would test the decision boundary deliberately.

**4. CI:** see D4 and D5.

**5. Claims against the raw data:**

| claim | source | check |
|---|---|---|
| A/B b62 1e17 ×1.088, b62 1e16 ×1.085, b60 1e16 ×1.124, b64 1e16 ×1.070, 1e14 ×1.078/×1.046/×1.015/×1.003 | `ab.py box ab B P` on `raw/box/ab_*` | reproduced exactly (medians, rounds, spreads, MHz) |
| NiceMark ×1.056 (7889.7 → 8327.8), scenarios ×1.039–1.077 | same | reproduced |
| 39 regs (b57/60/62), 40 (b64), 0 spills, no local, 24 images | `ab_P_jit.txt` | yes, all 24 |
| b62 common path 330 (FMA 140, ALU 170, LD/ATOM 6, br 14), rest 249, write-back 62 | `scr_jit.txt` k1 | 138+1+1 / 161+4+5 / 5+0+1 / 4+2+8 = 330 ✓ (from the K = 1 exp build; RESULTS gives the same for the PR tree) |
| floor 3.36 s = 0.745 TB/s, 98 % of 760 GB/s | 62.58e9 × 40 B / 3.359 s | ✓ |
| new kernel 3.19 s / 0.74 s, ×2.8 / ×2.9 | RESULTS §3 (K = 1 knob on the exp build, one round) | ✓ arithmetic; it is the exp build's K = 1 form, not the PR binary profiled; the body's "this kernel's form" is fair |
| old check 8.79 s of 77.5 s (11 %), 2.13 of 15.6 (14 %) | RESULTS §0, §2 | ✓ |
| 26 field shapes | `fin_counts.log` | ✗ 25 lists, 22 distinct shapes (M3) |
| exhaustive: 114 divisors, every x < 2^31 | test source + my run | ✓ (below) |
| "exact counts" on every timed field | — | true, but they are the join's counts, not the check's (D2) |

## What I ran (ivory, `nice -n 19`, worktree `.worktrees/review-check-d` at 0f3332d, own target dir, removed after)

- `cargo test --release -p nice_common --lib join_check`: 5 passed, 1 ignored, 2.6 s (build 2m17s, target
  273 MB).
- `NICE_TEST_CHECK_EXHAUSTIVE=1 … join_check::tests::magic_quotients_are_exact_everywhere -- --ignored`
  (taskset 3 cores): **ok, "114 divisors exact on every x below 2^31"**, 691 s (31 CPU-minutes; log in
  `raw/review/exhaustive_ivory.log`). It covers all 114 divisors (b and b² at bases 3–64, not powers of two),
  every x in [0, 2^31), comparing `mul_hi(x, m) >> s` with `x / d`. It does not cover the inverses or `wide_div`,
  which `inverses_and_wide_division_are_exact` tests at random.
- `cargo fmt --all --check`: clean (rustc 1.99.1). Clippy was not re-run here; the box's three-feature clippy
  logs (`clippy_*_FIN.log`) are rc 0.
- **Independent simulation** (`raw/review/kernel_sim.py`, `windows_sim.py`, `adv.py` for M2's table; Python, written from
  `check_kernel`'s text). It reproduces the kernel's control flow: `part_limbs`, `wide_div`, the schoolbook
  columns, the magic quotients with exactness asserts, the u32 overflow asserts, the gate and the masks.
  - **What was compared:** every limb of n (rebuilt), the distinct count, the gate and the mask, against big-int
    digits.
  - **Production:** 60,080 n over all 20 production bands at bases 40–64 (f0 = 3, k2 = 8). Each band got 3,000
    random n plus lo, lo + 1, hi − 1, hi − 2, ⌈√(b^s2)⌉ − 1, ⌈∛(b^s3)⌉ − 1, and hi − 1 with low digits b − 1.
  - **Windows:** the 18 test windows' shapes (b10's plus the 17), 3,000 n each plus their ends, including the
    four wide-H shapes.
  - **Results:** all exact. Largest dividends observed: columns 1.006e8 (< 2^27), part quotients < 2^30, wide
    chunks 2.28e8 (< 2^28), limb splits 4,095.
- Read: `raw/box/fin_counts.log`, `lvp_{naga,spv}_P.log`, `ab_P_jit.txt`, `scr_jit.txt`, `wgsl_lint_P.log`, the
  check kernel's WGSL in `wgsl_P.log.gz`, and CubeCL 0.10's MSL `__umulhi`.
- No GPU (no Vulkan ICD on ivory either), so no device test was run here.
