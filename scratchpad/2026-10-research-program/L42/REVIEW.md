# L42 review: `pr/cpu-join-fd-tops` (fba5431, one commit on upstream main 6f060a9)

Independent review, 2026-11-06, on ivory. "Finite-difference top certificates in the CPU join".

## Verdict

**Merge with small fixes.** I found no correctness defect. The stepped certificates are exact for every prefix
`tops()` can produce. The carry test's f64 screen is sound by about five orders of magnitude. `pc` and `dm` step
exactly. Every test, lint and opt-in check reproduces. Before opening:

- add one small test for the carry chain through words of `b − 1`, which no test exercises today (S1);
- fix five factual slips in the body (S2);
- fill the CHANGELOG's `#NNN`.

The rest are nits.

## Findings

### Should fix before opening

**S1. No test exercises a carry through a word of eight `b − 1` digit sums.** It is reachable in production, and
the fix is a ten-line test. I ran mutation tests (`raw/review/mutate.txt`):
- Two mutations survive every test in the crate:
  - **M1:** drop the ripple past the carry word (`cpu_top_fd.rs:77`, `if co && false`).
  - **M4:** drop `c2`, the carry the `cin` add makes, from `add_word`'s carry-out (`cpu_top_fd.rs:59`,
    `let cout = c1;`).
- Both fire only when a word's eight digit sums are all `b − 1` and a carry comes in. That is about `b^-8` per word-add.
- The ripple past the carry word (M1) cannot happen at production shapes. With `o = 3` and `t ≤ 10`, every destination
  array is too short for a carry past its carry word: SQ < b^20 against b^24, CU < b^30 against b^32, DC < b^24
  against b^24 or b^32 (DS and DDC likewise).
- The in-word case (M4) can happen in production. At b60 1e16, ~7·10⁶ steps a partition and ~8 live word-adds a step
  put it at roughly one occurrence per thousand b60 1e16 fields run on the CPU. That is rare, but it is not never.
- The code is correct today. I checked `add_word` by hand for the all-`0xFF` case: `carried = LO` and the result is
  all zeros. It is also detailed_fd's biased add. But the PR's own tests never execute that branch, so a later edit
  could break it unnoticed.
- Fix: a direct test in `cpu_top_fd::tests`. The version below kills both M1 and M4 (checked) and runs in under a
  millisecond:

```rust
/// A carry through words of b − 1: into word 0, through the words above
/// it (a carry in over eight digit sums of b − 1), and past the carry word.
#[test]
fn a_carry_runs_through_words_of_b_minus_1() {
    for b in 7..=64u32 {
        let (bias, top) = (256 - u64::from(b), u64::from(b - 1));
        for hi in 1..NW - 1 {
            let mut x = [0u64; NW];
            x[..=hi].fill(top * LO);
            x[hi + 1] = top | (top << 8);
            let mut one = [0u64; NW];
            one[0] = 1;
            add_digits(&mut x, &one, 0, hi, bias);
            assert!(x[..=hi].iter().all(|&w| w == 0), "b{b} hi {hi}");
            assert_eq!(x[hi + 1], 1 << 16, "b{b} hi {hi}");
        }
    }
}
```

**S2. Body claims that do not match the evidence.** None changes the conclusion.
1. **NiceMark rows.** The b60 row says "sampled from a 1e16 field" and the b62 row "sampled from a 1e16 window". On
   the CPU both are their `cpu_size` = **3e15** heads (`bench_defs.rs:155–181`; the JSONs' `window_size` is
   3000000000000000). Say "a 3e15 window of a 1e16 field".
2. **#240's top-kernel gain.** The body says "×1.48–1.59". #240's table gives ×1.483 (b60), ×1.585 (b62) and ×1.605
   (b58), so it should be ×1.48–1.61.
3. **Exactness bullet.** "1,860,723 unclipped blocks certified (413,250 kept, **243,907 of them seeds**)". The test
   counts seeds over all certified blocks, not over the kept ones (`cpu_top_fd.rs:673`). Say "413,250 kept; 243,907
   seeded".
4. **Method.** "kept only rounds that started at ≤ 2" suggests rounds were discarded. None was: the script waits
   for load ≤ 2 before each round, and all three rounds ran (1.64, 1.87, 1.97). Say "every round started at a 1-min
   load ≤ 2".
