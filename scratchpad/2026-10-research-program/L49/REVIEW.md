# L49 review: `pr/cpu-join-lean-prefilter` d32f579 (CPU join lean prefilter: FX + MT + GM), 2026-11-07

Reviewer: independent, read-only on the branch. Diff reviewed: `git diff caef70e fork/pr/cpu-join-lean-prefilter`
(`common/src/cpu_join.rs` +330/−41, `CHANGELOG.md` +1). Inputs read: L41 SCOPING §3, L41 REVIEW, L42 SCOPING §4(c)
(RC), L49 BRIEF / PR-BODY / PR-RESULTS and `raw/`, and the previous `prefilter` / `prefilter_digits` on caef70e.
Line numbers are the head's `common/src/cpu_join.rs`.

## Verdict: **merge with small fixes**

I found no correctness defect. On every input the join can produce, the lean prefilter computes the same predicate as
the division form it replaces:
- **FX:** the constants and the error bound re-derive. The CPU's operands are exactly A, P, D < b², and every triple in
  that range is covered by the opt-in exhaustive test, which I re-ran (all exact).
- **MT:** `fresh4` is the old four-mask test unrolled.
- **GM:** `gmask` is the old `seed ? mask : 0`, built at both construction sites.

Every test I ran passed: the whole `nice_common` suite, the production reference, whole b42, the exhaustive FX test,
fmt and clippy. The body's numbers match the raw logs.

What I would change before merge:
- **One cheap code change (M1).** `Top` grew 48 → 64 bytes for a field (`dm`) that only the test-shape path reads. The
  author's own profile shows the cost in the top sort.
- **Small corrections:** a test assertion and the dispatch condition read more loosely than the code (L1); doc nits
  (L2–L5); body wording (L6, L7).
- **One test gap to know about (M2).** No tested field has an unseeded top on the stepped or fixed-point path. A
  regression that applies the gate unconditionally would pass every test. This gap predates the PR (#247's `seed`
  had it too) and is dead in production, but the body's "stepped vs divided now compares `dh` and `gmask`" should
  not be read as covering it.

## What I ran (ivory, worktree `.worktrees/review-l49` detached at d32f579, `nice -n 19`, toolchain 1.99.1, release, target in the worktree)

