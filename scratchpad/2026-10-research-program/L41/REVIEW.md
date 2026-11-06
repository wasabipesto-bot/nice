# L41 review: `pr/join-lean-prefilter` d672887 (lean `walk_pf`: FX + MT + GM + RC), 2026-11-06

Reviewer: independent, read-only on the branch. Diff reviewed: `git diff 7832f89 fork/pr/join-lean-prefilter`
(`common/src/cubecl_join.rs` +476/−32, `CHANGELOG.md` +1). Inputs read: SCOPING §1–§7, RESULTS, PR-BODY,
`raw/registers.txt`, `raw/ab_table.md`, `raw/nm_table.md`, the CUDA/SASS in `raw/box/sass/{B,P,P4,P6}`, `CpuJoin::prefilter`,
and the 7832f89 `walk_pf`. Line numbers below are the head's `common/src/cubecl_join.rs` unless marked `PR-BODY`.

## Verdict: **merge with small fixes**

I found no correctness defect. FX, MT, GM and RC each compute exactly the predicate and count of the code they replace.
I checked this on the kernel source, the emitted CUDA and SASS, and the four backends' `mul_hi` lowerings. The tests
pin it on the host (mirrors) and on devices (CPU-reference parity, which CI runs on lavapipe and macOS). The measurements
in the body match the raw tables.

The fixes are a few lines of PR-body text and one stale code comment:
- Say more about the spill variability (M1).
- Make the bit-reversed mask convention a separate, visible note (M2).
- Correct the stacking line and one false "fits a word" sentence (L1, L2).

None of them changes code that runs.

## What I ran (ivory, own worktree `.worktrees/review-l41` at d672887, `nice -n 19`, `-j2`, toolchain 1.99.1, target in the worktree)