5. **Soundness → No overflow.** "it steps only to the prefix it then certifies" is not what the code does.
   - `advance` (`cpu_top_fd.rs:472–482`) can step past P when P − st.p is not a multiple of h, then seeds.
   - That cannot happen in the join: every prefix of one `tops()` call is ≡ key·b^p + v mod h. But the code handles
     it, and the random test reaches it (mutation M9, "don't re-seed after an overshoot", is caught only by
     `stepped_certificates_equal_the_divided_ones`).
   - The overshoot is harmless: the addends used are always at a prefix < P ≤ phi. The overshot values (< phi + h)
     still fit the six words: P³ ≤ 29 digits at every base 40–64 against 48. The values are discarded by the seed.
   - Suggested wording: "In the join every gap is a multiple of h, so the walk lands on P; one that would not (only
     the tests make one) re-seeds, and the values it passed through still fit."

**S3. CHANGELOG** (`CHANGELOG.md:12`): replace `#NNN` with the PR number once it is opened. The line is one
sentence and matches its neighbours' style.

### Nits (optional)

- **N1 — rustdoc warning.** `cpu_join.rs:13` links `[`crate::cpu_top_fd`]` from a public module's docs to a private
  module. `cargo doc -p nice_common` gives a new `rustdoc::private_intra_doc_links` warning. main already has
  several rustdoc warnings and CI does not build docs, so this is cosmetic. Fix: plain backticks, or link `CpuJoin`'s private docs
  instead.
- **N2 — derives for tests only.** `Top` gains `Debug, PartialEq, Eq` only for the tests (`cpu_join.rs:93`). Use
  `#[cfg_attr(test, derive(Debug, PartialEq, Eq))]`.
- **N3 — field widening.** `Base::poww` is widened to `pub(crate)` (`overlap_join.rs:549`) only for `poww.clone()`
  (`cpu_top_fd.rs:303`). A `pub(crate) fn poww(&self) -> &[W4]` accessor keeps the field private (`poww_words` at
  `:692` is the existing pattern). The other widenings (`ndig_w`, `digit_range_mask`, `close_certificate`,
  `SmallDiv`) are reuse rather than copies, which is the right call.
- **N4 — `MAX_STEPS` visibility.** `MAX_STEPS` is `pub(crate)` (`cpu_top_fd.rs:39`) but only used in its module;
  make it private.
- **N5 — production test sampling.** `stepped_tops_equal_divided_tops_on_production_fields` uses
  `step_by(live.len().div_ceil(24))` (`cpu_join.rs:1027`), which panics on an empty `live` (`step_by(0)`); use
  `.max(1)` as `check_partitions` does. `vs.extend(live.last())` can repeat the last partition when the stride lands
  on it, so "25 partitions" may be 24 + a repeat. That is harmless.
- **N6 — duplicated certificate logic.** `TopFdSetup::cert` (`cpu_top_fd.rs:548–584`) duplicates `Base::cert`'s scan.
  If `Base::cert` changes, the two can drift. The equality tests (window, production and random) would catch that,
  so no action is needed beyond being aware of it.
- **N7 — b64 not measured.** The body never mentions b64, and a reader of #240 will ask: the GPU kept the old kernel
  at power-of-two bases because FD was slower there.
  - On the CPU that reason does not apply: `digits_w` still divides by a runtime `b` at b64.
  - SCOPING §3.4 measured the certificate alone at ×1.41–1.64 at b64.
  - b64 takes the stepped path here (checked: 14–15 word-adds a step).
  - One sentence in the body would pre-empt the question. A b64 A/B would settle it.
- **N8 — plan coverage.** SCOPING §6 item 3 planned the first and last slices of a 1e17 plan in the host test. The
  test uses the 1e13/1e14 `PLAN_FIELDS`. The A/B harness covers b62 1e17 slice 0 by survivor counts, and the word
  counts do not change with field size (below), so this is a small gap. Adding the last slice of a 1e17 plan would
  cover the end-of-field clipping at production phi.

## Exactness: what I checked and how