| check | result |
|---|---|
| `cargo test --release -p nice_common` | **188 passed, 0 failed, 6 ignored**, 9.3 s (as the author's `unit-tests-head.txt`) |
| the four new CI tests, serially | all ok: `fx_digits_match_the_division` 2.6 s (prints 446,418,038 triples), `lean_membership_matches_the_masks` 2.7 s, `lean_prefilter_matches_the_division_form` 3.3 s, `production_shapes_take_the_fixed_point_prefilter` 0.4 s |
| opt-in `NICE_TEST_CPU_JOIN_REF=3` (production reference, b42–b64) | **ok**, 25.7 s |
| opt-in `NICE_TEST_JOIN_FULL_FIELD=1` (whole b42) | **ok**: 1764 partitions, **417,789,835 join survivors, 16,879,877 checked**, no hits; reference 83 s, join 12.4 s, stride 112.2 s on 4 threads |
| opt-in `NICE_TEST_FX_EXHAUSTIVE=1` | **ok**: 663,187,945,915 (A, P, D), bases 10–64, 306 s on 4 threads |
| `cargo fmt --all --check` | ok |
| `cargo clippy -p "*" --all-targets -- -D warnings` (default, CI's first lint) | ok |
| independent Python check, b = 2–64, every D < b² | `C`, `q`, `r` correct; `SmallDiv(b²)` exact on `D·r + b² − 1`; `dh` = the exact ceiling and < 2^32; `D·q` < 2^32 (u32 multiply); `(b² − 1)·C < 2^32`. **Max Δ = 26,655,048 (2^24.67) at b62**, as L41. With A, P anywhere below 2^16 it is still < 2^28.8. |
| public-API probe (separate crate outside the repo, reference join + the prefilter's definition with the gate forced off/on; tables under M2 and M1) | seed / clip coverage of every test window and four production fields; top-layer sizes of the b60 1e16 and b62 1e17 slices |

Not run:
- **The GPU-feature clippy.** `cpu_join.rs` has no feature-gated items. No other module uses `SmallDiv::rem` (removed)
  or `prefilter`; `cubecl_join` only names `CpuJoin::prefilter` in a doc comment.
- **`nice_client`'s 22 tests.**
- **Mutation runs.** I started them by adding a local probe to the worktree's test module. The session's permission
  classifier blocked that build as a modification of the reviewed tree, so I reverted it (the worktree is clean) and
  answered the "would the tests catch it" questions with the out-of-tree probe and by analysis.

## Findings

### Medium

**M1. `Top` grows 48 → 64 bytes for `dm`, which only the test-shape path reads** (`Top` lines 95–111; the only reader is
`prefilter_any`, line 940).

The struct is `p: u128` (align 16) plus 8 + 8 + 5 × 4 = 52 bytes, padded to 64. Before, it was 41 bytes padded to 48.
Production never reads `dm` after this PR: the lean path reads `dh`.

The cost shows in the author's own perf (`raw/perf-runs.txt`), in the top sort (`sort_unstable_by_key(|t| t.pc)`,
which moves whole `Top`s):

| | #247 | this PR |
|---|---|---|
| b60 1e16, sort share | 1.24 % | 1.84 % |
| b60 1e16, sort ms per partition | 32 | 43 |
| b62 1e17 s0, sort share | 1.12 % | 1.57 % |
| b62 1e17 s0, sort ms per partition | 28 | 35 |

Other per-symbol times in those single runs move by about ±20 ms, so this is consistent but not precise: about
0.3–0.5 % of a partition.

"At scale" is already what was measured. My probe gave these top-layer sizes:
- b60 1e16 (one slice): 5,073,849 prefixes.
- b62 1e17 slice 0: 4,745,416 (the body's "4.75 M" ✓). Slice 3: 4,015,693. Every b62 slice except the last is capped
  at 2^24 raw prefixes.

So a thread's per-key `tops` vector at production is about 65–85 k tops. That is 4.1–5.4 MB at 64 bytes against
3.1–4.1 MB at 48. Four threads hold about 20 MB against 15 MB, next to ivory's 16 MB L3. The tops are streamed
sequentially, and the 4-thread A/B (×1.076 / ×1.106) already includes this.

Fix (small):
- Drop `Top.dm` and recompute it in `prefilter_any`, which only test shapes reach:
  `let dm = ((top.p / self.pk) % u128::from(self.bmid)) as u64;` with the existing narrowing allow. The FD path still
  keeps `st.dm` to form `dh`.
- `Top` is then 16 + 8 + 8 + 4 × 4 = 48 bytes. Optionally add `const _: () = assert!(size_of::<Top>() == 48);`.
- `stepped_tops_equal_divided_tops_on_production_fields` keeps its strength: `dh` is strictly increasing in D
  (2^32/b² > 1), so comparing `dh` compares `dm`.

Expected effect: the sort's share back to about 1.2 %. That is an estimate, not measured. If the author prefers not to
change code, the body should at least say that the sort's share grows by about 0.6 points because of the 64-byte
`Top`; today it shows the number in the table without comment.

**M2. The seed gate's "always on" direction is untested on the stepped and fixed-point paths** (lines 547/565, 587; and
the body's stepped-vs-divided claim).

The probe (reference join on the same sampled partitions as `check_partitions`, then the prefilter's definition with
the gate as the field says, forced off and forced on):

| field | full_floor / k2 | join survivors (sampled) | on clipped tops | gate forced **off** changes | gate forced **on** changes |
|---|---|---|---|---|---|
| b10 k=1 (non-lean, no FD) | 1 / 3 | 1 | 0 | 0 | **1** |
| b20 (3,2,0) k=2 (non-lean) | 5 / 4 | 1,496 | 0 | 284 | 0 |
| b20 (2,3,1) ×2, k=3 | 6 / 5 | 1,599, 1,461 | 3, 0 | 117, 104 | 0 |
| b25 k=3, k=4 | 6 / 5, 8 / 6 | 4,251, 842 | 0 | 884, 89 | 0 |
| b30, b34, b40 ×2, b57 ×2 (k=4–5) | all ≥ k2 | 0–5 each | 0 | 0 | 0 |
| b50 k=4 | 14 / 6 | 934 | 0 | 286 | 0 |
| b54 k=4 | 14 / 6 | 445 | **210** | 156 (66 on clipped tops) | 0 |
| production b42 / b57 / b60 / b64 (3 partitions each) | 12–16 / 8 | 0.69 M – 4.46 M | 0 | 17–33 % of survivors | 0 |

Two directions of a gate regression:
- **"Never gate" (`gmask = 0`)** is caught: the prefilter-survivor comparison with `mid_mirror` differs in every lean
  window that has survivors and in every production field. Clipped tops are covered against the reference by b54
  (210 survivors on clipped tops; the gate decides 66 of them).
- **"Always gate" (`gmask = mask` regardless of the floor)** is caught only by b10, which has no FD and is not lean.
  Every FD window and every production field has `full_floor ≥ k2`. So unseeded tops never occur on the stepped path
  or the fixed-point path, and a slip in line 565's `if full_seed` (or a lean-only path that ignored `gmask` and ORed
  `mask`) passes every test.

`stepped_tops_equal_divided_tops_on_production_fields` does not close this gap:
- It compares `gmask` and `dh` only on full blocks of fields that are all seeded.
- For clipped blocks both sides run the same code (`Base::cert`, `cert_floor`, `(p / pk) % bmid`), so the comparison
  is tautological there.
- Its sample takes the first and last live partition values, not the partitions that hold the field's two clipped
  blocks.

What the test does guard is that the two construction sites stay consistent; it is not an independent check of
either.

This predates the PR (#247's `seed: fs.full_floor >= fs.k2` had the same exposure), and today the branch is dead in
production, so it is not a blocker. Fixes, either of:
- Add a small FD window with `full_floor < k2` to `windows()` (a b20–b30 field with k = 3 where the block's
  certificate reaches position k or k + 1), so that `check_partitions` sees unseeded stepped tops.
- At least reword the body: "now also compares `dh` and `gmask`" → "now also compares `dh` and `gmask`, which keeps
  the two construction sites consistent; the gate itself is checked against the prefilter's definition on the test
  windows (all their stepped tops are seeded; b10's are not)".

### Low

**L1. The dispatch and its test say less exactly what the code does** (lines 416, 1505–1515; body; commit message).
- `lean: mid == 2 && kb == 0 && bk == 0 && b2k == 0`. With `mid ∈ {1, 2}` (`FieldSetup::new`), `kb = b^(k−1) mod
  b^mid = 0` iff k > mid, and that already makes `bk` and `b2k` zero. So `lean ⟺ mid == 2 && k > 2`. That is exact
  and complete:
  - every other shape goes to `prefilter_any`, the general formula;
  - b10's k = 1 and b20's k = 2 are tested against `mid_mirror`.
- Writing it as `mid == 2 && k > mid` matches the field doc (lines 337–339). The three hoisted locals (396–398) were
  only needed for this test.
- The test asserts `join.lean == (jp.k > join.mid)` (line 1514). That equals the dispatch only because every window
  has mid = 2. A future mid = 1 window with k ≥ 2 would fail this assertion although the code is right. Use
  `assert_eq!(join.lean, join.mid == 2 && jp.k > 2)`.
- **Behaviour change the body does not mention:** mid = 1 shapes with k ≥ 2 moved from the old `prefilter` to
  `prefilter_any`. That is equivalent (kb = bk = b2k = 0, and every value is below b), but such a shape exists nowhere
  and is tested nowhere. The commit message's "Shapes with k <= mid keep the division form" is therefore incomplete.
  Say "every shape but mid = 2, k > 2 (in the tests b10's k = 1 and b20's k = 2; mid = 1 does not occur)".

**L2. `Fx` doc reuses names** (lines 212–225, 231–233, 264–267).
- In the proof, `q` is the quotient of `A + P·D` by b². The struct field `q` (documented eight lines later) is
  ⌊2^32/b²⌋.
- In `digits`, the local `x` is `F·b`, but the doc's `x` is `(A + P·D) mod b²`.
- Fix: call the proof's quotient `Q` (or `m`), and the local `fb`.

**L3. "three multiplies"** (line 213) is four with `A·C`, which this CPU code forms per pair. The body already says
"three multiplies per power (plus `A·C`)". Align the doc.

**L4. `lean_prefilter_matches_the_division_form` doc** (lines 1478–1482): "sets of up to b/2 digits (a bottom's 2k and
a gated certificate)" gives a rationale that does not hold. A production `seen` is the bottom's 12 digits plus a top
certificate, which can exceed b/2. The test is still sufficient: FX does not depend on `seen`, and
`lean_membership_matches_the_masks` covers set sizes 0..b. Drop the parenthetical or draw sizes up to b.

**L5. Per-top `dh`** (lines 569, 591). Each kept top pays a `SmallDiv(b²)` (u128 multiply) plus two u32 multiplies.
That is about 4.75–5.1 M tops per partition at the production shapes, perhaps 5–10 ms (0.2–0.4 %), an estimate.
L42's prototype instead read a b²-entry table (≤ 4096 × u32 = 16 KB). On the stepped path `dm` advances by 1, so
the reads would be sequential. Optional follow-up, unmeasured; not for this PR.

**L6. Body wording.**
- "x86 shifts take any count from 0 to 63, so no bit reversal is needed": the point holds on every target, since a
  Rust `u64 >> g` with g < 64 is defined everywhere (aarch64 `LSRV` too, and the client ships there). Say "a u64
  shift takes any count below 64 on the CPU".
- The title and CHANGELOG say "division-free" / "multiplications instead of divisions". The old code was already
  free of division instructions (reciprocal multiplies in `SmallDiv`), and the gain is fewer multiplies (about 8
  instead of 14 per survivor) and no branches. "fixed-point" is the accurate word. This is acceptable for a
  user-facing CHANGELOG line, but the PR title could be "a fixed-point middle-digit prefilter".
- The "Exactness" section has a stray double blank line after "Everything else ran on the head."

**L7. CHANGELOG** (line 13): one sentence, user-facing, after #247's line. Replace `#NNN` once the number exists.
#246 adds a line in the same place, so whichever merges second has a trivial conflict.

**L8. Test cost.** The four new CI tests take about 9 s serially in release, which is how CI runs them. A local debug
`cargo test` would spend minutes there. Nit; no change needed.

**L9. CI-level reference coverage of the lean path comes from k = 3–4 windows.** The windows with survivors in the
sampled partitions are b20 k=3 ×2, b25, b50 and b54: about 9,000 join survivors. The k = 5 windows (b34, b40,
b57) have 0–5. Production k = 6 is checked against the reference only by the opt-in `NICE_TEST_CPU_JOIN_REF` and
whole-b42 tests, and on CI's GPU jobs, where `join_sample_runs_partitions_of_a_production_field` compares the GPU
with `CpuJoin` at b57, which also runs this code on the macOS arm64 runner. Because FX depends only on A, P, D < b²,
which the exhaustive test covers, this is adequate. It predates this PR. Informational.

## The specific questions

**1. FX on the CPU.**

Operand ranges, checked in the code:
- **A:** `list` computes `divrem_small(t2)` with `t2 < M = b^(1+mid) = b³` (the column is reduced mod `big_m`), so
  `a2 = ⌊t2/b⌋ < b²`, and likewise `a3`. They are packed `a2 | a3 << 16` with b² ≤ 4096 < 2^16, and unpacked by
  `& 0xFFFF` and `>> 16` (line 275).
  - The carries are the same at key level and otherwise. There is no separate non-key packing on the CPU: the last
    bottom digit is added by `advance` either way.
- **P:** `ext.p2 = 2ρ mod b²`, `ext.p3 = 3ρ² mod b²`, with ρ = r mod b² (lines 658–662). On the lean path k > 2, so
  the last bottom digit at position k − 1 ≥ 2 leaves R mod b² unchanged.
- **D:** below `bmid = b²` on both paths. The stepped path wraps `st.dm` at `bmid` (`cpu_top_fd.rs` 441, 466); the
  divided path computes `(p / pk) % bmid`.

Constants and arithmetic, against the proof:
- `C = ⌈2^32/b²⌉`, `q = ⌊2^32/b²⌋`, `r = 2^32 mod b²`.
- `dh = D·q + ⌊(D·r + b² − 1)/b²⌋ = ⌈D·2^32/b²⌉`. The `SmallDiv` argument is below b⁴ ≤ 2^24, inside its 2^36 range
  for d = b², and `D·q` and the sum are below 2^32.
- `F = (A·C) wrapping_add (P wrapping_mul dh)` in u32: wraparound mod 2^32 is exactly the proof's "mod 2^32".
- `h = (F·b) >> 32`, `g = (lo32(F·b)·b) >> 32` in u64: these are the GPU's `mul_hi(F, b)` and
  `mul_hi(F·b mod 2^32, b)`, identical.
- The only difference from the GPU: the CPU forms `A·C` per pair with a plain (checked-in-debug) `*`, where the GPU
  keeps it per entry. The product is below 2^32 because `(b² − 1)·C < 2^32`, so a debug build would panic, not wrap,
  if A ≥ b² ever reached it. That is a useful tripwire; keep it.
- Max Δ is 2^24.67, a 161× margin.

Tests:
- The CI test checks C, q, r and `dh` exactly for every D, asserts the Δ bound from the measured ε, and checks the
  digits at the worst A and the worst P. Together with the derivation, that is a complete proof.
- The opt-in test enumerates every triple at bases 10–64. That is a superset of the join's bases (40–64) and of the
  lean test windows (20–57). Re-run here: exact.

Dispatch: L1. Exact and complete.

**2. MT.** For digits h2, g2, h3, g3:
- The old code checks g2 ≠ g3 and that g2, g3 are not in `seen`, adds them to `seen`, then checks h2 ≠ h3 and that
  h2, h3 are not in `seen ∪ {g2, g3}`.
- Pass therefore requires all six pairs distinct (including within a power: g2 = h2 fails in round two) and none of
  the four in `seen`. That is exactly `fresh4`.
- Digits are below b ≤ 64, because `F < 2^32` gives `hi32(F·b) < b`. So `seen >> g` is in range for digits ≥ 32 as
  well, and a debug build panics on an out-of-range shift.
- The test covers every 4-tuple × two random sets per base, plus 200 k random tuples per base against every set size
  0..b. That includes repeats.
- Bit order: every CPU mask is natural (digit d at bit d): `extend`/`list` build `1u64 << g`, `Base::cert` and the FD
  certificate (compared to `Base::cert` by the tests), and `fresh4` reads bit g. No CPU caller reverses. The
  reversal in #246 is local to the GPU join kernel.
- Swapped digit order (h ↔ g) cannot be caught and need not be: the predicate is symmetric in its four digits.
- A swapped power pairing (A2 with P3) would be caught: `Fx::pass` is checked against `(a2 + p2·d)` and
  `(a3 + p3·d)` on 10^6 random tuples per base, and the windows would differ too.

**3. GM.**
- `gmask: if full_seed { mask } else { 0 }` (565) and `if floor >= fs.k2 { mask } else { 0 }` (587) are #247's two
  `seed` expressions verbatim.
- Both readers OR it into `seen` (933, 954), as the old `bmask | if top.seed { top.mask } else { 0 }` did. Identical.
- `dh` is `self.fx.dh(dm)` at both sites, with dm < b² on both, so it is the exact ceiling for every top: stepped,
  divided, clipped or not.
- What the stepped-vs-divided test covers: M2 (seeded full blocks only; tautological for clipped blocks; it does not
  target the clipped blocks' partitions).

**4. Tests.** All pass (table above). Would they catch these regressions?
- **A wrong constant** (C, q, r, or a floor instead of a ceiling in `dh`): yes. The CI test asserts each against
  exact values for every D at every base.
- **A wrong D fed to `dh`:** yes, through the lean windows against `mid_mirror`.
- **A wrong gate:** "never" yes, "always" no on the FD and lean paths (M2).
- **Swapped digit order:** semantically harmless. A swapped power pairing is caught.
- **`lean` wrong:** caught by `production_shapes_take_the_fixed_point_prefilter`, and for k ≤ 2 also by the b10/b20
  windows.
- **A dropped inequality in `fresh4`:** caught by the 4-tuple enumeration.

**5. Claims, CHANGELOG, `Top`, naming, "not in this PR".** Claims: table below. CHANGELOG: L6/L7. `Top`: M1. Naming:
- `lean` is the program's word, shared with #246. It is documented at lines 337–339, but `fixed_point` would say more
  to a reader of this module. Nit.
- Dead code:
  - `SmallDiv::rem`, `smid` and the old `prefilter` body are gone.
  - `prefilter_digits` is now a one-line wrapper over `fresh_digits` with a single caller. Fine, or inline it.
  - `Top.dm` is live only for test shapes (M1).
- The double gate on the exhaustive test (`#[ignore]` plus the env variable) is necessary: `gpu-parity.yml` runs
  `-- --ignored` for the whole crate on lavapipe and macOS. Sharing `NICE_TEST_FX_EXHAUSTIVE` with #246 means one
  switch runs both exhaustive tests (about 5 min each). Fine.
- "Not in this PR":
  - **RC:** cites L42's prototype (×1.009 / ×0.987, on main before #247, 1 thread, 2 rounds) and says so. Accurate.
    It was not re-measured on #247, and the body says so implicitly with "a prototype on main (before #247)".
  - **Sharing `Fx` with the GPU module once both land:** right. The constants, `dh` and the exhaustive test are
    duplicates of #246's.
  - **A·C per listed bottom:** honest ("not tried").

**6. What a maintainer would want before merge:** M1 (drop `dm` to keep `Top` at 48 bytes, or at least state the
cost), L1 (the test assertion and the commit message's dispatch wording), L2/L3 doc nits, the `#NNN` placeholder.
Optional: an unseeded FD window (M2), the `dh` table (L5).

## Claims check (PR-BODY against PR-RESULTS, `raw/`, and my runs)

| claim | source | check |
|---|---|---|
| prefilter keeps ~6 % of pairs; b60 1e16 partition 34.2 M pairs, 2.17 M (6.3 %) checked | `ab-runs.txt` (136,900,315 / 8,692,368 over 4 partitions) | ✓ (6.35 %) |
| perf shares 36.4/28.7/22.9/9.9/1.2 → 40.3/30.5/14.7/11.7/1.8 (b60), 34.1/29.1/22.9/10.9/1.1 → 38.2/31.9/15.1/11.8/1.6 (b62); 2583/2340, 2471/2236 ms | `perf-runs.txt` | ✓ |
| `survivor` ~590 → ~345 ms (×1.7), predicts ×1.11 | 22.85 % × 2583 = 590; 14.67 % × 2340 = 343; 2583/(2583 − 247) = 1.106 | ✓ |
| main's share 17–18 % | L42 SCOPING | ✓ (cited) |
| Δ max 26,655,048 at b62, ×161 margin; b64 ε = 0 | my Python | ✓ |
| `A·C`, `dh`, `SmallDiv` ranges, `F·b < 2^38` | my Python + algebra | ✓ |
| operand ranges A, P, D < b² "re-derived for this code" | code (Q1 above) | ✓ |
| `Top` 48 → 64 bytes | layout (u128 align 16) | ✓ (cost: M1) |
| "Shapes with k ≤ mid keep the division form" | code | ~ (also mid = 1; L1) |
| 446,418,038 triples (CI); 663,187,945,915 triples, 299 s (opt-in) | Σ2b⁴, Σb⁶ for b = 10–64; my runs (306 s) | ✓ |
| "the existing test that compares stepped and divided tops … now also compares `dh` and `gmask`" | test code, probe | ✓ literally; it is a consistency check, not coverage of the gate (M2) |
| windows with k > 2 lean, b10 and b20 k = 2 divide | probe, test | ✓ |
| A/B: all ten rows (medians, rounds, spreads, per-round ratios) | `ab-summary.txt`, recomputed b60e16 1t/4t, b62e17 1t/4t, b64e14 1t | ✓ |
| every timed run has #247's counts | `ab-runs.txt`: 60 runs, one distinct (survivors, checked, hits) per case | ✓ |
| b60 / b62 1e14 counts equal #247's binary (brief's figures) | `ab-runs.txt` | ✓ |
| b62 1e17 slice 0 = 4.75 M top-layer prefixes | probe: 4,745,416 | ✓ |
| NiceMark score 798.5 → 868.5, ×1.088, per round 1.104/1.091/1.074/1.069; scenarios | `nicemark-summary.txt` (medians recomputed) | ✓ |
| PR's 4th b62 NiceMark run low, median excludes it | `nicemark-summary.txt` | ✓ |
| Zen 2 EPYC-Rome VM, AVX2 only, 4 vCPU | `lscpu` | ✓ |
| 188 + 22 passed, 6 ignored | my run (188 / 6; client not run) | ✓ |
| prodref ok; whole b42 417,789,835 / 16,879,877, join 12.1 s | my runs (12.4 s) | ✓ |
| fmt, default clippy clean; GPU feature sets do not touch this code | my runs; grep | ✓ |
| timed build differs from head only by `fresh4` parentheses; harness binary byte-identical | `build-head.log` | not re-checked; plausible (same parse) |
| RC ×1.009 / ×0.987 on main, 1 thread, 2 rounds | L42 SCOPING §4(c) | ✓ |

## Clean-up

The review worktree `.worktrees/review-l49` (detached at d32f579; clean at removal, the blocked probe edit having
been reverted with `git checkout`) and its target dirs (`target/` 1.6 GB, `target-probe/` 0.26 GB) were removed after the runs
(`git worktree remove --force`, then `git worktree prune`). The out-of-tree probe crate in `/tmp/l49-review/` was
deleted. Nothing was pushed or commented on, the branch was not modified, and the main checkout was not touched. Disk:
15 GB free before, unchanged after.