| check | result |
|---|---|
| `cargo test --locked --release -p nice_common --features gpu --lib --no-run` (CI's `test-gpu-host` feature set) | builds, **no rustc warnings** |
| the three new CI host tests + `ndig_fast_constants…` (`cubecl_join::` filter) | **4 passed**, 15 ignored (GPU), 7.4 s on 2 niced threads |
| the whole `nice_common` lib suite, same binary | **225 passed, 0 failed, 50 ignored**, 19.8 s |
| `cargo fmt --all --check` | **ok** |
| `cargo clippy --locked -p "*" --all-targets -- -D warnings` | **ok** |
| the same with `--features nice_client/gpu` | **ok** |
| the same with `--features nice_client/gpu,nice_client/cubecl-spirv` (CI's second lint) | **ok** (target peaked at 2.8 GB) |
| independent Python check of FX's constants and error bound, b = 2–64 (every D < b²) | `dh` = the exact ceiling and < 2^32 everywhere; max Δ over A, P, D < b² = **26,655,048 (2^24.67) at b62**; with A, P anywhere below 2^16 still < 2^28.8 |

Not run:
- **The wgpu/lavapipe tests.** ivory has no Vulkan ICD.
- **The CUDA tests.** ivory has no GPU and no `nvcc`.
- **`fx_digits_are_exact_everywhere` (opt-in).** Another agent's CPU A/B (`l42_ab`) was running on ivory, and 4 cores for
  ~10 min would have disturbed it. It is also redundant here: the per-base Δ computation above plus the derivation is a
  complete proof, and the author ran the test 4× (3 builds) with every triple exact.

## Findings

### Medium

**M1. The PR body understates the spill variability, and its cause is a hypothesis presented as fact**
(`PR-BODY` line 123 and lines 129–130).

The author's own data (`raw/registers.txt`) is more specific than the body:
- **Only level-4 (RC) builds ever spill.**
  - Levels 1–3: 9 offline passes, 18 compiles at b60/b62. Every one took 45–46 registers with no spills.
  - Level 4 (`XL4`, `X2L4m1`, `X3L4a–f`, `P1`, `P`, `P3`, `P4`, `P6`): **14 of 26** b60/b62 compiles took 40 registers
    with 28–44 B of spills. `X3L4b` also spilled at b64.
  - The head's own passes spilled in 2 of 4 (`P4` b60, `P6` b62).
  - So "some compiles" is about half of them. The trigger is the per-chunk range test's code, not FX's 4 extra
    registers alone.
- **The layout dependence is real.** I diffed `P4` and `P6`'s `join_kernel_b60_1.cu`: after normalising identifier
  numbers, the bodies are identical and only the `dynamic_shared_mem[...]` offsets differ. Yet `P4` gave 40 + 44 B of
  spills and `P6` gave 45 with none. The body's "depends on the order in which CubeCL lays out the shared arrays"
  therefore holds.
- **The base's codegen also varies by process**: `XL0` and `B` give 1080 and 1088 SASS for the same b62 join. The
  layout nondeterminism is pre-existing; **the spill is new with this PR**. The base sits exactly at the 40-register
  (6-cube) tier and needs no spill to get there.
- **"ptxas aims at 6 blocks because the dynamic array hides the 5-cube limit" is plausible but untested.**
  - Plausible: 40 is exactly the sm_86 tier for 6 × 256 threads, and the spilled values are cold.
  - Untested: no compile with a static `__shared__` array of the same size was done. That is the decisive check, and
    `raw/scripts/cuexp.sh` can run it in minutes on the next box.
- **The timed processes' variant was not recorded.** "The timed rounds agree to 0.1–0.6 %" bounds the cost
  statistically; it does not show that a spilling process was timed. With ~50 % per compile and 12 A/B processes,
  some almost certainly were. Also, the offline `nvcc` 12.8 pass is not the runtime's compile: the timed processes went
  through CubeCL's NVRTC and the driver (580.159.03). "No spills in the timed binary's pass" therefore says nothing
  certain about what the timed processes ran.

Fix: replace the body's bullet (line 129) with something like:

> In about half of the compiles (14 of 26 offline at b60/b62, always with the per-chunk range test; never at the
> intermediate levels without it, 0 of 18), ptxas takes 40 registers with 28–44 B of spills instead of 45. Which one a
> process gets depends on CubeCL's per-process order of the shared arrays: two compiles whose CUDA differs only in those
> offsets land on either side. The likely reason is that the shared memory is one dynamic array, so ptxas does not see
> the 5-cube limit and aims at 6 (≤ 40 registers). The spilled values are per work item and per batch (the work index,
> the list base, four values around the digit-major copy), never in the walk; occupancy is 5 cubes either way. Which
> variant each timed process compiled was not recorded; the PR's three processes per field agree to 0.1–0.6 %. The base
> sits at 40 without spills (its SASS also varies by process, 1080 / 1088 at b62).

Also make the registers table cell say "(about half of compiles: 40 + 28–44 B spills)". Optional before merge: the
static-array offline compile, to turn "likely" into a fact.

**M2. The bit-reversed mask convention needs a visible note in the body, and one code comment is now wrong.**
- **Code**, lines 528–529: "bit i of `t_tr[c·64 + d]` is set iff top 32c + i has digit d". When `lean` is on, `d` is the
  mask bit, i.e. digit 63 − d. Suggested text: "… iff top 32c + i has the digit at mask bit d (digit d, or digit 63 − d
  where the masks are held reversed, see below)".
- **Body.** The convention is buried inside the MT bullet (line 10). It is a representation change: whoever next edits
  `join_kernel` has two conventions inside one kernel, chosen by a comptime shape test. Add a short paragraph, e.g. under
  Soundness:

  > **Representation change (join kernel only).** At mid = 2, k ≥ 2 (every production shape) `join_kernel` holds every
  > digit mask bit-reversed (digit d at bit 63 − d): the entries' `mlo`/`mhi`, the tops' `t_lo`/`t_hi` and gated
  > `t_glo`/`t_ghi`, and so the digit-major `t_tr`. The global buffers (`ext_m`, `top_rec`), every other kernel and the
  > CPU join keep digit d at bit d; nothing else reads these masks. Other shapes (b10's k = 1) keep the natural order.

- **Optional, not needed for merge:** make the reversal unconditional so that there is one convention. `walk_pf` would
  test `1u64 << (63 − g)`; it runs only in test shapes.

I checked every producer and consumer, and the reversal is applied consistently:
- Producers: wave load (lines 737–739, `mlo = rev(hi32 m)`, `mhi = rev(lo32 m)`); batch load (581–585, the same
  swap+reverse); gated copies (603–604, taken from the already-reversed `lo`/`hi`).
- Consumers:
  - the transposed copy reads reversed `t_lo`/`t_hi`, and the AND indexes `t_tr` by the entry's reversed bit position:
    the same labelling on both sides;
  - the small-batch test `(mlo & tlo) | (mhi & thi)`, both sides reversed;
  - `walk_pf_lean`'s `seen`;
  - the empty-slot default `0xFFFFFFFF`, which is reversal-invariant.
- The stage and flush carry only `t_id` and `r0`. `check_kernel` rebuilds n from `top_rec` (natural order). The host
  compares only counts. All reversals are gated by the same `comptime!(lean)`, and `walk_pf` (non-lean) still gets
  natural-order masks.

### Low

**L1.** `PR-BODY` line 1: "the diff below is this PR's commit only" is not what GitHub will show. A PR against `main`
from a branch containing #241's commit shows both commits until #241 merges. Use #239/#240's wording: "Stacked on #241
(its commit is the base of this branch; the new work is the last commit)."

**L2.** `PR-BODY` line 41: "and `D·Q + D·R` too" [fits a word] is false at b = 44, 46, 47 and 49–63, where
(b² − 1)(Q + R) ≥ 2^32 (I computed it for every base). The kernel never forms that sum. It forms
`D·Q + ⌈D·R/b²⌉ = ⌈D·2^32/b²⌉ ≤ ⌈(b² − 1)·2^32/b²⌉ < 2^32`, with `D·R + b² − 1 < 2^25`. Say that instead.

**L3.** The soundness section should name the kernel's operand ranges, since the proof assumes them. Checked in code:
- **A**, key level: `(t2 % b³) / b < b²` (lines 700–706).
- **A**, otherwise: the bucket kernel's digits `k..k2` of R², R³ as numbers, < b^mid (lines 333–340, unpacked at 728–729).
- **P**: `2ρ`, `3ρ²` reduced mod b² (lines 716–718, and 342–347 in the bucket kernel).
- **D**: `⌊(P mod b^(k2 − f0)) / b^(k − f0)⌋ < b^mid` (line 597).

So the host tests' range A, P, D < b² is exactly the kernel's, not just the model's. Also worth one clause: the only
condition is Δ < 2^32, which still holds (< 2^28.8) for any A, P < 2^16, so the 16-bit packing could never break
exactness either.

**L4.** Host arithmetic against the kernel's:
- **Identical:**
  - `fx_digits` is `ah.wrapping_add(p.wrapping_mul(dh))`, then the low word of F·b, then the high words; the kernel does
    the same in u32 (the CUDA: `__umulhi(l_750, 62)`, `l_750 * 62`, `__umulhi(…)`).
  - `fx_top`'s `div_ceil` equals the kernel's `(dm·R + b² − 1)/b²` without overflow.
  - The comptime constants come from the same `fx_consts`, which the test checks against u128 arithmetic.
- **Not mirrored:** the backends' `mul_hi`. I read CubeCL 0.10's lowerings, and all are exact for u32:
  - CUDA `__umulhi`;
  - SPIR-V `OpUMulExtended`;
  - WGSL: a u64 product when `supports_u64`, else a 16-bit split;
  - MSL: a `uint64_t` product.

  Device parity covers the backends: lavapipe naga and SPIR-V on `P4`, CUDA on `P`/`P4`, and CI's macOS job when the PR
  opens.

**L5.** The sign test on `hi32(seen << g)` is exact for g in 0..63:
- g, h < b ≤ 64 by construction: hi32(F·b) < b because F < 2^32.
- CubeCL emits plain `uint64 << uint64` then `>> 32` (`P/join_kernel_b62_1.cu`, around line 1100), defined for shifts
  below 64.
- ptxas lowers each to one `SHF.L.U64.HI` (SASS 0x31c0–0x3220).
- The base's `1u64 << g` already relied on `SHF.L.U64.HI` for g ≥ 32, and the b57–b64 parity and 1e14 checked counts
  (digits ≥ 32 throughout) match exactly.
- WGSL/SPIR-V/MSL shifts below the width are defined.

Nothing to fix.

**L6.** No run on Apple or AMD hardware. CI's macOS job (paravirtual Metal) will be the first Metal execution of the lean
path, and the real M4 compiler is not covered there. The known bug class is a constant division of a half-width shift
or a high word. The new code has `mul_hi`, whose MSL is `u32(u64 product >> 32)`, but nothing divides its results. The
one new constant division divides a sum (`(D·R + b² − 1)/b²`). The WGSL lint flagged 0 (26 constant divisions in
JoinKernel b57, down from 36). Fine as is. Optionally add one line under Exactness: "not run on Metal or AMD hardware;
CI's macOS job covers paravirtual Metal."

**L7.** Comment at lines 2887–2888: "The sign test last: first, it compiled to a select…" reads oddly. Suggest: "Keep the
sign test last in the chain: placed first, NVVM compiled it to a select and a byte extension in front of the compares."

**L8.** The doc of `lean_prefilter_matches_the_division_form` (lines 6150–6152) says "against the division form
([`walk_pf`] at mid = 2, as `cpu_join`'s prefilter)". It compares against a host re-implementation (`pf_masks` on
`(A + P·D) mod b²`'s digits), which is fine, but "against a host model of the division form" is the accurate claim. The
device tests are what compare with `walk_pf`'s replacement and `CpuJoin` directly.

**L9.** `PR-BODY` "Why" (line 18): "about 70 % of the join's warp instructions by SASS count" comes from SCOPING's
budget, which uses estimated wave and batch counts. "Integer-ALU-bound" is likewise the model's diagnosis; the measured
×1.10 in cycles agrees with it. Prefix "an estimated". Nit.

**L10.** `PR-BODY` line 95: the timed build differs from the head by more than the list says. It also has the new tests'
clippy fixes (`div_ceil`, two allows, `seed` → `flag`), and the `let mut pass`/`if` → `let pass = if` change, which
changes the emitted CUDA. P4 is the same SASS as P instruction for instruction, and P4 → head is tests only (I checked
`git diff f516356 d672887`: hunks only in `mod tests`). Add "and lint fixes in the new tests".

**L11.** CHANGELOG: the line is fine (one sentence, user-facing, under Unreleased after #241's). The `#NNN` placeholder
must be replaced once the PR number exists. Nit: it does not mention the range-test part, which "testing them with fewer
instructions" covers loosely. That is acceptable under the brevity rule.

**L12.** The new CI tests run ~6.6·10^8 inner iterations. That is 4.4–7 s in release, which is how CI runs them, but a
local debug `cargo test --features cubecl` will spend a minute or more there. Nit; no change needed.

## Specific questions

**1. FX.** The bound re-derives:
- C·b² = 2^32 + ε1 and dh·b² = D·2^32 + ε2, with 0 ≤ ε < b².
- (A·C + P·dh)·b² = q·b²·2^32 + r·2^32 + Δ, so F = (A·C + P·dh) mod 2^32 = (r·2^32 + Δ)/b², below 2^32 for any Δ < 2^32.
- Two multiplies give ⌊F·b²/2^32⌋ = h·b + g with h, g < b, and that is r iff Δ < 2^32.
- The condition is necessary and sufficient; A, P, D < b² gives Δ < 2b⁴ ≤ 2^25.

Per base, the exact maximum is 2.67·10^7 (b62, 2^24.67; b64 0), a margin of ≥ 161×. Computed independently for every
base 2–64 and every D. Ranges and host/kernel arithmetic: L3 and L4. The kernel sees exactly A, P, D < b², which is
what the exhaustive test covers. The 16-bit packing (non-key `q0`/`q1` halves) holds values < b^mid ≤ 4096, with no
stray high bits: the bucket kernel writes `a2 | a3 << 16` and `p2 | p3 << 16` only. The bound holds even for 16-bit
operands.

**2. MT.** Consumers and consistency: M2. The sign test: L5. No host code, test or CPU-join comparison reads these masks;
the host compares survivors, checked and hits only.

**3. GM and RC.** Both are the same predicate and count.
- **GM:** `select(seed != 0, lo, 0)` of the reversed certificate equals the old `if (dmv >> 16) != 0 { seen |= top }`.
  `top_rec[7]` is 0/1 from both top kernels (`seed`, `seedf`), so the old `seed << 16` packing lost nothing.
- **RC:**
  - Both top kernels write `[a − pw0, e − pw0 + 1)` or `[0, w)`, and `top_fd_kernel`'s `w` is the same `self.w_f0`
    argument.
  - Every r0 = `bp_r` < b^f0 = w.
  - So a top with rlo = 0 ∧ rhi = w rejects nothing, and every other top is marked (line 592).
  - The clearing loop removes exactly the bits the per-pair test rejected (the negation, at line 838).
  - `nand += popc(pm & vv)` counts exactly the walked in-range bits the old per-bit `nand += 1` counted.
- **`s_cw` lifecycle:**
  - zeroed before the kernel's first barrier;
  - set before the batch barrier;
  - read after it;
  - cleared after the last chunk's two barriers and before `tc += TOP_CAP; sync_cube()`;
  - the batch loop has no early exits.
- **What pins each part:**
  - **FX:** host `fx_digits_match_the_division` (constants, worst A/P) and opt-in `fx_digits_are_exact_everywhere`;
    on devices, every checked count compared with `CpuJoin`.
  - **MT:** host `lean_membership_matches_the_masks` (mirror); device parity.
  - **GM:** host `lean_prefilter_matches_the_division_form` (mirror with a random seed flag); device checked counts
    (seeded and unseeded tops occur in every window).
  - **RC:** device parity only. `cubecl_join_matches_the_cpu_reference` and the CUDA twin have windows clipped at both
    ends; the author's mutant without RC fails at `b20 [58945, 160000) (2,3,1)`. CI runs the wgpu twin on lavapipe and
    macOS. `join_sample_runs_partitions_of_a_production_field` asserts survivors/checked against `CpuJoin` at the b57
    production shape on wgpu. The 1e14 compare test does **not** pin RC (it compares hits only); the author's exact
    survivor counts did.
  - The reversal's consistency in the AND (transposed and small-batch paths) is pinned only by device parity. That is
    adequate, since any slip changes survivor counts.

**4. Spills.** The explanation is plausible and partly demonstrated: the same body with a different layout lands on either
side. It is not pre-existing: the base never spills, though its codegen also varies per process. It is specific to RC.
The body should say more: M1.

**5. Tests.** See "What I ran". Lavapipe/CUDA could not run here; the author's runs are recorded in RESULTS §4.

**6. Claims.** See the table below. Naming is fine: `ac`/`pc` reused in lean mode as A2·C/P2 with `ac3`/`pc3` for n³, and
the comment at line 651 covers it. There is no dead code: `ac3`/`pc3` and `t_glo`/`t_ghi` are sized 1 or unused in
non-lean shapes, and the compiler drops them. There is no env knob in the PR. The bit-reversed convention should be
prominent: M2.

## Claims check (PR body against RESULTS and `raw/`)

| claim (PR-BODY) | source | check |
|---|---|---|
| round before the stage at b62: 71/45 → 59/35 → 51/28 → 47/24 → **41/21**; b60 69 → 41, b64 64 → 43 | RESULTS §3, `registers.txt` (XL0, XL1, X3L2c, X3L3c, P) | ✓ (the intermediate levels are the prototype's knob builds, the last is `P`) |
| "6 instructions on the FMA pipe and none on the ALU pipe" | `P` SASS 0x3130–0x3190: 2 `IMAD`, 2 `IMAD.WIDE.U32`, 2 `IMAD.HI.U32` | ✓ |
| range test rejects 26 / 5 / 0 / 0 in-AND pairs on the 1e14 fields | RESULTS §4, mutant `X4` | ✓ |
| Δ < 2b⁴ ≤ 2^25, factor 128 | my computation (actual max 2^24.67) | ✓ |
| `(b² − 1)·C < 2^32` for b < 256 | algebra; checked b ≤ 64 | ✓ |
| "and `D·Q + D·R` too" | my computation | **✗ for b = 44, 46, 47, 49–63** (L2) |
| A/B b62 1e17 108.97 → 100.38, ×1.086 (1.073, 1.086, 1.087), cycles ×1.103 | `ab_table.md` | ✓ (cycles = ratio of medians of per-run s × MHz; the product of the medians gives 1.107) |
| b62 1e16 ×1.086, b60 1e16 ×1.122, b64 1e16 ×1.070, cycles 1.075 / 1.126 / 1.104 | `ab_table.md` | ✓ |
| 1e14 ×1.027 / 1.017 / 1.006 / 0.997 with the per-round values | `ab_table.md` | ✓ |
| NiceMark score ×1.061 (1.056–1.063); scenarios 1.070 / 1.041 (min 1.007) / 1.058 / 1.068 | `nm_table.md` | ✓ |
| screen ×1.075 / ×1.111 (level 4), ×1.028 / ×1.037 (FX alone) | RESULTS §5 | ✓ |
| exact counts on every field; FD test 26 / 279 / 237,907,266; certificates 102,365 / 33,582 / 203,413 / 69,824 | RESULTS §4, `ab_table.md` | ✓ |
| rounds 128,346,267,597 → 128,350,614,206 | RESULTS §5 | ✓ (a second level-0 run differed by more) |
| registers 40 / 40 / 47 → 45 / 45 / 45–47, "some compiles" spill | `registers.txt` | ✓ but understated (M1) |
| "the diff below is this PR's commit only" | GitHub behaviour | ✗ (L1) |
| the timed build differs only by a comment, two warnings, the opt-in | `git diff 50465be d672887` | ~ (also the test lint fixes; L10) |
| lavapipe naga + SPIR-V ok, WGSL lint 16 / 0, 36 → 26 divisions | RESULTS §4 | ✓ (author's run; not reproducible here) |
| fmt / clippy default, gpu, gpu + spirv clean | my runs | ✓ all three, toolchain 1.99.1 |

## Clean-up

The worktree `.worktrees/review-l41` (detached at d672887) and its 2.8 GB target dir were removed after the runs
(`git worktree remove --force`, then `git worktree prune`). Nothing was pushed, commented on or modified on the branch;
the main checkout was not touched.