1. **The step: the five packed additions, the trimmed word counts, overflow.**
   - **The step identities:**
     - SQ(P+h) − SQ(P) = 2Ph + h² = DS(P);
     - DS steps by 2h²;
     - CU(P+h) − CU(P) = 3P²h + 3Ph² + h³ = DC(P);
     - DC(P+h) − DC(P) = 6Ph² + 6h³ = DDC(P);
     - DDC steps by 6h³.

     The order in `step` (`cpu_top_fd.rs:447–467`) consumes each addend before updating it. The binary differences
     check out too: d2 = δ(2a + δ) steps by 2δH; d3 = δ(3a² + 3aδ + δ²) steps by Δ3 = 3δH(2a + H + δ); Δ3 steps by
     6δH². All three match the seed (`:433–439`) and `c2`, `c3` (`:362–363`).
   - **The biased add** (`add_word`, `:55–62`) is exact for digits < b ≤ 255. `rb`'s bytes do not overflow. The
     carry into byte i+1 is bit 8(i+1) of `t ^ a ^ rb`, including the `cin` chain. At most one of `c1`, `c2` is set.
     A byte with no carry-out is ≥ bias, so subtracting the bias never borrows. `2h²` and `6h³` are single digits for
     b ≥ 7 (`try_new` requires 7..=64).
   - **Trimmed word counts.** `add_digits(x, y, 0, hi)` needs y = 0 from word `hi` up, and x's result to fit the six
     words.
     - Every addend used is DS/DC/DDC at a from-prefix < P ≤ phi. All three are increasing in P, so they are below
       their values at phi, which set `addend_words` (`:311–319`).
     - Each destination's new value is at a prefix ≤ phi (or < phi + h on an overshoot), and its digits are bounded
       by P³'s.
     - `fits` (`:323–330`) checks every array, the carry words (`addend_words < NW`, `dddc_at + 1 < NW`; `dds_at ≤
       dddc_at`), and that `6δH` fits u128.
     - The seed's `sum` and `shl_digits` operate on partial sums of DS/DC/DDC at P ≤ phi, so they fit too. Their
       overflow is only `debug_assert`ed, which is fine given `fits`.
   - **Every base 40–64 with a band:** review test `review_production_fits` (`raw/review/review_tests.rs`), 1608
     fields of 1e13/1e14/1e16/1e17 at 202 points across each band, both ends. Every one takes the stepped path. Word
     adds a step: 12–13 at b40–b47, 14 at b49–b63 (b48 13–14), 14–15 at b64. **So the body's "14 at b60 and b62" is
     right.** P³ has at most 29 digits (b62–b64) against 48: ample room.

2. **The seed's conversion** (`to_digits`, `:385–405`) is exact.
   - `Div64` (Möller–Granlund) by b^8 and b^4 returns exact quotients and remainders.
   - `SmallDiv::divrem` is exact for x < 2^48/d, and each half-chunk is < b^4 ≤ 2^24. Magic = ⌈2^48/d⌉, so the error
     term is below x/2^48 < 1/d.
   - x < b^48 is guaranteed by `fits`, so at most six chunks.

3. **The carry screen** (`carry`, `:523–541`).
   - **The exact condition** is `(a^j mod b^c0) + d ≥ b^c0`, with `a^j mod b^c0 = (P^j mod b^(c0−z))·b^z` for
     c0 > z (zero otherwise). Dividing by b^(c0−2): `R/b^(k−2) + D ≥ b²`, with R/b^(k−2) ∈ [r, r+1) and D =
     d/b^(c0−2) < b².
   - **Error bound.** `w4_f64` has relative error ≤ 3·2⁻⁵³ (two conversions, one add, the dropped words < 2⁻⁶⁴).
     `inv[c0]` adds a division rounding (≤ 4·2⁻⁵³), and the product one more, so D̂ is within 2⁻⁵⁰ relative, under
     2⁻³⁸ ≈ 3.6e-12 absolute. The sum `r + D̂` (< 2¹³) adds ≤ 2⁻⁴¹. Total < 4e-12, against a margin of 2⁻²⁰ ≈
     9.5e-7.
   - **True branch.** It returns true only when r + D̂ ≥ b² + m, so T ≥ r + D > b².
   - **False branch.** It returns false only when r + 1 + D̂ ≤ b² − m, so T < r + 1 + D < b².
   - So it never decides a case the exact test would decide differently. `b² ± 2⁻²⁰` is exact in f64. Rust does not
     contract floating-point operations, so this is identical on every target.
   - **Adversarial inputs** (review test `review_carry_boundary`).
     - Bases 7–64, f0 = 1–3, o = 1–3, z = 2f0 and 3f0, 14 values of c0 above each z.
     - X random with runs of b−1 and 0. d at the exact boundary (rem + d = b^c0) and at both screen thresholds
       ((b² − r)·b^(c0−2) + b^(c0−2)/2²⁰ and (b² − r − 1)·b^(c0−2) − b^(c0−2)/2²⁰), each ±0–3, plus random d.
     - Result: **20,701,691 calls, all equal to the exact test.** 3,945,508 true and 3,825,330 false were decided by
       the screen right at its thresholds.
     - It catches a margin-sign flip (M7) and an r/r+1 slip (M8). The PR's own random test also catches both.
   - **Edge cases.** For k < 2 and c0 ≤ z, the exact path is taken. When c0 ≤ z, rem = 0 and d < b^c0, so it returns
     false, which is what `Base::cert` computes. `rem + d < 2·b^c0 ≤ 2·a^j < 2²⁵⁶`, as in `Base::cert`.

