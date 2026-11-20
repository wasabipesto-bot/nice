# How far is the middle-out join's pairing from its floor? (director's note, 2026-11-20)

Labels: **[M]** measured (source given), **[P]** proven or a plain computation, **[J]** judged. Base 64 unless
said. The measured study that goes with this note is `CEIL/BRIEF.md` → `CEIL/RESULTS.md`.

## 0. Why ask

On the card that does most of the search, the pairing kernel is 60 % of a slice [M, design document §2]. An
earlier review of the "no shortcut" argument (`N5/REVIEW.md`) put a *flat* floor for any prefix–suffix join at
about ×4.5 under the join of that day and an *output-sensitive* floor about ×6 below that. The middle-out join
measures ×4.1 (RTX 3080) to ×4.8 (RX 9070 XT) [M]: it sits on the flat floor. So the only large factor left in
this family is the gap between "test every compatible pair" and "touch only pairs that survive". This note
asks whether anything practical lives in that gap, and what does not.

## 1. The object [M unless marked; per slice of 2^45 n, design document §1, §2, §6]

- About 238k tops (digits 4–12 of n; a certificate of about 17 digits: n² at positions ≥ 18, n³ at ≥ 31, the
  positions no value of the low four digits L can change) and 33.7M children (n mod 64^10; 20 digits: the low
  ten of n² and of n³).
- A job is (class, unit digit 9): 4,032 jobs; about **472 probes × 8,400 children** each; 1.6e10 pair tests per
  slice; 11.77M survive (7.4e-4; the uniform model gives C(47,20)/C(64,20) = 5.0e-4 [P]).
- The test: children in chunks of 64, one word per digit value; a probe ORs its ~17 words: **0.27 word
  operations per pair**, 0.13 after the common-mask skip keeps 0.49 of (probe, chunk) visits.
- Output-sensitive ideal: about 6 survivors per probe per job against 8,400 children scanned: a gap of ×1,400
  in pairs, ×90 in word operations (131 chunks × 17 ORs × 0.49 ≈ 1,090 against about 12 for six records).

## 2. Generic indexing cannot close the gap [J, with the arithmetic]

1. **It is an orthogonal-vectors problem.** "Find the pairs of masks with empty intersection" with masks in
   64 dimensions and lists of 500 × 8,400 is the orthogonal-vectors problem at dimension about 5·log2 N. No
   algorithm is known that beats the pair count by more than polylogarithmic factors there, and the best
   practical one is the bit-sliced scan the kernel already is. This is a statement about arbitrary masks; ours
   are not arbitrary (§3, §4).
2. **Per pair there is nothing left to save.** At 0.13–0.27 word operations per pair, any scheme that touches a
   pair individually (a hash probe, a bitmap lookup, a merge) loses. Only skipping whole 64-pair words wins.
3. **Skipping whole words is bounded by the size of a job.** A chunk can be skipped when the probe's digits
   meet something all 64 children share. A job has 8,400 children = 131 chunks = **7 bits of sort key**. One
   shared digit costs log2(64/20) = 1.7 bits of key and removes 17/64 = 27 % of visits: about ×1.2 per bit, so
   about ×3.6 at the very best for 7 bits against the ×2.0 the 8-bit key gets today (kept 0.49). A tree over
   chunks was counted earlier at 1.0–2.0× the flat visits [M, design document §6.5]. Joining larger lists (not
   keying on the unit digit, or on the class) gives more key bits but costs ×2 in pairs for every bit gained.
4. **Tables.** Four-Russians byte tables need 2,048 word operations per chunk and 8 lookups per probe; at 226
   probes per chunk after the skip that is 17.0 against 16.4 [design document §6.6]. Asymptotically ×2, at
   several times today's probes per chunk, which the join cannot have without paying in pairs.

## 3. Three restructurings tried on paper, and why each fails [P for the counts, J for the conclusion]

1. **Walk the bottoms as the tree they are.** A bottom's low 2j digits depend only on n mod 64^j, so the
   children of all slices are leaves of one 64-ary tree, and a top could prune subtrees. But the list a top
   meets today is already filtered by what the tree cannot see until its leaves: validity of all 20 digits
   (3.1 % of the 2^24 values of L) and the class (8 of 63). The walk visits 64 + 2,195 + 73,700 + 2.4M nodes
   to reach 1.19M leaves per top, against 67,000 children tested flat. Worse by ×35.
