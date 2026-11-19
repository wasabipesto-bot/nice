# Independent review of PR 1 (`pr/midout-coordinate`, cf27bc89) and PR 2 (`pr/midout-cpu-reference`, 06d55495), 2026-11-19

Reviewer worked alone, cold, on the two branch heads fetched from the fork. Nothing on either branch was changed;
all experiments were in scratch clones `/root/rv/c1..c4` with their own target directories on the handed box
(Vast 61441981). Nothing contacted the production API (the box's `/etc/hosts` blocks it, and no client was run).

---

## PR 1 — field coordinate: **MERGE WITH FIXES (description only; the code needs no change)**

### What I ran myself (box, clone `c1` at cf27bc89, target `/root/rv/t` then `/root/rv/tr`)

- `cargo fmt --all --check` rc 0; `cargo clippy -p "*" --all-targets -- -D warnings` rc 0;
  `cargo clippy -p "*" --all-targets --features nice_client/gpu,nice_client/cubecl-spirv -- -D warnings` rc 0
  (= `just lint`).
- CI's test step `cargo test --locked --release --no-fail-fast`: rc 0, nice_common lib 213 passed / 9 ignored
  (133 s, mostly pre-existing tests), client 24 passed.
- Not run: `cargo build -p "*"` (the box has no libpq: `nice_jobs` fails to link with `-lpq` on main too, an
  environment gap, not the branch); `nice_common --features gpu --lib` (disk); the debug timings of PR 1 alone.

### Checked and found true

- Bijection: `v − start = key·H·b^k0 + (h−h0)·b^k0 + low` with `key < b^(k1−k0)`, `h−h0 < H`, `low < b^k0`
  has maximum `H·b^k1 − 1`, so `v_of_n` is one-to-one into `[start, start + H·b^k1)`; `n_of_v` inverts it
  and returns `None` exactly off the range. Exhaustive on nine small bases in the test; algebraic at base 64.
- Quantum: writing `key = t·b^(q0−k0) + r`, the offset is `t·(H·b^q0) + (rest < H·b^q0)`, so
  `(v − start) div quantum = t` = digits `[q0, k1)`. "A field is the n with digits 5–7 in `[t0, t1)`" is true.
- Coverage: fields of whole quanta tile `[start, v_end)`; `n_count` clips only the first and last `h`, and its
  sums equal the range (tested exhaustively on small bases, all 274,625 quanta of base 65, all of base 64).
- Numbers: slice `2^45` (76 bits − 30 fixed − the fixed top bit), quantum `2^57`, `64^3 = 262,144` fields,
  4,096 slices per field, base 65 `65^3 = 274,625` quanta: all correct.
- Overflow: `with_digits` refuses a coordinate whose `start + H·b^k1` overflows; every intermediate in
  `v_of_n`, `n_of_v`, `n_count` is bounded by that sum; base 64 tops out at `2^76`. Margin is ample.
- `b64_field_is_4096_whole_slices` builds `n` from the slice digits by bit operations, independently of
  `Coord`: not circular.
- No leftover of the older digit choice (digits 6–8 / `(4, 9, 6)`) in the code (grep).
- No production behaviour changes: the only line outside `midout/` is `pub mod midout;` in `common/src/lib.rs`.
  No allowances, no dead-code suppression.

### Findings

**Must (description, before opening)**
1. PR1-BODY "Why": *"fields could later be re-cut along other digits without searching anything again"* — not
   true as written: a finished field fixes digits 5–7, and a field cut along other digits is not a union of
   finished fields, so a re-cut would leave partly searched fields. Delete it, or say precisely what is meant
   (that the *slicing inside* a field is free).

**Should**
2. PR1-BODY "Why": *"Any search that splits n into a top part and a bottom part (today's overlap join
   included) ... can search a field by filtering on those three digits, with its work shrinking in
   proportion"* — the first half is true (and is in `coord.rs:60–63`), "work shrinking in proportion" for the
   overlap join is neither shown nor tested here. Drop the clause.
3. PR1-BODY "Digits 5–7 rather than 6–8 ... (about 3 % per field on a GPU, in a later pull request)" — the
   maintainer has never seen a 6–8 definition; it reads as development history, and the 3 % is a later PR's
   performance claim. Either drop the paragraph or reword as "why not digits 6–8" without the number.
