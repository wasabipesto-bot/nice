# A3, day 2: the pairing gap on real masks (2026-11-17)

Yesterday's three investigations and your model agree: the only slack left inside the
view-certificate model is the pairing step. An ideal join that pays only for pairs passing
disjointness sits on the floor; A2 measured that ideal at ×8–27 on the pair term inside a
transversal unit (`../a2-digitsets/NOTES.md` I1, I8) and found practical structures at ×1.0–1.5;
the redesigned join G2 (`../../G2/RESULTS.md`, reviewed in `../../G2/REVIEW.md`) keeps 0.45–0.58 of its
64-bottom chunk incidences with one common-mask test, and its reviewer argues that no group
test can remove 90 % at these densities. In G2 at base 64 the 64-pair words are about 60 % of
the remaining cost, so this step now decides how far past ×5 the structure can go.

Your proposal for another day was to measure the gap where it matters and to try structured
orthogonal-vectors schemes on real masks. Do that, with the adversary's eye:

1. **Real data.** One real base-64 super-unit is staged at `../../G2/bench/su64_712012851/` (tops with
   masks and classes for all 64 units; `../../G2/BENCH.md` describes the files); the prototype crate
   `../../G2/proto/` generates the depth-9 parents and their children (bottom masks) for any
   super-unit at bases 62 and 64 (build your own copy under your directory; a single thread).
   Use two super-units per base.
2. **The gap, exactly, in this structure:** per admissible n at production shape (4, 10): pairs;
   pairs that pass; G2's flat and kept chunk incidences (reproduce its 0.49); the ideal
   (output-sensitive) count in units that a GPU could pay for (kept 64-pair words if only
   words containing at least one passing pair were touched; and if words were packed
   optimally).
3. **Schemes, each with its kept fraction and an honest cost per operation on a GPU**
   (lookups in shared memory, instructions, memory per chunk; today's measured costs are in
   `../../G2/REVIEW.md` F1): chunk formation by clustering instead of a sort key (greedy set-cover
   or k-medoids on masks, to maximise the common mask); two-sided blocking (tops grouped too:
   block-against-block common-mask tests; the tops of a unit that share leading digits);
   hierarchical common masks (a chunk of chunks); bucketing bottoms by their presence pattern on
   the d digits most frequent among the tops that probe that class (2^d buckets, each top visits
   only the buckets it is disjoint from on those digits), with d chosen per class; random-subset
   or locality-sensitive bucketing tuned to the measured per-digit densities; anything from the
   orthogonal-vectors literature that fits dimension 64 and set sizes of 16–20 (search it:
   subset-query data structures, partial-match tries, the polynomial method for low-dimension
   OV; say for each why it does or does not survive a 5–25 ps word).
4. **Asymmetry:** tops and bottoms are not symmetric (tops' digits are leading output digits,
   strongly non-uniform and shared among neighbours; bottoms' are low output digits, with
   residue structure: at base 64 the lowest digit of an odd square is ≡ 1 mod 8). Measure the
   per-digit presence frequencies and pairwise co-occurrence on both sides and say what the
   best exploitable structure is.
5. **Verdict.** Kill criterion: if no scheme reduces the cost of the pairing term by at least
   ×1.5 against G2's sorted-chunk skip at a GPU-plausible unit cost (state the cost model), the
   pairing line is closed, and say what the exact ceiling is and why. If one does, specify it
   precisely enough to add to the GPU benchmark.

Rules as yesterday (`../COMMON.md`): CPU only on ivory, one thread, `nice -n 19`, single runs
under ten minutes, keep 4 GB of disk free, write only under your own directory, no pushes, no
pull requests, no subagents, no rented machines, no contact with the production API. Continue
your `NOTES.md` (a "Day 2" section). Hard stop **10:30 UTC**. Your final message is at most 300
words for the program's director: the verdict against the kill criterion first.