2. **A first stage shared by 4,096 slices.** A top's twelve highest certified digits do not depend on digits
   4–5 of the slice, and a child's eight lowest do not depend on the slice at all, so "top's 12 against
   child's 8" (17 % survive [P]) is the same test for a whole family of 4,096 slices. Sharing it would cut
   the per-slice tests by ×6 if its result could be consulted for free. It cannot: stored it is 6e10 bits
   (7.5 GB) per family and unit; recomputed per chunk it *is* 12 of the 17 ORs; and chunks that are the same for every
   slice are chunks of roots, of which only 5.7 % are valid children in a given slice, so each word would
   hold 3.6 live pairs instead of 64.
3. **Join tops with parents, or key the join on one more digit.** (top, parent) tests 3.1e10 pairs per slice,
   twice today's [P]. Keying on digit 10 as well is the (4, 11) shape, priced before: 64 times the bottoms.
   Doing either lazily after the pair test is what the prefilter already does.

## 4. One source of coherence that is not used: the magnitude of L [P for the widths; the gain is the study's]

The bottoms are residue objects: the join never uses *how large* L = n mod 64^4 is. For a fixed top, n is
monotone in L, so on an interval of L every digit position of n² (and n³) whose floor quotient is equal at both
ends is constant: an **extended certificate that holds for that interval only**. Widths of L over which the
next digits below a top's certificate stay constant (three tops across the range; one job's children are about
2,000 apart in L; a chunk of 64 spans about 2^17):

| digit | L-width where constant | in chunks of one job |
|---|---|---|
| n² position 17 | 3.4e7 – 6.5e7 (wider than the whole L range, 1.7e7) | all (at most one break) |
| n² position 16 | 5.3e5 – 1.0e6 | 4 – 8 chunks |
| n² position 15 | 8,300 – 15,900 | 4 – 8 children |
| n³ position 30 | 9.2e7 – 3.4e8 | all (rarely a break) |
| n³ position 29 | 1.4e6 – 5.3e6 | 11 – 40 chunks |
| n³ position 28 | 22,500 – 82,000 | 11 – 41 children |

So with a job's children **sorted by L** instead of by key, a (probe, chunk) visit knows about two more digits
of the top (n² position 16, n³ position 29; sometimes 17 and 30 where the top's certificate lacks them). If an
extended digit is already one of the top's digits, or two coincide, **no n in that span can be nice for this
top**: the visit is dead without reading a child. Two fresh digits survive with probability 0.53, three with
0.37 [P]. That is the same size as the common-mask skip (0.49), and it wants the same sort. A hybrid order
(a few leading bits of L, then the key) trades one against the other at about ×1.1–1.2 per bit either way.

**My prior [J]: ×1.0–1.25 fewer visits than today for the best hybrid, plus about half the records** (two more
digits in the OR set), i.e. below the ×1.3 at which I said it earns a kernel prototype. I commission the
counts anyway because (a) the prior rests on a uniform-digit model that is known to be 10–20 % off, (b) the
two skips may be less correlated than I assume, and (c) a measured "no" closes the last coherence source I can
name. The same idea from the other side (digits 10–11 of n², n³ are affine in the top's low digits, so 54 % of
(child, top digit 10) combinations are dead by the child's own digits [P]) cannot skip a visit, only thin the
records; it is counted as Q3.

## 5. What a factor of ten would need [J]

Fewer pairs, not cheaper pairs: more certified digits per side *at the same list sizes*, i.e. digits of the
middle of n² and n³ (positions 10–17 and 10–30: 29 of the 64) known from one side alone. Every route to those
that I can write down makes them known only to a pair (magnitude of L from the top's side, residue of the top's
low digits from the bottom's side), which is §4 and the prefilter. The earlier round on "below exhaustive"
methods (`BX/`) found the middle digits to be functions of every digit of n with no usable structure. Unless
that changes, the family ends within about ×2 of where the middle-out join is: about ×1.3–1.5 in the kernel
(lanes are 60.5 % busy; the wide path more) and what the stages around it still cost (40 % of a slice).

## 6. What the study decides

`CEIL/RESULTS.md` replaces the priors of §2.3 and §4 with exact counts on real slices and one cost model
(lane slots × ORs). Under ×1.3: the pairing is closed as a research line, with the measured ceiling, and the
remaining kernel work is ordinary engineering for the card. At ×1.3 or more: a kernel prototype on the branch.