4. **The certificate** (`cert`, `:548–584`) is `Base::cert` with digit `pos` of a^j read as digit `pos − z` of P^j (0
   below z).
   - `ndig` from the bit-length table: d ∈ [2^(L−1), 2^L) gives ndig ∈ {c, c+1}, since b ≥ 3 and `pw[c]` exists (c ≤
     s3 < `pw.len()`, checked in `fits`). d = 0 gives 0.
   - The run of b−1 terminates even reading past sp: P^j's digits above `sp − z` are 0 ≠ b−1.
   - `digit_range_mask(g, g+1)` has g ≤ b−2.
   - `close_certificate` is shared.

5. **The walk's orderings.**
   - **Exactness does not depend on order.** Every `advance` either steps exactly from the state's own P or seeds
     from scratch. A backward or equal P seeds (`p > st.p` fails). An overshoot seeds. The first prefix seeds (`p =
     u128::MAX`).
   - **What `tops()` produces.**
     - Ascending within a key: `top_layer` is breadth-first and ascending, and `CpuJoin::new` sorts it stably by key.
     - Gaps that are multiples of h, so no overshoot.
     - Clipped blocks only at P = plo / phi of the slice. They go through `Base::cert` and leave the state alone.
     - A fresh `TopFd` per `tops()` call, so per key and partition.
     - FD off when `fits` fails: never at b40–64, and b10's window has f0 = 0.
   - **Slices.** Every slice is a `CpuJoin::new` with its own phi (client `main.rs:881`, `bench.rs:590`), so
     `addend_words` always comes from the slice being run.

6. **`pc` and `dm` for kept tops** equal main's u128 expressions for every P.
   - h = b^o ≡ 1 (mod b−1), so `pc` steps by 1 mod b−1.
   - ⌊(P+h)/h⌋ = ⌊P/h⌋ + 1, and main's divisor `pk` = b^(k−f0) = h, so `dm` steps by 1 mod b^mid.
   - Both start from the exact mod at the seed. `seed`, `rlo` = 0 and `rhi` = w are main's values for an unclipped
     block (`full_floor`).
   - Checked by both new tests: the random test asserts pc/dm on every block, and the production test compares whole
     `Top`s.

## Tests: would they catch a dropped carry or a wrong seed?

Mutation runs: one release build per mutation. Each runs the two new tests, the windows and slices tests, stride
agreement, and my boundary test (`raw/review/mutate.sh`, `mutate.txt`).

| mutation | caught by |
|---|---|
| M1 ripple past the carry word dropped | **nothing** (S1) |
| M2 carry into the carry word dropped | random test, production test, windows, slices |
| M3 addend words trimmed by one | random, production, windows, slices |
| M4 `add_word` loses the `cin` carry (`cout = c1`) | **nothing** (S1) |
| M5 seed DS without h² | random, production, windows, slices |
| M6 seed DDC without 6h³ | random, production, windows, slices |
| M7 screen margin −2⁻²⁰ (unsound screen) | random test; review boundary test |
| M8 screen's false branch uses r for r + 1 | random, production, windows; review boundary test |
| M9 overshoot not re-seeded | random test only (the join cannot overshoot) |

So: a wrong seed or a lost carry *between* words is caught at once, by four tests. A lost carry *through a word of
b−1 sums* is not (S1); the proposed test kills both M1 and M4. `cpu_join_agrees_with_the_stride_path_on_whole_windows`
caught none of these. Its windows are evidently too small to be affected, or the corrupted certificates did not
change their (empty) hit sets. That is expected: it was not written for this.

## Claims check (body against `PR-RESULTS.md`, `raw/pr/`, and my runs)