4. `coord.rs:79–92`: every field of `Coord` is `pub`, so `Coord { .. }` can be built without the checks of
   `with_digits` (order of positions, overflow). A maintainer will ask; private fields with getters, or a
   sentence saying the fields are read-only by convention.

**Note**
5. PR1-BODY test list: `b64_field_is_4096_whole_slices` "whatever the other digits" — it samples one `n` per
   slice with 64 random fills; say "with random other digits" (the algebra makes it true anyway).
6. `coord.rs:15–17` doc wrap is uneven ("(`hn`" / "in the code), ..."); cosmetic.
7. `coord.rs:55–68` ("Slices") describes the join's slice with base-64 digits and a performance rationale
   (shared preparation) before any code defines a slice; acceptable as context, but it is the one place a
   maintainer may ask "where is this used?" (answer: PR 2's `Shape`).
8. `Coord::is_known` is used only by tests in this PR (public, so no warning).
9. PR1-BODY: "and so do the whole workspace suite" → "so does".

---

## PR 2 — CPU reference: **MERGE WITH FIXES (add three cheap independent checks to the test; correct the description)**

The reference itself I found correct: it agrees with production's own CPU search on every whole base I tried,
and every survivor of two real base-64 slices passes the brute-force predicate. The gaps are in what its tests
can see: five mutants that change the *definition* pass the author's suite (M01, M03, M04, M10b, M22), and one
breaks the arithmetic base 64 alone uses (M18). Each is caught by a short independent test (below), which I
wrote and ran in a scratch clone.

### What I ran myself (box)

- Clone `c2` at 06d55495: `just lint`'s three commands rc 0 / 0 / 0. CI's `cargo test --locked --release
  --no-fail-fast` rc 0: nice_common lib 217 passed / 9 ignored, client 24 passed. The midout tests alone,
  release: 10 passed in **13.4 s** (57 s wall with the build). Debug (`cargo test -p nice_common --lib midout`,
  the `just test` form): **67.2 s**, and libtest prints "has been running for over 60 seconds"; with the
  base-25 case removed (scratch) the same test takes **13.7 s** in debug, so base 25 is ~54 s of it.
- Clone `c4` (06d55495 + a scratch `midout/review.rs`, never pushed; copy at
  `/root/rv/review_full.rs` on the box):
  - **(a) against production, whole bases:** `search_field` over the whole range vs production's
    `process_range_niceonly` (stride table `k = 1`, as `process_niceonly` builds it) on bases 10, 12, 13, 14,
    17, 18, 19, 20, 22, 23, 24, 25, 27, 28, 29: the nice numbers are identical (base 10: exactly `[69]`; none
    elsewhere). Where production's search panics (b19, b23, b27: `stride_filter.rs:165`, index into an empty
    residue list — a production defect for bases with no valid residues, out of scope here) I compared with a
    scan by production's `get_num_unique_digits`: identical.
  - `arith::roots(b)` == production's `get_residue_filter(b)` for every base 3–128; `unique_digits(n, b).0` ==
    production's `get_num_unique_digits` for every `n` of bases 10–22 (with ranges).
  - `top_cert_split` == a brute-force definition (the common top-down prefix of `n²`, `n³` over every `n` of the
    interval, at positions `>= k`, and the part `>= k + 2`) on 7 base/shape pairs including `f0 = 0`
    (b10 (0,2), b13 (0,3), b19 (0,4)), up to 20,000 intervals each: identical.
  - `prefilter` at **base 64**, shape `(4, 10)` (`b^12 = 2^72`, the large-modulus branch of `mm`, which no test
    base reaches) vs the full digits of `n²`, `n³` on 200,000 random `n` and random `mhi`: identical (714 pass).
  - **Two whole base-64 slices** (`t` = 77,777 and 3, the 1,235th slice each) through `slice_join::<u64>`:
    27 s each in release; 11,790,459 and 11,719,747 survivors, every one inside its slice, none twice, every
    one passing `q_shape`, and its prefilter verdict equal to `q_checked`'s (339,089 and 336,685 checked).
    This exercises the real shape, 64-bit masks with bit 63 and `n > 2^75` arithmetic, none of which the PR's
    tests touch.

### Mutants (one line each, scratch clone `c3`, `cargo test --release -p nice_common --lib midout::`)

