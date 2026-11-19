# FS: is the middle-out field structure a local optimum? An adversarial review (brief, 2026-11-19 05:50 UTC)

You are an independent reviewer and researcher. Work alone (do not start subagents), on this machine only
(ivory: 4 cores, 7 GB of memory, about 6 GB of free disk). **Hard stop 10:30 UTC.**

## The question, in the owner's words

The project ("nice": an exhaustive search for numbers whose square and cube together use every digit of a
base once) is replacing its GPU search join with a redesign, the "middle-out join". Today a unit of server
work (a "field") is a contiguous range of n, which any search algorithm can process. The redesign needs fields
that are sets of n sharing a few *middle* digits. The owner approved the build yesterday with this concern:

> "I appreciate the simplicity of the current field structure and that we aren't pigeonholed into a specific
> search implementation. I want to ensure that this new field structure won't prevent us from being able to
> incorporate a significant amount of optimizations (ie that this isn't a hill climb to a local optimum,
> preventing/delaying us from reaching a true peak elsewhere)."

They also said the join and the field structure may still be re-architected before any schema is fixed. **Your
job is to try to show that the proposed field structure is the wrong commitment**: find a structure that
would beat it, or an optimisation it blocks, with numbers. If you cannot, say exactly what you tried and what
would have to be true for it to be wrong.

## What exists (read in this order)

Under `~/projects/nice/scratchpad/2026-10-research-program/`:

- `G2/RESULTS.md`: the design and its reasoning (work units keyed by the middle digits that top prefixes and
  bottoms share; shape (f0 4, k 10); Amdahl tables; where the ceiling is).
- `G2/BUILD-NOTES.md` §2 ("The interface: what a field is, and what it permits and forbids"), §3, §7: what was
  built and the engineers' own account of the commitment. A field at base 64 fixes digits 6–8 of n and holds
  4,096 slices (a slice = all n sharing digits 4–8); the coordinate is a per-base renumbering of n.
- `G2/PROPOSAL.md` §1–4: the server side of it (three options, including no server change).
- `G2/bases/RESULTS.md`: the design above base 64 (shapes per base, the padded coordinate, field sizes).
- `BX/COMMON.md` and the three `BX/a*/NOTES.md`: last week's study of whether anything beats work proportional
  to the candidates (it found nothing), including a lower-bound model ("view certificates") and its exact
  optimum at small bases.
- `G2/REVIEW.md`: an earlier adversarial review of the design's speed claims, as a model of the standard.
- Measured state: `EXPERIMENTS.md` entries MO.1–MO.6 and G2.7–G2.11 (end to end ×3.9–4.0 against production on
  an RTX 3080 at base 64; base 65 at ×2.08 of base 64's cost; the kernel is 71 % of a slice).
- Tools: the exact CPU prototypes `G2/proto/` and `G2/bases/proto/` (the second handles any base to 70 with wide
  masks, has `su`, `sample`, `smallsu`, `unitat` commands and a pricing script `G2/bases/price.py`); they count
  tops, parents, children, chunks, pairs, kept words and survivors exactly for a given shape and unit. Build
  them in their own directories (small crates; `nice -n 19`, at most 3 threads; check `df -h /` first and stop
  under 4 GB free).

## What to do

1. **State the commitment precisely.** What exactly would the server and every future tool have to assume
   once a base's fields are defined this way (which digits are fixed per field, the coordinate, field sizes,
   alignment)? What stays free (shape, slice key, kernels, mask width, prefilter, order of work inside a
   field)? Check the engineers' "permits / forbids" list against the code and the design; correct it.
2. **Attack it with alternative structures.** For each, say what a field would be, what a join inside it would
   look like, and price it with exact counts from the prototype where the prototype can express it (or a small
   extension of it), against the current shape, at base 64 and at least one of 65, 68, 70:
   - other key positions and widths (fields fixing digits 7–8 only, 5–8, 6–9; coarser and finer fields);
   - keys that are not digit runs of n (residue classes of n, low-digit classes, classes of the top prefix, a
     hash of several digit groups);
   - leading-range × middle-digit rectangles; fields that are contiguous in n after all (what the redesign
     loses if a field must stay a range: is the loss really the factor the design claims?);
   - three-way or multi-level joins (top × middle × bottom) and what unit they would want;
   - a shape that changes across the base (different (f0, k) in different regions) and whether one field
     definition can serve it;
   - anything else you think of. The best attack is one nobody listed.
3. **Attack it with future optimisations.** List the optimisations still on the table inside the join
   (`G2/RESULTS.md` §4 and §6, `G2/BUILD-NOTES.md` §7 and §9, the pairing headroom found by BX, table-lookup
   pairing, smaller records, sharing parents or tops across neighbouring slices, a different chunking, deeper
   bottoms at larger bases) and for each say whether the proposed field definition permits it unchanged, permits
   it only with a different choice of fixed digits, or forbids it. For "sharing across neighbouring slices"
   work out which choice of fixed digits makes the neighbours that could share live in the same field.
4. **Recommend the field definition that keeps the most freedom** at bases 64 and 65: which digits a field
   fixes and how many, the field size and count, and why; with what it costs in speed, if anything, against
   the definition in the notes. One table.
5. **Answer the owner's question in half a page**: is this a local optimum, with what evidence, and what would
   falsify your answer. Distinguish what is proven, what is measured, and what is your judgement.

## Rules

- ivory only. No rented machines, no ssh elsewhere, no production API, no git push, no pull request. Write only
  under `G2/fs/` (code, raw counts, notes). Do not modify the prototypes in place: copy what you extend.
- Label every number measured (exact count from the prototype), derived, or guessed. A structure you could not
  price is listed as unpriced, not dismissed.
- You are not here to defend the design. If the honest answer is "the proposed fields are wrong" or "nobody can
  know yet", say so and say what experiment would decide it.

## Deliverable (by 10:30 UTC)

`G2/fs/REVIEW.md`: the answer to the owner first (half a page), then the commitment stated precisely, the
table of alternative structures with their prices, the table of future optimisations against the field
definition, the recommended definition, and what you did not get to. Then a report to me of at most 35 lines.