| claim | status |
|---|---|
| A/B table: medians, rounds, spreads, ×, per-round ratios (8 rows) | **matches.** `raw/pr/scripts/analyze.py` over `ab-runs.txt` reproduces every figure; whole-field wall seconds check against the raw `wall` lines. |
| "Every run of both sides found the same join survivors and full checks" | **matches** (every row, every round) |
| NiceMark score ×1.186 and per-scenario rows | **numbers match** (analyze.py over the 8 JSONs). **The b60/b62 descriptions are wrong:** 3e15 CPU windows, not 1e16 (S2.1). |
| "1876 setups, 1,860,723 blocks, 413,250 kept, 243,907 seeds, 3654 clipped" | **reproduced exactly.** "of them seeds" is wrong (S2.3). |
| "3,698,847 tops" over 6 plan fields | **reproduced exactly** (468,727 + 1,521,618 + 692,904 + 260,942 + 429,898 + 324,758) |
| `cargo test --release -p nice_common`: 183 passed, 5 ignored | **reproduced** (nice_client's 22 I did not rerun; in `raw/pr/unit-tests.txt`) |
| Opt-in production reference (`NICE_TEST_CPU_JOIN_REF`) passes | **reproduced** at =3 (25.7 s) |
| Whole b42 field: 1764 partitions, 417,789,835 / 16,879,877, no hits | **reproduced exactly** (reference 84 s, join 12.6 s, stride 112.1 s on 4 threads) |
| fmt, clippy default features clean (rustc 1.99.1) | **reproduced.** The repo pins 1.99.1 in `rust-toolchain.toml`, so that is CI's compiler. I also ran CI's second lint, `--features nice_client/gpu,nice_client/cubecl-spirv`: clean. |
| "14 word additions a step at b60 and b62" | **confirmed** for every sampled field (b64 14–15) |
| "Every production field (b40–b64) … fits" | **confirmed** across all bands, 1e13–1e17 |
| "×1.48–1.59" for #240's top kernel | **slightly off:** ×1.48–1.61 (S2.2) |
| 1.38–1.43 steps per prefix, 2.3–4.7 % seeds; 42–43 % share; ~57 % on two `div`s; ~650 cycles | **match SCOPING** §2 and §3.1. These are prototype/main measurements with the same walk rule, not re-measured on the PR. |
| "kept only rounds that started at ≤ 2" | **wording:** none was discarded (S2.4) |
| Soundness "steps only to the prefix it then certifies" | **inexact** for the defensive overshoot path; harmless (S2.5) |
| NiceMark JSONs' `build_sha` | Both sides read `6f060a9`, because the PR binary was built from the uncommitted tree (PR-RESULTS says so; code identical to fba5431). This is not in the body, which is fine, since the JSONs are not public. |
| CHANGELOG line | One sentence, user-facing, consistent with #235/#237/#240's. `#NNN` placeholder (S3). |

## What I ran

All in a throwaway worktree `.worktrees/review-l42-fd` at fba5431 (detached), with `CARGO_TARGET_DIR` inside it,
`nice -n 19`, release, rustc 1.99.1 (the repo's pin). The target peaked at 2.1 GB. The target and the worktree are
removed; the main checkout was not touched.

- `cargo test --release -p nice_common`: 183 passed, 5 ignored; new-test counts as above.
- `NICE_TEST_CPU_JOIN_REF=3 … cpu_join_matches_the_reference_on_production_fields --ignored`: ok.
- `NICE_TEST_JOIN_FULL_FIELD=1 … cpu_join_matches_the_reference_on_a_whole_field --ignored`: ok.
- `cargo fmt --all --check` (1.99.1): clean.
- `cargo clippy -p "*" --all-targets -- -D warnings`: clean.
- `cargo clippy -p "*" --all-targets --features nice_client/gpu,nice_client/cubecl-spirv -- -D warnings`: clean.
- `cargo doc -p nice_common --no-deps`: one new warning (N1).
- **Review tests**, appended locally to `cpu_top_fd.rs`, never committed (`raw/review/review_tests.rs`), all pass on
  the PR's code:
  - `review_production_fits`: every base 40–64, 1608 fields each;
  - `review_carry_boundary`: 20.7 M boundary calls;
  - `review_ripple`: the S1 test, which fails under M1 and M4.
- **Mutation runs** M1–M9 (`raw/review/mutate.sh`, `mutate.txt`). The script expects `/tmp/cpu_top_fd.review.rs` =
  the PR's file + `review_tests.rs`.
- **Claims:** `raw/pr/scripts/analyze.py` over the A/B log and the NiceMark JSONs; `bench_defs.rs` for the NiceMark
  windows; `gh pr view 240` for #240's figures.

Logs: `raw/review/` (`unit-tests.txt`, `optin-tests.txt`, `clippy.txt`, `mutate.txt`, `review_tests.rs`,
`mutate.sh`).
