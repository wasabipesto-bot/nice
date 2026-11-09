# L56 review: `pr/cpu-join-seeded-check` (fork, head `5c218b7`)

Independent review, 2026-11-09, on ivory (Zen 2, 4 vCPU, AVX2), of the one commit `5c218b7` on fork `pr/cpu-join-two-pass-scan` `1cce00d`: `git diff 1cce00d fork/pr/cpu-join-seeded-check` (+1306/−69: `common/src/cpu_check.rs` new, `cpu_join.rs`, `cpu_top_fd.rs`, `overlap_join.rs`, `lib.rs`, CHANGELOG). Read against the old full check on `1cce00d` (`get_is_nice`, `get_is_nice_with_known_lsd`), `Base::cert`/`close_certificate`, `CpuJoin::tops`, L47/SCOPING.md §(b) (the warning that seeding with the post-closure mask is unsound), and the GPU twin `join_check` on fork `pr/check-d` (`e28b79f`). Everything I ran was in my own worktree (`.worktrees/l56-review`, detached at `5c218b7`, `CARGO_TARGET_DIR` inside it, `nice -n 19`, release only); the branch, the main checkout and GitHub were not touched.

## Verdict

**Merge with small fixes.** I found no soundness defect. Each of the three seeded digit sets is exactly the true digits of `n²` and `n³` at its positions for every survivor it is used for, the closure-forced digits are excluded by construction, the seed is used only under the same flag that makes the prefilter test against the certificate (which is what makes the low and top sets disjoint), and the column form's arithmetic is exact with proofs that check out and are enforced per field at setup. The tests are strong where it matters: on every recorded survivor they assert the seeds equal the true digits position by position, and my mutation runs show that a seeded closure digit, a seed position off by one either way, a wrong magic constant, a cube scan stopped at the square's end and a swapped square/cube coefficient in the re-read prefilter digits are each caught by the CI suite; the one gap is below (1). Everything in the body's tables matches the raw logs.

Before merge I would ask for one test and a few text corrections (all small):

