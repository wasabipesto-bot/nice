# N6: can the join test fewer top certificates? (2026-11-13, ivory, CPU only)

Tags: **[M]** measured here (exact counts over the sample, CPU), **[D]** derived from measured numbers by
the arithmetic shown, **[A]** assumed, **[E]** from earlier program measurements (cited).

## 0. Answer

DRAFT

## 1. What a top test is

**Shape.** Every production field the join takes runs `(t, k, p) = (L − 3, 6, 2)` (`JoinParams::for_length`):
`f0 = L − t = 3`, partition = the two digits of `n` at positions 3 and 4, key = position 5. The host builds the
*top layer* once per slice: every prefix `P0` of depth `t − p = L − 5` (a block of `b^5` consecutive `n`) whose
certificate passes and whose ancestors' passed (`Base::top_layer`, breadth first, cap `k = 6`). A **top test** is
one `(P0, v)` pair, `v` a partition value in `0..b²`: the block `P = P0·b² + v`, i.e. the `b^3` numbers
`[P·b³, P·b³ + b³ − 1]` (clipped to the slice at its two ends), certified by `Base::cert(a, e, 6)`. On the GPU,
`top_fd_kernel` gives each layer prefix a thread that walks the batch's 16 consecutive partition values (one
launch = 16 slots, `join_plan::SLOTS`), seeding `P²`, `P³` by division at the batch's first slot and stepping
them by five digit-array additions after that; `top_kernel` takes the two clipped blocks per slice.

**What it certifies.** For `j = 2, 3`, the digits of `n^j` that are the same for every `n` of the block: the
common top digits of `a^j` and `e^j`, from `c0 = max(6, ndig(e^j − a^j))` up, minus `a^j`'s run of `b − 1`s and
the digit above it if `e^j`'s value at `c0` is one more (then that digit is `d` or `d + 1` for every `n`, which
`close_certificate` uses: Hall's condition on the two "dom" intervals). The pair passes iff those common
digits are 2·… distinct (a 64-bit mask) and the closure leaves each dom interval a free digit. Because the block
is `b³` wide, `e² − a² ≈ 2n·b³` and `e³ − a³ ≈ 3n²·b³`, so the certificate covers `n²` from position `L + 3`
(or `L + 4`) and `n³` from `2L + 2` (or `2L + 3`) up: concretely (`raw/example.py`, [M])

| base | L | n² / n³ digits | layer prefix (b^5) certifies | a pair (b^3) certifies | new digits per pair |
|---|---|---|---|---|---|
| 60 | 12 | 24 / 36 | n² 18–23, n³ 30–35 (12) | n² 16–23, n³ 28–35 (16) | n² 16, 17; n³ 28, 29 |
| 62 | 13 | 25 / 37 | n² 18–24, n³ 30–36 (14) | n² 16–24, n³ 28–36 (18) | n² 16, 17; n³ 28, 29 |
| 64 | 13 | 26 / 38 | n² 18–25, n³ 31–37 (15) | n² 16–25, n³ 29–37 (19) | n² 16, 17; n³ 29, 30 |

(the exact positions move by one with the field's leading digit and the carry run; §3 has the distribution).

**Why a pair fails.** Its layer prefix passed, so the prefix's 12–15 common digits are distinct. The pair adds
about four digits — two of `n²`, two of `n³` — and fails iff one of them repeats a prefix digit or another new
one (or, in ~2 % of failures, the closure empties a dom interval). With ~14 of 62 digits taken and four new
draws, roughly a third survive, which is the measured 0.32–0.35 (§3). The four new digits change at very
different rates along `v` (the GPU's walk): one step of `v` moves `n` by `b³`, so `n²` by `≈ 2n·b³` and `n³` by
`≈ 3n²·b³`. At b62 with leading digit 2.5 that is `≈ 5·b^15` and `≈ 18·b^27`: `n²`'s position 17 changes
every ~775 partitions (5 values over a prefix), position 16 every ~12; `n³`'s position 29 every ~210, position
28 every ~3.4. A collision of a slow digit kills a long run of consecutive partitions; a collision of a fast
digit kills one to a dozen. That is the whole clustering structure, and it decides every scheme below.

**What it costs and what it recomputes.** Measured on the RTX 3080 (EXPERIMENTS L35.1, [E]): a stepped slot
0.198 ns, a seeded slot 0.350 ns (seed ≈ 1.77 steps); later FD top test 0.14–0.15 ns on both cards; "the step's
additions are unmeasurably small — what remains is the two certificate scans, the remainder, the carry tests and
the append". So a test's cost is the scan of ~16–19 common digits plus the low words for `x mod b^c0`, not the
stepping: every test recomputes all its certified digits, the ~14 it shares with its layer prefix included.
Share of a field (EXPERIMENTS, [E]): 22–23 % at b62 1e17, 18–19 % at b60 1e16 (3080 and 9070 XT); at b64 1e17
16.7 % before #254, **8.4 % after it** (FD at power-of-two bases, CUDA). One fifth is b60/b62; b64 is now a twelfth.

**What the field certificate removes first.** `fc = cert(s, e − 1, 6)` covers the whole field: if it fails the
field has no tops at all (the top layer is empty: 0 tests). Otherwise it is only used to prune bottoms; every
top's mask contains it, but nothing on the top side skips work because of it. The layer itself removes the
`b^5` prefixes that fail (and their whole subtrees): of the `b` prefixes under a certified `b^6` block, ~0.6
are in the layer (§3), and every one of those is tested at all `b²` partitions.

DRAFT-REST
