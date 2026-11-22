# Below exhaustive, round 3 (director, 2026-11-22): an attempted lower bound, and where it would have to fail

Standing line; a negative round is a status. Labels: **[P]** proven or plain computation, **[M]** measured,
**[J]** judged. Rounds 1 and 2: `EXPERIMENTS.md` BX.1, BX.2; `BX/ROUND2.md`.

## 1. The three numbers at base 64 [P from the uniform model; M where said]

| what | how many |
|---|---|
| pair tests the middle-out join makes | 1.7·10^19 (1.6·10^10 per slice, measured) |
| pairs that survive (37 certified digits all distinct) | 1.3·10^16 (measured: 11.77M per slice) |
| n whose two ends, each read to full depth, certify 52 distinct digits | about 10^9 |
| nice numbers expected | 10^-4 |

The search pays for the first line. An output-sensitive pairing would pay for the second (×1,300 less); a
method that produced the third line directly would be ×10^10 below today's cost. **Those two gaps are the whole
question; everything else is constants.**

## 2. The attempt

**Claim to prove:** any exact method costs at least a constant times the second line.

1. **Digit localisation [P].** Output digit p of n² is a function of n² mod b^(p+1) or of n² to relative
   precision b^(p − len). A set of n on which it is constant is a union of residue classes mod b^(p+1) with
   that digit (about b^p of them: the bottom-tree nodes of that depth) or of intervals (top-tree nodes). So
   every certificate any method can hold is a union of nodes of the two trees. There is no third kind.
2. **Random middle [M, round 1].** Given both ends to any depth short of all of n, the uncertified digits are
   uniform and independent to the precision measured (10^-4 per digit, all orders tested, bases ≤ 62).
3. **From 1 and 2:** a method is a choice of tree nodes to examine; a node can be discarded only on a repeat
   among its certified digits; what is not discarded must be examined deeper or checked. That is the "view"
   model whose exact optimum round 1 computed for bases 20–33 by a fractional cover: the flat join is within
   ×1.03–1.11 of the optimum at production weights, and an ideal pairing that pays only for survivors is on it.

So the bound holds in the view model, numerically for small bases, with the second line as the floor. **It is
not a theorem for all methods, and it cannot be made one** (a proof that no fast method exists for a concrete
problem of this kind is beyond what anyone can prove). What the attempt does give is the list of the only
places a method could step outside it:

## 3. The three ways out, and what stands in each

1. **A certificate that is not a tree node.** Excluded by step 1 [P].
2. **Paying less than one unit per node or pair.** This is where the join's gains came from (64 pairs per
   word, children by two additions) and where this week's measurements sit: no order or skip test beats
   today's by more than ×1.18 and a perfect skip gives ×1.99 (2026-11-20); wider words ×1.09 on NVIDIA
   (2026-11-21); sharing loads between probes is being measured today. Constants; the pairing is an
   orthogonal-vectors problem, for which nothing better than constants is known at this dimension.
3. **Counting without visiting.** Exact identities exist. Ryser's formula for the permanent gives

       number of nice n = Σ over digit sets S of (−1)^(b − |S|) · #{n in range : n² and n³ use only digits in S},

   and the equivalent Fourier form says n is nice exactly when Σ over output digits of ω^(j·digit) vanishes for
   every j = 1 … b − 1 (ω a primitive b-th root of unity): for b = 64, "the digits are balanced modulo 2, 4, …,
   64". Both are true and both are useless as they stand [P]: the first needs 2^64 exact restricted-digit
   counts that cancel from 10^22 down to 0 or 1 (and there are as many terms as the join makes pair tests);
   the balance conditions are implied by distinctness of the digits already certified and prune nothing
   earlier (37 distinct digits out of 64 are automatically within every balance bound). A method here would
   need the restricted-digit counts in closed form, i.e. a theory of squares and cubes with digits in a
   prescribed set, which is the open problem the literature has for a single missing digit, not for 2^64 sets.

## 4. Status

Nothing below exhaustive. The line now has a precise shape: two gaps (×1,300 and ×10^10 at base 64), one model
in which the first is the floor, and three exits of which one is closed by proof, one is constants, and one
needs mathematics that does not exist. I do not see a round 4 that is more than restating this; **the line
stays open in the sense that anything new I meet (in the literature sweeps, or from the kernel work) is tested
against these two gaps**, and I will report it when that happens rather than produce a round for its own sake.