| id | change (cpu.rs unless noted) | author's tests | reviewer's checks |
|---|---|---|---|
| M01 | top certificate one digit short (`j > kpos + 1`, :187) | **survives** | killed (top cert vs brute, b10) |
| M02 | top certificate one digit long (`j >= kpos − 1`, :187) | killed | — |
| M03 | `mhi` drops position k+2 (`j > kmid`, :197) | **survives** | killed (top cert vs brute) |
| M04 | `mhi` takes position k+1 (`j + 1 >= kmid`, :197): **rejects nice numbers** whenever the certificate reaches k+1 | **survives** | killed (top cert vs brute) |
| M05 | bottoms keep `e2 == e3` (:319) | killed | — |
| M06 | child kept with `e2 == e3` (:423) | killed | — |
| M07 | prefilter checks `mhi` only at k+1 (:236) | killed | — |
| M08 | prefilter reads one digit, not two (:232) | killed | — |
| M09 | prefilter exemption threshold `b^((k+2)/2)` in `prefilter` only (:222) | killed | — |
| M10a | `roots` gains class 1 (arith.rs) | killed (`known_nice_and_roots`, base 64) | — |
| M10b | `roots` gains class 1 below base 64 only (arith.rs) | **survives** | killed (roots vs production) |
| M11 | class pairing off by one (:562) | killed | — |
| M12 | top interval runs to `end`, not `end − 1` (:355) | killed | — |
| M13 | top interval not clipped at `start` (:354) | killed | — |
| M14 | survivor at the top's last `n` dropped (:615) | killed | — |
| M15 | `q_shape` interval runs to `end` (:645) | killed | — |
| M16 | last lead dropped (:352) | killed | — |
| M17 | chunk key order reversed (:533) | **survives** | survives (work counts only; expected) |
| M18 | `mm` large-modulus branch shifted (`[64, 32, 1]`, :149): wrong prefilter at base 64 | **survives** | killed (prefilter at base 64) |
| M19 | nice-ness accepts `b − 1` distinct digits (arith.rs) | killed | — |
| M20 | prefilter skips the duplicate test (:236) | killed | — |
| M21 | exemption threshold changed in both `prefilter` and `prefilter_direct` (:222, :772) | survives | survives (equivalent in practice: `n²` still long enough) |
| M22 | top certificate two digits short (:187) | **survives** | killed (top cert vs brute) |
| M23 | bottoms' forced digits off by one (:303) | killed | — |
| M24 | prefilter ignores `n³` (:230) | killed | — |
| M25 | first lead dropped (:349) | killed | — |
| M26 | chunk common-mask skip disabled (:598) | **survives** | survives (only `kept` changes; expected) |

The author's fix (prefilter checked against `prefilter_direct`) works: M07, M08, M09, M20, M24 all die on it.
The next gap is the one the description calls safe: `top_cert_split` (M01, M03, M04, M22), plus `roots` below
base 64 (M10b) and `mm`'s large branch (M18). M04 is a real definitional error (it silently drops nice numbers)
that passes because the only base with a nice number, 10, has the prefilter exempt (`n < b^2`).

### Findings

**Must (before opening)**
1. **Test the shared definitions independently** (`cpu.rs` tests). Three short additions, all cheap
   (a second or two together in release in my scratch version): (i) `top_cert_split` against a brute-force prefix over
   every `n` of the interval, on shapes with `f0 = 0` (the only ones where the certificate reaches positions
   k..k+2 at these bases) — kills M01/M03/M04/M22; (ii) `roots(b)` against `residue_filter::get_residue_filter`
   for bases 3–128 — kills M10b; (iii) `prefilter` at base 64 against full digits (random `n`) — kills M18 and
   is the only test of the arithmetic base 64 uses. Comparing with production code in a test is not "reusing
   the code it checks"; `arith.rs:6–8` can keep its point.
2. **PR2-BODY**: *"The one piece the reference and its brute-force predicate share is `top_cert_split`"* is not
   true: they also share `roots` (the class test on both sides), `unique_digits` (the search's full check and
   the brute nice scan), the interval clipping and the prefilter exemption (duplicated text in `q_shape`,
   `q_checked` and `prefilter_direct`), and `prefilter_direct` takes `mhi` from `top_cert_split`. Correct it
   (or make it true with finding 1), and list the surviving mutants honestly next to the three that die.
3. PR2-BODY placeholders `#NNN` (twice).