1. **(Medium) The verdict path's `true` is only ever tested at one limb.** No test makes `Check::nice` (the non-count path, the one that decides hits) return `true` for `n` of more than two digits: the only nice `n` the tests have is 69. An edit to the early exit that rejects every nice `n` of the production shape passes the whole `nice_common` suite (mutants M4, M4b). A 60-line property test closes it (under M-1; I ran it: it passes on the branch in 0.9 s, produces `true` at every limb count, and catches both mutants).
2. **(Low) Body: the b58 explanation is wrong** ("whose partitions check a larger share of their pairs": b58 checks the *smallest* share).
3. **(Low) Doc/comment inaccuracies:** `e = 10 at bases 39–64` (b40's `e` is 8), "four more quotients" (three at b40), and `n² < b^(2·nl)` (should be `b^(4·nl)`, i.e. `(b²)^(2·nl)`), in the module doc, two comments and the body.
4. **(Low) Readability:** the inner `from` in `cert_parts` shadows the new outer `from` array.

`Magic` and the GPU's `join_check::magic` compute the same constant; unify them later, in whichever of the two PRs lands second (as the body says), not now.

## 1. Findings

### M-1 (Medium, fix before merge): the verdict path's `true` is tested only at one limb

`Check::nice` (`COUNT = false`) is the code that decides hits. Its `true` is reached in the tests only by 69 at base 10 (`sixty_nine_is_nice`, `cpu_join_finds_69_in_base_10`, the 12 "nice" decisions of `the_seeded_check_decides_what_the_full_check_decides`, all `NL = 1`). Every other `nice()` call in the tests (near-nice `n`, adversarial and random `n`, every recorded survivor of every field) has the answer `false`, and the digit-level tests run count mode, which disables the early exits. So the property "a nice `n` of 3–16 digits gets `true`" rests on reading the code (it holds: the exits are all `return (false, …)` under the sticky `repeat`), not on a test. Two mutants show the gap: **M4** (`if !COUNT && $j % 2 == 1 && (sc.repeat || $j == 3)`, an exit that drops every survivor whose `n²` scan reaches column 3, i.e. the windows' shapes with `k2 ≤ 7`) and **M4b** (the same at column 5, inside the production shape's middle, `k2 = 8`) each **pass the whole `cargo test --release -p nice_common` suite (196 passed)**. In production M4b would discard every hit; nothing in CI would notice, and the A/B and NiceMark counts would not change either (survivors and checked counts come before the check, and production has no hits). It is the one regression in this module that costs hits without failing a test, and a future tweak of the exit cadence ("test every column", "every third") is exactly the kind of edit that could introduce it.

**Fix:** a property test that compares the verdict path with count mode on arbitrary masks, including masks chosen to miss every middle digit, so that `true` is produced at every limb count. Count mode is already pinned to malachite digit by digit, so this transfers that to the verdict path. The test I ran (append to `cpu_check::tests`; it reuses the module's `adversarial`, `xorshift`, `check_for` and `SHAPES`):

```rust
/// The verdict path (`nice`, which stops at a repeat) agrees with
/// count mode's `!repeat` on any mask, including masks that miss every
/// middle digit, so that its `true` is taken at every limb count (no
/// nice `n` is known past base 10, so the other tests only see it at
/// 69, one limb).
#[test]
fn the_verdict_agrees_with_count_mode_on_any_mask() {
    let mut r = 0x1234_5678_9ABC_DEF1u64;
    let (mut runs, mut yes) = (0u64, [0u64; MAX_NL + 1]);
    for b in 3..=64u32 {
        let bb = u128::from(b);
        for l in 2..=16u32 {
            if bb.pow(l - 1) >= 1 << 85 {
                break;
            }
            let (lo, hi) = (bb.pow(l - 1), (bb.pow(l) - 1).min((1 << 85) - 1));
            let mut ns = adversarial(b, l);
            for _ in 0..6 {
                let x = (u128::from(xorshift(&mut r)) << 64) | u128::from(xorshift(&mut r));
                ns.push(lo + x % (hi - lo + 1));
            }
            for n in ns {
                for &(f0, k2) in SHAPES {
                    let Some((check, s2, s3)) = check_for(n, b, f0, k2) else {
                        continue;
                    };
                    let w = bb.pow(f0);
                    let (p, r0) = (n / w, u32::try_from(n % w).unwrap());
                    for _ in 0..4 {
                        // Short middles half the time, so that their digits
                        // are often distinct; any middle otherwise.
                        let cap = if xorshift(&mut r) % 2 == 0 { 8 } else { 48 };
                        let span = |s: u32, r: &mut u64| {
                            k2 + u32::try_from(xorshift(r) % u64::from((s - k2 + 1).min(cap))).unwrap()
                        };
                        let ends = [span(s2, &mut r), span(s3, &mut r)];
                        let middle = check.count(p, r0, 0, ends, false);
                        let seen = if xorshift(&mut r) % 2 == 0 {
                            !middle.mask & xorshift(&mut r)
                        } else {
                            xorshift(&mut r)
                        };
                        let want = !check.count(p, r0, seen, ends, false).repeat;
                        assert_eq!(
                            check.nice(p, r0, seen, 0, ends),
                            want,
                            "b{b} n = {n} f0 {f0} k2 {k2} ends {ends:?} seen {seen:#x}"
                        );
                        runs += 1;
                        if want {
                            yes[check.nl as usize] += 1;
                        }
                    }
                }
            }
        }
    }
    eprintln!("{runs} verdicts; true by limb count (0 = long division): {yes:?}");
    assert!(yes[1..].iter().all(|&y| y > 0), "{yes:?}");
}
```

On the branch it passes in 0.9 s (release): 1,195,784 verdicts, `true` at every limb count (long division 7,492; `NL` = 1…8: 7,161, 34,454, 23,646, 14,888, 13,234, 12,325, 8,893, 4,195). With M4 it fails at once (b3, `n = 80`, `f0 = 2`, `k2 = 7`, ends `[8, 8]`: `nice` says `false`, count mode `true`), and with M4b too (b3, `n = 270`, the production shape `f0 = 3`, `k2 = 8`). It needs `Check::nl` visible to the test (it is: same module).

### L-1 (Low, body): the b58 explanation is wrong

`PR-BODY.md` line 75: "b58 1e15, whose partitions check a larger share of their pairs, gains ×1.17". From the A/B counts, b58 checks **5.64 %** of its AND survivors (18,029,967 / 319,652,260), less than b60 1e16 (6.35 %) and b62 1e17 (5.95 %). What is larger is the rate of checks per unit time: 563 k checks in 415 ms per partition (1.36 per µs) against 2.17 M in 1743 ms at b60 (1.25 per µs), so the check is a larger share of b58's *time*. Suggested: "b58 1e15, whose partitions spend a larger share of their time in the check (1.36 checks per µs against 1.25 at b60), gains ×1.17." (Even that predicts ~×1.13, so ×1.17 is somewhat more than the share explains; the honest phrasing is "gains ×1.17" without a cause, or with this one hedged.)

### L-2 (Low, docs and body): three inaccurate statements

- `cpu_check.rs:17` (module doc) and the body (line 12): "`e` (10 at bases 39-64)". `e` is the largest even `≤ 2·nl` with `b^e < 2^63`, i.e. `min(2·nl, 10)` there. At b40 the band's `n` has `l = 8` (a 9-digit `n` already has `s2 + s3 ≥ 17 + 25 > 40`), so `nl = 4` and `e = 8`. Say "`e = min(2·nl, 10)` at bases 39–64 (10 from b42 up)". The body's "four more independent quotients by `b^2i`" is `eh − 1`: four at `e = 10`, three at b40.
- `cpu_check.rs:412–413` ("n² < b^(2·nl) has 2·nl columns") and `:441` ("The top column's carry is 0 (n² < b^(2·nl))"), and the body's Soundness ("carries nothing out (`n² < b^(2·nl)`)"): `n < b^l ≤ b^(2·nl)`, so `n² < b^(4·nl) = (b²)^(2·nl)`. Write `(b²)^(2·nl)` (2·nl base-b² limbs).
- The body's "The column form against the long division: ×1.5–1.8" compares with the bench's V3 form (two quotients by `b⁴`, five digits per quotient by `b⁵`), not with this PR's own `long` fallback (one quotient by `b` per digit); say "against the chunked long division (the table's second form)".

### L-3 (Low, readability): `from` shadowed in `cert_parts`

`overlap_join.rs:837` adds `let mut from = [self.s2, self.s3];` and the loop binds its element as `first`, while `:854` keeps the old `let mut from = 0usize;` (an index into `dx`, the run's end). Two different `from`s, one an absolute position array and one a relative index, three lines apart, and `Cert::from` is the absolute one. Rename the inner one (`run`, or `skip`) so `*first = c0 + run as u32` reads as what it is.

### L-4 (Low, process): fmt/clippy logs are from `5bab136`

`raw/clippy-default.txt` is on `5bab136e` (before the comments-only amend). I re-ran both on `5c218b7` (rustc 1.99.1, default features): both clean. Nothing to fix; replace the log when the body cites it.

### Nits (optional)

- **N-1** `Scan<false>` still carries `trace: [[u8; 48]; 2]` and `Scan::new` fills it. It is optimised out (no fill in `full_check`'s code), but giving the verdict path a zero-sized trace (a small trait with a no-op `record`, implemented by a ZST and by the `[[u8; 48]; 2]` array; a `[_; if COUNT {48} else {0}]` length is not stable Rust) would state the intent instead of relying on the optimiser.
- **N-2** `Check::limbs` is `pub(crate)` but used only in `columns`; `Check::bf0` duplicates `w` as `u64`; `Check::new`'s `by(..)` silently maps an overflowing `b^i` to 2 (fine, unused unless columnar; a comment would save a reader the check).
- **N-3** `mid_bits` recomputes the prefilter's digits instead of the prefilter returning them. It is the cheaper choice (only checked survivors pay), and `assert_checked` would catch drift, but a one-line comment at `Fx::pass` / `prefilter_digits` ("`mid_bits` re-reads these digits; keep them in step") would help a future editor.
- **N-4** The top's digits are the soundness-sensitive half of the PR and buy little in place: ×1.010 (b60 1e16) and ×1.023 (b62 1e17) over the same check without them (`raw/ab-variants-summary.txt`), inside the variants' round spread (b60 "notop" rounds 1718, 1606, 1627). On recorded survivors they take a check from 38–41 to 28–29 ns. The body reports this honestly. I would keep them (they are proved and pinned by the strongest assertions in the suite), but a maintainer could reasonably ask to drop `Cert`, `seed`, `ends` and `gate` for a simpler PR; the answer should be in the body's first lines rather than at the end of the bench section.
- **N-5** `full_check` is 28.9 KB (eight `NL` instantiations of `columns` inlined); only one is hot per field. Not worth changing now.
- **N-6** The body is 4,260 words, the longest of the stack (#248's 3,709, the two-pass scan's 3,867). The Exactness and Measurements sections could go under `<details>`.

## 2. Tests: what would they catch? (mutation runs)

Each mutant is a one-line edit in my worktree (reverted after), built in release, run on the module's CI tests (`cpu_check::*`, `cpu_join_matches_the_reference_on_the_test_windows`, `the_full_check_is_exact_on_production_survivors`, `cpu_join_finds_69_in_base_10`). The edits are exactly as in the table (applied by a throwaway script, not kept); line numbers are the failing assertions on the branch's `cpu_check.rs`/`cpu_join.rs`.

| mutant | the edit | caught by | verdict |
|---|---|---|---|
| **M1** closure digit seeded (L47's unsound case) | `top()`: seed `c.mask` instead of `c.common` | windows, production survivors (`assert_checked`'s top-digit equality, `cpu_join.rs:1284`) | **caught** |
| **M2** seed position one low | `ends = from − 1` (the `d`/`d+1` digit neither seeded nor converted) | windows, production survivors (`:1284`, `:1289`) | **caught** |
| **M2b** seed position one high | `ends = min(from + 1, s)` (the lowest common digit both seeded and converted) | windows, production survivors (`:1284`) | **caught** |
| **M3** wrong magic constant | `Magic::new`: `m = ⌊2^s/d⌋` instead of `⌈2^s/d⌉` | the quotient test (`bound`, `:558`), the column digits, the seeded verdicts, windows, production survivors | **caught** (5 tests) |
| **M4** early exit wrong, verdict path only | `if !COUNT && $j % 2 == 1 && (sc.repeat \|\| $j == 3)` | nothing: all 8 pass, and the whole `cargo test --release -p nice_common` (196 passed); likewise **M4b** (the same exit at column 5, in the production shape's middle) | **not caught** (M-1) |
| **M5** cube scanned only to the square's end (power swap in the bound) | cube loop `if pos >= ends[0]` | the column digits (`:728`), the seeded verdicts' count (`:819`), windows, production survivors (`:1300`) | **caught** (4 tests) |
| **M6** square/cube swapped in the re-read prefilter digits | `mid_bits`: `n²`'s digits with `p3` | windows, production survivors (`c.low` equality, `:1276`) | **caught** |

M1, M2, M2b and M6 are caught only by the join-level `assert_checked` (the check-level tests cannot see seeds the join builds): that assertion, which compares each recorded survivor's seeds with the true digits, is the load-bearing test of this PR and should stay in CI. No verdict-level test would see M1/M2/M6 in production fields (no hits). A plain swap of `take(0, …)`/`take(1, …)` power indices changes only the count-mode trace, not any verdict, so it is not a defect.

The verdict test proposed under M-1 catches M4 and M4b and passes on the branch (numbers there). With it, every mutant above is caught.

## 3. Soundness of the seeded digit sets

The check's predicate is the old one: `get_is_nice` on `1cce00d` returns `true` exactly when no digit repeats among all of `n²`'s and `n³`'s digits (with `s2 + s3 = b` in a band that is niceness); `get_is_nice_with_known_lsd` is the same scan started from a mask of the low `2·3` digits. The new `Check::nice(p, r0, low, top, ends)` returns `true` exactly when every digit of `n²` at `k2..ends[0]` and of `n³` at `k2..ends[1]` is new against `low | top` and the ones before it. That equals the old predicate if and only if (i) `low` is exactly the set of the `2·k2` digits at positions `0..k2`, and they are distinct; (ii) `top` is exactly the set of the digits at `ends[j]..s_j`, and they are distinct; (iii) the two sets are disjoint. I checked each.

**(a) Positions `0..k` (the bottom's mask, `bmask`).** Unchanged code: `bpre`'s mask (positions `0..f0` of `r0^j`), `extend` (positions `f0..k−1` of `r^j`, `r = r0 + add` without the last digit; `R^j ≡ r^j mod b^(k−1)`) and `list` (position `k − 1` from `t_j = ⌊R^j/b^(k−1)⌋ mod b^(1+mid)`, affine in the last digit `d` because `b^(k−1) ≡ 0 mod b^(1+mid)` at `k ≥ mid + 2`; otherwise recomputed in full). In the key-level case (production: `o − p = 1`) `d` is the key, so the two digits at `k − 1` come from the key; in the partition-last-digit case (windows with `o = p`) from the partition. Both are digits of `n mod b^k`, which `n` shares with `R`. Every step drops a residue whose digits repeat (`DEAD`, `g2 == g3`, `mask & bits`), so `bmask` has `2k` distinct bits. **Tested directly**: `assert_checked` asserts `c.low == bits(d2[..k2]) | bits(d3[..k2])` and `popcount == 2·k2` for every recorded survivor of the 17 windows' sampled partitions (both list kinds, `f0` 0–3, `k2` 3–7) and of two partitions of each production field.

**(b) Positions `k..k2` (the prefilter's four).** `mid_bits` calls `Fx::digits` with exactly the arguments `Fx::pass` used (`info.carries & 0xFFFF` / `>> 16`, `ext.p2[row]` / `p3[row]`, `top.dh`) on the lean shape, and on other shapes the same `mid_values` + `divrem_small` loop that `prefilter_any` → `fresh_digits` runs (with the same `rho`): same function, same inputs, same digits (`cpu_join.rs:982`–1001). They are true digits: with `n = R + D·b^k` and `k ≥ mid`, `⌊n²/b^k⌋ ≡ ⌊R²/b^k⌋ + 2RD` and `⌊n³/b^k⌋ ≡ ⌊R³/b^k⌋ + 3R²D (mod b^mid)` (the `D²b^k`, `3RD²b^k`, `D³b^(2k)` terms vanish), `R mod b^mid = r mod b^mid` because the last digit sits at `k − 1 ≥ mid` (`lean` requires `k > mid`), and `Fx`'s fixed-point read-off is exact (#248's proof: `Δ < 2b⁴ ≤ 2^25 < 2^32`). The prefilter passed, so the four are distinct and miss `bmask` (and the certificate when gated). Tested by the same `c.low` assertion.

**(c) The top's common digits (`Cert::common`, positions `from[j]..s_j`).** In `cert_parts` (`overlap_join.rs:826`): `d = e^j − a^j < b^c0`, so for every `n ∈ [a, e]`, `⌊n^j/b^c0⌋ ∈ {q, q + 1}` with `q = ⌊a^j/b^c0⌋` (monotone, and the gap is below `b^c0`). If `⌊e^j/b^c0⌋ = q` (`!one_more`) every digit from `c0` up is `q`'s, for every `n` of the block, and `from = c0`. If it is `q + 1`, `q` and `q + 1` differ exactly on `q`'s trailing run of `b − 1`s and the digit above it (`d` → `d + 1`); every digit above is common, and `from = c0 + run + 1` (`:867`). So `common` holds true digits of every `n` in `[a, e]`, not just the endpoints, and a repeat among them returns `None` (the top is dropped), so they are distinct (across both powers: one mask). **Closure digits are excluded by construction**: `close_certificate` only ORs bits from `dom` (the `d`/`d+1` interval) into a copy; `Cert { mask: closed, common: mask, from }` keeps the pre-closure `mask`. The `d`/`d+1` position is `from − 1 ≥ k2`, so it is converted as a middle digit. The stepped `TopFdSetup::cert` writes `*first = pos` after the same run skip (absolute position) and is compared field-by-field (`mask`, `common`, `from`) with `cert_parts` on 1.86 M blocks, and `cert_parts` with an independent two-endpoint reference (`cert_reference`, which sets `from` at the first disagreement + 1).

**The flag.** A top keeps `common` only if `gate` (`floor ≥ k2`): `full_floor ≥ k2` for stepped (unclipped) blocks, where `full_floor` is the first full block's floor and the floor is non-decreasing in `P` (`(a + w − 1)^j − a^j` grows with `a`), and the block's own `cert_floor(a, e, k) ≥ k2` for clipped ones. `cert_floor = min_j max(k, ndig(e^j − a^j)) = min_j c0_j ≤ from[j]`, so the seeded positions are `≥ k2`: no overlap with the low positions. The flag is also exactly the condition under which the prefilter tests its four digits against the certificate (`gmask`), and that is what gives (iii): without it the prefilter's digits could equal a common digit undetected. With the flag, `bmask ∩ mask = ∅` (the AND) and the four `∩ mask = ∅` (the prefilter), and `common ⊆ mask`. **Clipped blocks** are certified on the clipped `[a, e]` and only pass residues `r0 ∈ [rlo, rhi)` (`survivor`'s range test), so `n ∈ [a, e]`. **Unflagged tops** get `seed = 0`, `ends = (s2, s3)`: the scan covers every position from `k2` up, which is the old check minus the known low digits. A seed of `c.mask` (the post-closure mask, L47's unsound case) is caught by the CI suite: mutation M1, §2.

**Distinct count.** Nothing in production uses one. `Check::count`, `Count` and `columnar` are `#[cfg(test)]`; count mode is the same `columns`/`long` code with the early exits off and a trace on, used as the tests' oracle (its mask equals `get_num_unique_digits` when the seeds are true digits, which the tests assert). The nice-only join only needs the verdict.

## 4. The column form

- **Limb split** (`limbs`, `cpu_check.rs:361`). `(H, W) = Magic64(b^(e−f0)).divrem(P)` needs `P < 2^63`: `Check::new` takes the column form only if `p_max = fs.phi < 2^63`. `L = W·b^f0 + r0 < b^e < 2^63` (no overflow: `W·b^f0 ≤ b^e − b^f0`). `H = ⌊n/b^e⌋ < b^(l−e) < 2^31` (checked). Limb `i < eh − 1` is `⌊L/b^2i⌋ − ⌊L/b^(2i+2)⌋·b²`, limb `eh − 1` is `⌊L/b^(e−2)⌋ < b²`, limbs `≥ eh` come from `H` by `Magic(b²)`; `eh ≤ NL` and `H < (b²)^(NL−eh)` because `l ≤ 2·NL`. At the production shapes `P < 2^60` (b64's band ends below `64^13 = 2^78`, `P = n/64³`), so the margin is wide; the b64 test window (`P ≥ 2^63`) takes the long division, as intended.
- **`Magic64`.** `s = 64 + ⌊log₂d⌋`, `m = ⌈2^s/d⌉ < 2^64` for `d` not a power of two, `e = m·d − 2^s ∈ (0, d)`, `d < 2^(s−63)`, so `x·e < 2^s` for `x < 2^63`: exact. Powers of two: `m = 2^(64−t)`, `s = 64`, i.e. `x >> t`. The `u128` product is below `2^127`.
- **`Magic`.** Same with 32: `m ≤ 2^32`, `x·m < 2^63` fits `u64`, `x·e < 2^31·2^(s−31) = 2^s`: exact for every `x < 2^31` and every `d < 2^32`. It is the GPU's `join_check::magic(d)` constant exactly (`⌈2^(32+⌊log₂d⌋)/d⌉`, applied there as `mul_hi(x, m) >> ⌊log₂d⌋`); the CPU form folds the shift and adds the power-of-two case (shift), which the GPU's construction rejects. Inputs: columns and `H` below `2^31` (by `b²`), limbs below `b²` (by `b`).
- **Columns.** A column of `n²` (or `n³ = n²·n`) has at most `NL` products of limbs `< b²` plus a carry `< NL·b²` (induction: `carry ≤ (NL(b²−1)² + NL·b² − 1)/b² < NL·b²`), so it is below `NL·(b⁴ + b²) ≤ 8·(2^24 + 2^12) < 2^28`; `Check::new` also checks it per field. The partial sums in `u32` (`x` before doubling, `2x + carry`, then `+ nn[j/2]²`) are each below that bound. The macro's index range `max(0, j−NL+1)..⌈j/2⌉` is exactly the pairs `i < j − i` with both limbs present; the square term is added only for even `j` with `j/2 < NL`. The top carry of `n²` is 0 (`n² < (b²)^(2NL)`, `debug_assert`ed). The cube loop stops at `pos ≥ ends[1]`.
- **Which digits are taken.** A column `j` at digit positions `2j, 2j + 1` is split only if `2j + 2 > k2 && 2j < ends[0]`, and each digit is taken only if `pos ≥ k2` (low one) / `pos + 1 < ends` (high one): exactly `k2..ends`. Same for the cube. Verified against malachite in count mode, position by position, at every base 3–64, every length, every shape and random ends (`the_columns_take_the_digits_of_the_square_and_the_cube`, 274,661 (n, shape) pairs; also each by the long division).
- **Early verdict.** `Scan::take` ORs a sticky `repeat`; the only early returns are `return (false, …)` guarded by `sc.repeat` (after odd columns of `n²`, after `n²`, after odd columns of `n³`). `repeat` set means two true digits are equal (or a true digit equals a true known digit), so "not nice", exactly as the old check's first repeat. A nice `n` never sets it, so the non-count path takes the same digits as count mode and returns `!repeat = true`. Correct by inspection; the gap is that no test exercises that `true` beyond one limb (finding M-1).
- **Code generation.** I disassembled `full_check` in the release test binary: no `div` on the lean path (the only `div`s and the two `u128` division calls are in the non-lean `mid_values` branch, behind the `lean` test, unused in production), and no 96-byte fill of `Scan::trace` (the array is dead in non-count mode and the optimiser drops it). `full_check` is 28.9 KB with all eight `NL` instantiations inlined; one is hot per field.

## 5. Claims check (body vs `L56/PR-RESULTS.md` and `L56/raw/`)

| claim (PR-BODY.md) | checked against | verdict |
|---|---|---|
| A/B medians and per-round ratios, all 12 rows (b60 1e16 ×1.117 / ×1.139, b62 1e17 s0 ×1.136 / ×1.109, b58 ×1.168 / ×1.167, whole 1e14 ×1.069–1.119) | `raw/ab-summary.txt`, `ab-summary-whole1t.txt`, `ab-runs.txt` (recomputed b60 1 t: 1718/1537 = 1.118, 1743/1560 = 1.117, 1759/1594 = 1.104; b62 4 t round 1: 1802/1683 = 1.071) | ✓ |
| "every round is ×1.10 or more but one 4-thread b62 round (×1.071 …, 0.6 of a core)" | `ab-runs.txt` r1 b62e17s0_4t pr: `others: 2.1.280(claude 63.6%)` | ✓ |
| Counts identical on both sides (136,900,315 / 8,692,368 etc.) | `ab-runs.txt`; my `NICE_TEST_CPU_CHECK_REF=4` reproduces the checked counts exactly (8,692,368; 8,194,223; 2,247,150; 93,515; 90,465; 334,391) | ✓ |
| NiceMark score 1091.0 → 1259.6, ×1.155, per round 1.170/1.139/1.168/1.121; scenarios | `raw/nicemark-summary.txt` (medians of 4 recomputed: (1090.0 + 1092.0)/2, (1255.7 + 1263.6)/2) | ✓ |
| "The base's score (1091.0) is the two-pass scan PR's own measurement" | L52's PR side (1090.2, 1099.7, 1091.8, 1068.2) → 1091.0 | ✓ (coincidence, but true) |
| perf: check 14.8 % → 4.9 % (b60), 16.1 % → 4.7 % (b62); first pass 14–19 % | `raw/perf-runs.txt` (14.76/4.88, 16.08/4.70; pass1 18.65, 14.29) | ✓ |
| Per check 119 → 36 ns, 133 → 34 ns in place | share × ms/partition (`perfstat-summary.txt`: 1746/1601, 1695/1481) ÷ 2.17 M / 2.05 M checks | ✓ (my arithmetic: 118.6, 36.0, 133.0, 34.0) |
| "14.8 % and 16.1 % cut ×3.3 and ×3.9 give ×1.12 and ×1.14" | 1/(0.852 + 0.148/3.3) = 1.115, 1/(0.839 + 0.161/3.9) = 1.136 | ✓ arithmetic; note it is not an independent prediction (the ×3.3/×3.9 come from the PR's own perf share) |
| Counters: cycles −8.6 % / −12.7 %, IPC 2.85 → 3.12 / 2.79 → 3.17, instructions flat | `raw/perfstat-summary.txt` | ✓ |
| Recorded-survivor bench table (125.5 / 131.6 → 28.5 / 29.3 ns, ×4.40 / ×4.49; other rows) | `raw/check-bench.txt` (medians of the three reps) | ✓ |
| 9.6–9.8 → 1.8 digits before the verdict; 96 % in the first four middle digits; 0.06–0.07 % reach n³; 16.0 / 17.8 top digits | `raw/check-bench.txt` (9.62/9.77, 1.83/1.80, 96.20/96.56 %, 0.072/0.058 %, 16.03/17.77) | ✓ |
| "×1.5–1.8 with the same seeds" (column form vs long division) | 50.3/28.5 = 1.76, 60.5/38.2 = 1.58, 50.8/29.3 = 1.73, 61.1/41.0 = 1.49 | ✓ numbers; wording (L-2: it is the chunked V3 division) |
| In place: over no-top ×1.010 / ×1.023; over V3 ×1.051 / ×1.028 | `raw/ab-variants-summary.txt` | ✓ (within the variants' spread at b60; N-4) |
| "b58 …, whose partitions check a larger share of their pairs" | `ab-summary.txt` counts: 5.64 % vs 6.35 % / 5.95 % | ✗ (L-1) |
| "`e` = 10 at bases 39–64", "four more independent quotients" | `Check::new`; b40 has `l = 8`, `e = 8` | ✗ minor (L-2) |
| "carries nothing out (`n² < b^(2·nl)`)" | `n² < b^(4·nl)` | ✗ minor (L-2) |
| Column bound "at most 1.2·10^8 in production" | b64: `nl = 7`, `7·(64⁴ + 64²) = 117,469,184` | ✓ |
| Tests: 196 + 22 passed, 8 ignored; 274,661 pairs; 298,153 decisions (12 nice), 81 near-nice; production survivors per field; opt-in 19.65 M; b42 whole field 417,789,835 / 16,879,877, no hits; JOIN_REF=3 | `raw/unit-tests*.txt`, and my own runs (§7; `nice_common`'s 196, not `nice_client`'s 22): identical counts | ✓ |
| "No knobs, no new public API"; `Base::cert` keeps its signature and result | diff: `cert_parts` and `Cert` are `pub(crate)`; `cert` is `cert_parts` mapped to its `mask` | ✓ |
| "17 of the 18 take the column form …; the b64 window, whose `P` exceeds 2^63, takes the long division" | b64 window: `n ≈ 5.2·10^22`, `f0 = 2`, `P ≈ 1.27·10^19 > 2^63` | ✓ |
| "One `Magic` … the GPU's base-b² check uses the same multiply-high construction for the same divisors" | `e28b79f:common/src/join_check.rs:35`: `m = ⌈2^(32+⌊log₂d⌋)/d⌉`, `mul_hi(x, m) >> ⌊log₂d⌋` | ✓ (same constant; GPU rejects powers of two, CPU shifts) |

**CHANGELOG** (`CHANGELOG.md:15`): one sentence, user-facing, no numbers, `#NNN` placeholder (as the two-pass scan's line above it). Fine; fill the number when opening. One wording thought: "two at a time and without long division" is accurate (two digits per base-b² limb).

**Commit message** (`raw/commit-msg.txt`): accurate; it says "four more give the low limbs" (three at b40, L-2).

## 6. `Magic` and `join_check`: unify now or later?

Later. The constants are the same (`m = ⌈2^(32+⌊log₂d⌋)/d⌉`); the forms differ only in packaging (GPU: `(m: u32, s)` for a `mul_hi` and a shift, powers of two rejected, `const fn`; CPU: `m: u64`, total shift `32 + s`, powers of two by shift; plus `Magic64`, which the GPU replaces by an exact division with `inverse_mod_2_64`). `join_check` lives on the GPU stack (fork `pr/check-d`, `e28b79f`, on the FD round-2 commits), which is not under this branch, so unifying now would mean moving a GPU module into a CPU PR or stacking the two series. Both carry the same proof, the same block-worst CI test and an exhaustive opt-in (8 min on 4 threads for the CPU's) under different variables (`NICE_TEST_CPU_CHECK_EXHAUSTIVE`, `NICE_TEST_CHECK_EXHAUSTIVE`). Whichever PR merges second should move one `magic` (keep `join_check::magic` as the `const fn` source of the constant, and build `cpu_check::Magic` from it) and keep one exhaustive test. The body's "Not in this PR" already says this; I would add that the second PR does it.

## 7. What I ran (on `5c218b7`, release, `nice -n 19`, worktree `.worktrees/l56-review`)

| run | result |
|---|---|
| `cargo test --release -p nice_common` | **196 passed, 0 failed, 8 ignored** (14.8 s), as reported |
| the new and touched tests with `--nocapture` | ok: 274,661 (n, shape) pairs through the column form; 298,153 decisions (12 nice), 81 near-nice; 1,876 setups / 1,860,723 blocks for the stepped certificates; production survivors b42 18,491, b50 650,120, b57 163,500, b60 46,474, b62 45,090, b64 164,685, all with their top's digits: identical to `raw/unit-tests-new.txt` |
| `NICE_TEST_CPU_CHECK_REF=4 … the_full_check_is_exact_on_production_shapes` | ok, 130 s: b60 1e16 8,692,368; b62 1e17 s0 8,194,223; b58 1e15 2,247,150; b60 1e14 93,515; b62 1e14 90,465; b64 1e14 334,391 checked survivors, all gated, all exact |
| `NICE_TEST_CPU_JOIN_REF=3 … cpu_join_matches_the_reference_on_production_fields` | ok, 31.7 s |
| `NICE_TEST_JOIN_FULL_FIELD=1 … cpu_join_matches_the_reference_on_a_whole_field` (whole b42) | ok: 1764 partitions, 417,789,835 join survivors, 16,879,877 checked, hits []; reference 86 s, join 10.6 s, stride 116.4 s on 4 threads |
| `cargo fmt --all --check` | clean |
| `cargo clippy -p "*" --all-targets -- -D warnings` (default features, rustc 1.99.1) | clean (exit 0, no warnings; 1 m 25 s) |
| `objdump` of `CpuJoin::full_check` in the release test binary | 28.9 KB; no `div` and no `Scan::trace` fill on the lean path |
| 8 mutants (§2), M4/M4b also on the whole `nice_common` suite, and the proposed verdict test (M-1) clean and against M4/M4b | §2, M-1 |

Not run: the exhaustive quotient test (8 min on 4 threads; the closed-form proof covers it, and the block-worst CI test passed), `nice_client`'s tests (unchanged by the diff), any timing (I did not re-measure; I recomputed the reported numbers from the raw logs, §5).

## 8. Cleanup

Worktree `.worktrees/l56-review` and its `target/` removed (`git worktree remove`), `/tmp/l56rev` and the `/tmp/l56rev-*.log` files removed after this file was written. The branch, the fork, the main checkout and GitHub were not touched.
