# Below exhaustive: common ground for every investigator on this line (2026-11-16)

## The problem

A **nice number** in base b is an integer n whose square and cube, written in base b, together
use every digit 0 … b−1 exactly once. So n² and n³ have b digits in total; n has L ≈ b/5 digits
(L = 13 at b = 62), n² about 2L, n³ about 3L. The only one known is 69 in base 10. The project
(`~/projects/nice`, upstream `wasabipesto/nice`) has searched every base up to 60 exhaustively
and is in base 62 now. The heuristic expected count per base is tiny (about 2e-4 at base 62);
the expected total still reachable by today's methods (bases 62, 64, 65) is about 0.2 %. The
expected count per base only reaches 1 somewhere beyond base 125, where the candidate ranges
are astronomically large. **So with methods whose work is proportional to the number of
candidates, a second nice number will almost certainly never be found.** That is why this line
exists.

## What exists

- **Tree / stride search:** fix digits of n from the top (the leading digits of n² and n³ are
  then known) or from the bottom (n mod b^k fixes the low k digits of both), prune on repeated
  digits; a residue filter: a nice n satisfies n² + n³ ≡ b(b−1)/2 (mod b−1), which leaves at
  most a few residue classes.
- **The overlap join** (`common/src/overlap_join.rs` module docs; read them): a list of
  certified top prefixes (t digits) and a list of certified bottom residues (mod b^k) with
  t + k > L, joined on the shared digits and the residue class; each matched pair costs one
  AND of two digit masks; survivors get a middle-digit prefilter and a full check. At base 62
  it tests about 2e-2 pairs per admissible candidate and runs at about 5e-16 s per candidate
  on one GPU.
- **Accounting every method so far obeys:** fixing d digits of n (from either end) determines
  at most 2d output digits (one of n², one of n³). With all L digits fixed from the ends, 2L of
  the 5L output digits have been used for pruning and the other 3L ("the middle": around
  position L of n² and the middle L of n³) arrive only when n is complete. The number of n
  whose 2L end-determined digits are all distinct is about N · (roots/(b−1)) · e^(−0.094 b) (N =
  candidates in the base), and every method so far touches each of them at least once. Work is
  therefore N · c^b with c slightly below 1: exhaustive up to a constant.
- **The standing argument that nothing better exists**, written to be attacked:
  `../2026-11-fresh-eyes/NOTES.md` §2, and one adversarial review of it, `N5/REVIEW.md` (verdict:
  no exponent-changing hole found). An earlier theory round: `../2026-08-theory-review/` if it
  exists on disk (Hall subdivision, b^r ± 1 invariants, carry-state ladders: all closed).

## What counts as a result here

1. **A method that touches fewer than the baseline count of candidates**, shown by a prototype
   on bases where the truth can be checked (exhaustive enumeration is feasible up to about
   base 30 in a script, further on sub-ranges; the project's own results cover every base to
   60): report the number of elementary operations as a function of base for your method and
   for the two-sided tree, and fit the growth. A constant factor is interesting only above ×10
   at base 62; a different exponent is the prize.
2. **Or a new necessary condition** on partial information (some digits of n fixed, or none)
   that involves the middle output digits, or any invariant not in the list above, with its
   rejection rate measured.
3. **Or a real negative:** a precise statement of a model and why no method in it beats the
   baseline, plus the list of ideas you tried with the reason each one failed, concretely
   enough that the next person does not retry them.

Do not restate the standing argument. Spend the time on ideas that are not in it. Keep a living
`NOTES.md` in your directory (ideas tried, in order, each with its outcome and the code that
shows it): you may be resumed tomorrow with this conversation intact, and others will read it.
Prefer many small experiments to one large write-up. Say plainly what is measured, what is
derived and what is a guess.

## Rules

CPU only, on this machine (ivory; 4 cores shared with three other investigators): one thread
each, `nice -n 19`, single runs under ten minutes (use small bases and sub-ranges), keep 4 GB of
disk free (`df -h /`), `/tmp` is a small tmpfs. Python or a small standalone Rust crate inside
your own directory (not the `nice` workspace's build). Write only under your own directory in
`~/projects/nice/scratchpad/2026-10-research-program/BX/`. No pushes, no pull requests, no
subagents, no rented machines, no contact with the project's production API or servers, nothing
on any other machine. Web search is fine for literature (keep queries to technical terms).
Your final message is at most 300 words for the program's director: the single most promising
thing you found (or the sharpest negative), then what you would do with another day.