**Should**
4. Test time: `whole_small_bases_vs_brute_force` is one `#[test]` with 17 cases run in sequence (13 s release,
   67 s debug with the 60-second warning; 14 s debug without base 25). The debug figure is too long for this
   repository's `just test`. Split it into one test per base (a macro or a helper taking the case) so the harness runs
   them in parallel and a failure names the base; this repository's habit is fast plain `cargo test` with slow
   hardware tests `#[ignore]`d (69 ignored in `common`), not long single tests. Also `cpu.rs:841–844` re-runs
   `slice_join` for every slice after `search_field` already did, only to collect the survivors: a second full join pass
   per base; let a test helper return them instead. Simplest acceptable fix: keep base 25 but run it only in
   release (`if cfg!(debug_assertions) { skip }`), or split per base so it runs beside the others.
5. `cpu.rs:36–37`, `:677–681` and PR2-BODY ("They mean what production's counters mean"): say "the same kind of
   count as production's `survivors` / `checked`, for this join's shape"; the numbers are not comparable with
   the overlap join's, and "what production's `survivors` counts for the overlap join, for this join's shape"
   is hard to parse.
6. `Counts` (`cpu.rs:450–472`): `tops_tested`, `tops`, `parents`, `children`, `chunks`, `pairs`, `flat`, `kept`,
   `words` have no doc comments and no test (M17, M26 survive by design). The module doc says a GPU kernel's
   chunk and word counts will be compared with these; say here that they are untested until then, and document
   each field in one line ("flat" and "words" will be asked about).
7. Two of the eleven bases are vacuous for survivors: base 12 (shape (1,3)) and base 19 (shape (1,3)) have
   zero survivors over the whole range (my run), so they test only "nothing found". Fine to keep, but the
   description's "eleven bases" overstates the coverage; and the prefilter is never applied at bases 10, 12, 13,
   14 (whole range below `b^ceil((k+2)/2)`, `cpu.rs:222`).

**Note**
8. No test of this PR runs base 64 (or anything above 25): the real shape, bit 63 of a `u64` mask and
   `n > 2^64` arithmetic are covered only by my scratch run above. A single base-64 slice is 27 s in release —
   too slow for the suite; finding 1 (iii) covers the arithmetic cheaply; the rest waits for the GPU PRs.
9. `Base::new` (`cpu.rs:126–130`) saturates `pw` silently past `u128`; indices used stay far below that for
   bases ≤ 128, but a `checked_mul` with a panic would make misuse loud.
10. `key_digits` (`cpu.rs:441`) orders by `f64` products of counts: exact while products < 2^53 (true at base 64:
    ~1e6 × 2e5); an integer product (`u128`) would be exact by construction and avoid `partial_cmp().unwrap()`.
11. Unused public items: `Base::l`, `Mask::count_ones`.
12. Readability: "shape `(f0, k)`", "slice", "pip", "unit", "parent/child", "survivor" are each defined where
    first used (`cpu.rs:12–22`); "quantum" in `coord.rs:41–42`; "padded form" does not occur. Good.
13. PR2-BODY "Survivors go through production's middle-digit prefilter (the same rule as `cpu_join`'s)": the
    same rule (digits `k`, `k+1` distinct, new, and off the certificate above `k+2`; `cpu_join.rs:1096–1103`),
    computed independently — say "the same rule", not "production's prefilter".
14. Attribution: both bodies end with the "Generated with Claude Code" line and the commits carry
    `Co-Authored-By: Claude …` trailers, as merged upstream PRs do (e.g. #270). Otherwise no forbidden
    reference (no research program, notes, scratchpad path, agent or host names) in either body or the diff.
15. Commit `294abe9b` (the merge of PR 1's doc fix into PR 2) has git's default message; harmless if the PR is
    squash-merged, visible otherwise.

---

## Corrections to the descriptions (summary)

PR 1: delete "fields could later be re-cut ... without searching anything again"; drop "with its work shrinking
in proportion"; reword or drop the "Digits 5–7 rather than 6–8 ... about 3 %" paragraph; "whatever the other
digits" → "with random other digits"; "so do" → "so does".

PR 2: fix "the one piece ... share is `top_cert_split`" (finding 2); add the mutants that survive (or the tests
that now kill them) to the "I broke the reference on purpose" paragraph; fill `#NNN`; "production's prefilter" →
"the same rule as production's prefilter"; counters are "the same kind of count", not comparable numbers; note
that base 12 and base 19 contribute no survivors.
