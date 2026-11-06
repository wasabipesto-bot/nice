# L42 PR results: FD top certificates in the CPU join (2026-11-06; ivory, CPU only)

**Branch:** `pr/cpu-join-fd-tops` on the fork (`wasabipesto-bot/nice`), one commit on upstream main `6f060a9`:
HEAD_SHA. Not opened as a PR. Body: `L42/PR-BODY.md`. Raw logs: `L42/raw/pr/`.

**Worktree:** `.worktrees/pr-cpu-join-fd` (kept; `target/` and `target-ab/` removed at the end).

## Summary

SUMMARY

## What the commit does

- New `common/src/cpu_top_fd.rs` (587 lines of code and docs + a 123-line test module): `TopFdSetup` (per
  `CpuJoin`, `None` when the field's arrays would not fit or b ≤ 6) and `TopFd` (per `tops()` call, one key).
  - Step: five packed digit-array adds (`detailed_fd`'s biased add with a runtime bias), each over its addend's words
    at the slice's last prefix plus the carry word, rare ripple out of line: **14 word-adds a step at b60/b62** (15 at
    b64), against the prototype's 21; plus three `W4` adds.
  - Walk: step while P is at most `MAX_STEPS` = 4 steps (4h) above the last stepped prefix of the same call; anything
    else (first prefix of a key, gap > 4h, a walk that does not land on P) seeds.
  - Seed: P, P², P³ converted by `Div64` (b^8, b^4) + `SmallDiv` per digit; DS, DC, DDC built from P's and P²'s
    digits by shifts and adds (two long conversions instead of the prototype's five); d2, d3, Δ3 by `W4` products;
    `pc`, `dm` by the old u128 expressions.
  - Certificate: `Base::cert`'s scan on the stepped digits; c0 from a bit-length table + one compare; the carry test
    screened in f64 (margin 2^-20, error < 1e-11), exact `W4` fallback inside the margin or for k < 2.
  - Kept tops: `pc` and `dm` step by one with P (h = b^o ≡ 1 mod b − 1; `dm`'s divisor b^(k−f0) is h), no u128
    division except at seeds.
- `CpuJoin::tops`: unclipped blocks through the FD state; clipped blocks (P = plo, phi) and non-FD fields through
  `Base::cert`, state untouched. No env knobs, no prototype code.
- `overlap_join.rs`: `poww`, `ndig_w`, `digit_range_mask`, `close_certificate` made `pub(crate)`; `cpu_join.rs`'s
  `SmallDiv` `pub(crate)`; `Top` derives `Debug, PartialEq, Eq` (tests).
- Interpretation note: the brief's "seed by `Base::cert`'s division" is implemented as the seed converting P, P², P³
  with the base's `Div64` reciprocal division (no hardware `div`); the seed slot is then certified from the fresh
  state, not by `Base::cert` (cheaper, and the test proves it equal).

## Tests

TESTS

## A/B against main

AB

## NiceMark CPU nice-only

NICEMARK

## Notes

NOTES
