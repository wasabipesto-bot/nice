# G2 across bases: does the redesign hold above base 64? (brief, 2026-11-18 13:15 UTC)

You are an investigator on the "nice" number search. Work alone (do not start subagents), on this machine
only (ivory: 4 cores, 7 GB of memory). Hard stop **18:00 UTC**; write your results file before that, even if
unfinished.

## The question, and why it matters

A nice number in base b is an n whose square and cube together use every digit of base b exactly once.
The search is exhaustive, base by base. Today's GPU search is an "overlap join"; G2 is a redesign of that
join. A hand-written CUDA benchmark of G2 measured ×5.1 against today's code at base 64 on an RTX 3080, and the
design's exact CPU prototype gave similar modelled ratios at base 62.

The project's owner asked this morning: **is G2 only useful for base 64, or does it perform similarly well on
higher bases? "If this is a 5x improvement for all further work then I'm much more interested than a
b64-specific optimization."** Nobody has looked at G2 above base 64. Your job is to answer that with counts
measured on real data, and to say plainly what is measured, what is derived and what is guessed.

Facts you start from (verify what you rely on):

- After base 64 the bases with candidates are 65, 68, 69, 70 (66 has no digit-count range, 67 no residue
  class). Admissible n (candidates in a root residue class) relative to base 64, by my count: b65 ×0.9, b68 ×17,
  b69 ×42, b70 ×600. Check these.
- Digit masks are 64-bit everywhere today. **Neither today's join nor G2 runs above base 64 as written**:
  production falls back to a far slower "stride" path there (`common/src/cubecl_join.rs`, `fs.b > 64`).
- An October experiment extended today's CPU join to 128-bit masks for b65–69: fork branch `exp/join-wide`
  (c20ad7e6), write-up `~/projects/nice/scratchpad/2026-10-next-steps/JOIN-PAST-64-PROPOSAL.md`. It found the
  wide join ×209–435 cheaper than the stride path above 64, 128-bit masks costing ×1.16–1.19 with a split
  scan, and priced base 65 at 3–5 times base 64. Those prices are a month old (the join has gained about ×3
  since), but the structure of the estimate is useful.
- G2's inner test probes per-digit bit slices over a chunk of 64 bottoms, so its word width is the chunk size,
  not the base. My reading is that this part should carry above 64 nearly unchanged, while the parts that hold
  one bit per digit (child masks, common masks, digit fields packed in 6 bits, a slice table with one row per
  digit) must widen. That reading is untested.
- Three things in the base-64 result are specific to base 64: digits by shifts (power of two), a bit
  renumbering that fits G2's work units into the server's existing fields table (base 64's range is exactly
  [2^75, 2^76)), and 64 digits filling a 64-bit mask exactly.

Read first (all under `~/projects/nice/scratchpad/2026-10-research-program/G2/` unless a path is given):
`RESULTS.md` (the design, the Amdahl tables, the evidence labels), `REVIEW.md` (the adversarial review that cut
the model from ×10 to about ×5: use its unit costs, not the author's), `BENCH.md` (the GPU measurement at
base 64 and the measured unit costs of kernel v10), `PROPOSAL.md` §1–2 (the work unit and its "virtual
coordinate"), `NOTES.md`. Code: `proto/` (the exact CPU prototype, Rust, about 1,200 lines, u64 masks),
`model.py`, `model2.py`, `review/` (the reviewer's independent enumerator). The production join is
`~/projects/nice/common/src/overlap_join.rs` (CPU) and `cubecl_join.rs` (GPU), main at 7e0113fc.

## What to deliver

1. **The prototype above 64.** Extend the exact CPU prototype to masks wider than 64 bits (copy it to
   `bases/proto/`; leave `proto/` untouched). Prove it: (a) it still reproduces the recorded base-62 and
   base-64 counts of `RESULTS.md` exactly; (b) against brute force on whole small bases, including bases of
   each digit-count class (b mod 5 = 0, 2, 3, 4) and odd bases; (c) above 64, against an independent
   enumeration of at least two real units per base (the reviewer's `review/unit_indep.py` is a model for
   this), since brute force is impossible there.
2. **Counts per admissible n at bases 65, 68, 69 and 70** (base 64 as the control, in the same run), on a
   sample of real super-units wide enough that you can state the sampling error: tops, parents and children,
   chunks, kept words after the common-mask skip, pairs, survivors, full checks. For each base choose the
   shape (f0, k) and the unit's digit positions by the same Amdahl reasoning as `RESULTS.md` §2–4, and say
   whether base 64's shape (4, 10) is still the right one. Note that n has 13 digits at bases 62–65 and 14 at
   68–70.
3. **Predicted cost per admissible n at each base**, from those counts and the *measured* unit costs of v10
   at base 64 (`BENCH.md`), with every change the kernel needs above 64 listed and priced: wider child and
   common masks, 7-bit digit fields, more slice rows per chunk (and what that does to the shared-memory
   budget the tuned port just got under: `TUNE-RESULTS.md`), division by constants where base 64 used
   shifts. State which of these are counts and which are guesses.
4. **The comparison the owner asked for.** There is no production baseline above 64 except the stride path.
   Give two: (a) G2 against today's join design widened to those bases (from `exp/join-wide`'s counts and
   today's measured GPU cost per unit of work at base 64: say how you carried it over); (b) G2's cost per
   admissible n at each base against its own cost at base 64. One table: base, admissible n relative to
   base 64, G2 cost per admissible n, widened-today cost per admissible n, ratio, card-years on one RTX 3080
   for the whole base under each. Bands, not single numbers.
5. **The work unit above 64.** Base 64's bit renumbering is exact only for a power-of-two base. Say what the
   unit and its coordinate are at 65, 68, 69, 70 (a padded coordinate? how much padding? does it fit the
   server's range columns?), in half a page. No server code.
6. **A verdict in three lines at the top:** does the gain carry to bases 65–70 (yes / partly / no), with what
   ratio and what confidence, and what single GPU measurement would settle it. If the staged-input format of
   `bench/su64_*` generalises, stage one real base-65 super-unit in `bases/su65_<id>/` so a GPU benchmark can
   follow tomorrow; do not write GPU code today.

**Stop rule:** if by 15:30 UTC the widened prototype is not exact on the small-base and base-64 checks, stop
extending and write what blocks it.

## Rules

- ivory only. No rented machines, no ssh to other hosts, no calls to the production API, no git push, no
  pull requests. Write only under `G2/bases/` (and a scratch git worktree under
  `~/projects/nice/.worktrees/` if you need production code compiled; remove its target directory when done).
- CPU work under `nice -n 19`, at most 3 threads. Check `df -h /` before any build; stop and report if free
  space falls under 5 GB. `/tmp` is a 3.8 GB tmpfs: do not build or keep data there. Memory is small: stream,
  do not hold whole bases.
- Label every number [M] measured, [D] derived from measured numbers, [G] guessed. A cost ratio above 64 that
  rests on a guess says so in the same sentence.
- If the honest answer is "the gain shrinks above 64" or "base 70 is out of reach either way", that is the
  answer wanted. Do not round toward ×5.

## Deliverables

`G2/bases/RESULTS.md` (verdict first, then the tables, evidence, what is not proven), `G2/bases/NOTES.md`
(log), code and raw counts under `G2/bases/`. A final report to me of at most 40 lines: the verdict, the
table of item 4, and anything that surprised you.
