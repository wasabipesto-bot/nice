# The middle-out join, step 7P: pull requests 1 and 2 cut from the cleaned tree (2026-11-19, 14:53–16:10 UTC)

Brief `G2/BUILD-BRIEF-7P.md`; specification `G2/PR-PLAN.md` §PR 1, §PR 2. Source: `dev/mo-clean` at `5a048669`.
Box: Vast 61441981 (16 threads visible, CPU quota ~5, Rust 1.100.0), production hosts mapped to 127.0.0.1 and ::1
(proof per run in `build7p/raw/*/hosts_proof.txt`; nothing in these branches touches the network). Box scripts
`build7p/box/`, raw logs `build7p/raw/`, both branches as a bundle `build7p/pr12.bundle`.

## 1. The branches

| | `pr/midout-coordinate` | `pr/midout-cpu-reference` |
|---|---|---|
| base | `origin/main` `974d7194` | `pr/midout-coordinate` |
| head | `cf27bc89` (2 commits) | `06d55495` (2 commits + 1 merge of PR 1's doc fix) |
| on the fork | `fork/pr/midout-coordinate` | `fork/pr/midout-cpu-reference` |
| files | `common/src/lib.rs` (+1 `mod` line), `midout/mod.rs` (17), `midout/coord.rs` (502) | `midout/cpu.rs` (+941), `arith.rs` (+138), `mask.rs` (+65), `mod.rs` (+13 −3) |
| lines | 520 insertions: ~290 code and docs, ~213 tests | 1,157 insertions: cpu 758 code and docs + 183 tests, arith 127 + 11, mask 65 |
| new tests | 6 (all `coord`) | 4 (`cpu` 3, `arith` 1) |
| their time (box, release / debug) | 0.18 s / 0.57 s | 10 midout tests 13.2–13.4 s / 66–67 s (nearly all `whole_small_bases_vs_brute_force`; most of that base 25: its search 4.4 s in release plus its brute-force scans) |
| `just lint` (its three commands) | clean | clean |
| CI's `cargo test --locked --release --no-fail-fast` | pass (nice_common lib 213 pass, 9 ignored) | pass (217 pass, 9 ignored) |
| CI's `nice_common --features gpu --lib` | pass (267 pass, 66 ignored) | pass (271 pass, 66 ignored) |
| raw | `raw/p1_lint`, `raw/p1_suite` | `raw/p2_lint`, `raw/p2_suite`, `raw/mut` |

No feature, no dependency, no `Cargo.toml` change, no ignored test, no dead-code allowance; production code paths
unchanged (one `pub mod midout;` in `lib.rs`). No changelog line: the convention lists user-facing changes only.
The `just` on the box (apt 1.21) cannot parse the justfile, so the recipe's three commands were run as written.

## 2. What I changed against the cleaned tree, and why (carry back to `dev/mo-clean` where it applies)

Diffs: `raw/pr1_vs_clean.diff`, `raw/pr2_vs_clean.diff`.

**`coord.rs` (PR 1)**
- Only `(4, 8, 5)`: `coord_digits_known` (a list per base) replaced by `coord_digits(b) -> Option<…>`, base 64 only;
  `is_known` now compares with it. Base 65 and 68–70 have no coordinate in this PR (the wide path's PRs add them
  back). **Carry back:** the route, client and bench call `coord_digits_known`; they need `coord_digits` / `is_known`.
- Module docs rewritten for `(4, 8, 5)`: the cleaned tree's base-64 paragraph still gave the `(4, 9, 6)` formula
  (bits 24–53 to 45–74, `H = 2^21`) as *the* base-64 coordinate, wrong for the default. Now: the `(4, 8, 5)` bit
  formula, `H = 2^27`; a new "Slices" section (a slice is `2^45` numbers, a field is 4,096 whole slices, what that
  leaves free, what digits 4 and 8 free buys); "no server stores it, nothing proposes a field row, claim or API".
  `n_count`'s doc no longer says "its `range_size`" (a server term).
- Tests: the two `(4, 9, 6)` tests dropped, `known_coordinates` replaced by `only_base_64_has_a_coordinate`
  (also refuses out-of-order digit positions); `b65_padded` keeps only `(4, 8, 5)` and asserts the padding is
  non-zero; new `b64_field_is_4096_whole_slices` (the slices statement, without the join's `Shape`, which is PR 2's).
  `pow` got a `# Panics` section (clippy pedantic; the cleaned tree had module-wide allowances).
- `mod.rs`: rewritten per PR (what the join is in five lines, what is here, "nothing uses this yet"); the module-wide
  clippy allowance list is gone entirely.

**`cpu.rs`, `arith.rs`, `mask.rs` (PR 2)**
- **A gap in the cleaned tree's test, fixed:** `whole_small_bases_vs_brute_force` counted `checked` with
  `q_checked`, which calls the reference's own `prefilter`, so a wrong prefilter rule passed it. Proved by a one-line
  fault on the pre-fix head `294abe9b` (`raw/mut_prefix/`: the test passes with it, rc 0). New test helper `prefilter_direct`
  recomputes the prefilter from the full digits of `n²`, `n³` (U384) for every survivor; the same fault now fails
  (`b17 n 11847`). Commit `06d55495`. **Carry back.** Two more one-line faults (a child kept with equal new
  digits; one residue class skipped) fail the test before and after (`raw/mut/`).
- Removed: `Shape::label` (telemetry, PR 9's), the box-only `b64_slice_vs_staged` (staged data, `midout-box-tests`
  feature; PR-PLAN's cut list), `Mask::low64` (only the device path uses it: PR 3/4 add it back).
- `shapes_that_do_not_fit_are_refused` rewritten for `(4, 8, 5)` (was `(4, 9, 6)`); `coordinate_485_is_whole_slices`
  renamed `fields_are_whole_slices_of_the_shape`.
- Lints: instead of `mod.rs`'s ten module-wide clippy allowances, `#[must_use]` on 8 functions, `# Panics` sections
  on 8, `sl.fill(0)`, a `type Case` in the test, `#[allow(clippy::too_many_lines)]` on `slice_join` alone and
  `#![allow(clippy::many_single_char_names)]` on `cpu.rs` alone (formula names), each with a reason.
  **Carry back** or expect later PRs to bring their own allowances per file.
- Docs: device/audit/telemetry wording replaced; a "What a field search returns" section defines `survivors` and
  `checked` and their relation to production's counters.

**Process note:** the merge commit `294abe9b` (PR 1's doc fix into PR 2) has git's default message without the
trailer; every other commit has it. Nothing was amended, rebased or forced.

## 3. What a reviewer should look at hardest

- PR 1: the contract in `coord.rs`'s "What a field fixes" (what a search may rely on: the set of `n` with digits
  5–7 in a range, nothing about order inside a quantum) and that nothing claims it is stored anywhere.
- PR 2: `top_cert_split`, the one definition the reference and its brute-force predicate share (soundness: `n²`,
  `n³` monotone, so digits equal at both ends are equal throughout; and a power whose length changes gives no
  certificate). Then `prefilter` / `prefilter_direct`, and `q_shape` (whose bottom side, `bot_cert_direct`, is
  independent of `bottoms`). The nice-number comparison has teeth only where a base has nice numbers (69 at
  base 10); elsewhere the survivor and `checked` sets carry the test.
- Test time: 13 s release in CI's form is fine; 67 s in a debug `just test` is long for "seconds". Base 25 is most
  of it and is the only `k = 5` case; I kept PR-PLAN's eleven bases and say so in the description.

## 4. What in `PR-PLAN.md` turned out wrong or loose

- PR 1 "330 + 200 lines": 290 + 213, fine. PR 2 "900 + 190": 950 + 194, fine.
- PR 1 cannot test "a field is whole slices" with the join's `Shape` (that lives in `cpu.rs`, PR 2); a digit-only
  test in `coord.rs` does it instead.
- PR-PLAN says the brute-force test is "the only place a mistake in the definition can be seen": true for the
  survivors, but as cut it could not see a wrong prefilter (`checked` was compared with the same function). Fixed.
- The "padded form kept for its tests" needs no API surface: `with_digits` serves the tests; no padded base is
  "known".

## 5. Not done

No pull request opened (as briefed). No GPU, Metal or lavapipe run (no device code here). Tier timings on a 4-core
GitHub runner not measured.
