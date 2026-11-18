# NM brief: near misses as a by-product of the nice-only search (2026-11-18)

You are a researcher on the nice research program (repo `~/projects/nice` on this machine, ivory;
upstream `wasabipesto/nice`). The maintainer's instruction: the program exists "to delve deep
into novel high-impact ideas". Two days of work (`BX/`, `G2/` in the program directory
`~/projects/nice/scratchpad/2026-10-research-program/`) established that no method finds nice
numbers faster than exhaustively, and that the expected number of nice numbers in the bases
still reachable is about 0.2 %. So the search, as it is, will almost certainly end with nothing
to show. This line asks a different question: **what else could the same compute discover?**

## The idea

A nice number in base b has all b digits of n² and n³ distinct. A number that misses by one
digit (b − 1 distinct) is about C(b, 2) ≈ 1,900 times more frequent at base 62; one that misses
by two, about a million times. By the uniform model that fits the exhaustive data
(`BX/a3-adversary/NOTES.md`: the near-nice tail matches the product formula to 2 %), base 62
should hold of the order of 0.4 numbers with 61 distinct digits and a few hundred with 60:
"the nicest numbers of base 62". **Today's nice-only search throws them away**: the join
discards every candidate at its first repeated digit. Its last stage, the full check
(`common/src/join_check.rs`, `cubecl_join::check_kernel`, and the CPU path in
`common/src/cpu_join.rs` / `client_process.rs`), computes the digits of n² and n³ for every
survivor that reaches it (about 4.5e10 per base-62 field). If that stage counted repeats
instead of stopping at the first, it would find every near miss whose end digits are clean,
which by a rough count is over half of them, for a small extra cost. Base 62 is being searched
now (about 14 % done; each day that passes loses about 1.2 % of it for good), base 64 is next.

Detailed mode already has near misses on the wire: submissions carry `nice_numbers:
Vec<NiceNumberSimple { number, num_uniques }>`, `number_stats::get_near_miss_cutoff(base)`
defines the cutoff, and the server stores nice-only submissions' numbers without checks
(`api/src/main.rs`, the `SearchMode::Niceonly` branch).

## Task

1. **Definitions and coverage, exactly.** Say precisely which candidates reach the full check
   in today's join (clean top certificate, clean bottom certificate, disjoint masks, the
   prefilter's digits clean, the residue class): so the by-product set for a tolerance m is
   {n : n reaches the check and has at least b − m distinct digits}. It must be a property of
   the field and the join's shape, the same on every device (the search's counters already
   are). Compute what fraction of *all* numbers with b − 1 and with b − 2 distinct digits it
   contains: by the uniform model and by brute force on small bases (20–30) where both sets can
   be enumerated. Then the variants: also tolerating repeats in the prefilter's digits; in the
   AND (pairs sharing up to m digits); in the certificates themselves; with each variant's
   extra survivors per stage from exact counts on real base-62 and base-64 partitions (the CPU
   join can run sampled partitions of real fields on one thread; `CPU2/raw/scripts/` and
   `G2/proto/` show how fields and partitions are sampled).
2. **Yield.** The measured niceness histogram among checked candidates on real base-62 and
   base-64 partitions (the tail as far down as the sample reaches), against the model; from
   it the expected number of by-product numbers at b − 1, b − 2, b − 3 for the remaining 86 %
   of base 62 and for all of base 64, with honest intervals. Also what bases 58 and 60 (already
   finished) would have yielded, for scale.
3. **Cost.** Implement variant A (the check counts repeats up to m and reports numbers with at
   least b − m distinct digits; m a small constant, 2 by default) in the CPU join in a scratch
   worktree `~/projects/nice/.worktrees/nm-near-miss` on a local branch (never pushed), exact
   against brute force on small bases (the reported set equals the definition) and with the
   nice-number result and every existing counter unchanged. Measure the CPU cost on ivory at
   production shapes (b60 1e16, b62 1e17, b64 1e17; one thread, interleaved with the unmodified
   join, at least five alternations, counts identical). For the GPU check kernel: read it,
   say exactly what would change (the gate between n² and n³'s upper limbs is the delicate
   part: with a tolerance, more planes continue), count from the CPU run how many more
   survivors pass the gate and each later step, and price it with the measured unit costs
   (`N17.1` and `N22/RESULTS.md` shares; the check is 7 % of a base-62 field and 11 % of a
   base-64 field on the production card). If time allows, implement it in the kernel and prove
   it exact on lavapipe from CI's Mesa (container `localhost/lvp26:latest`, see the program
   README "Device tests on CI's Mesa without a box") with both compilers; timing on a card is
   not possible today (no rented machines).
4. **What the rest of the system would do with them.** Follow a nice-only submission's
   `nice_numbers` through the API, the jobs and whatever the site reads: would entries with
   fewer than b distinct digits be stored and shown as near misses, or be taken for nice
   numbers anywhere (an alert, a counter, a "found" banner)? List every place with file and
   line. Is anything needed server-side at all?
5. **Verdict and a one-page proposal** for the maintainer (`NM/PROPOSAL.md`; this is a new
   feature, so it needs their yes before any pull request): what it would find, what it costs,
   what must change, and what is lost each day it is not running during base 62.

**Kill criterion:** if variant A at m = 2 costs more than 3 % of a field at base 62 or base 64
(CPU measured, GPU priced from counts), or the expected yield over the rest of base 62 plus
base 64 is under 30 numbers with at least b − 2 distinct digits, stop and write up why.

## Rules

CPU only on ivory: two threads at most, `nice -n 19`, check `df -h /` before builds and keep
3 GB free (a release build of the CPU join harness is allowed, in its own `CARGO_TARGET_DIR`
under the worktree; delete it when done). Nothing is pushed; no pull requests; no subagents;
no rented machines; the production API may be read lightly from ivory if needed (primary keys
or `field_id=eq.`, `User-Agent: nice-audit-census`) but nothing is claimed or submitted;
nothing on the fleet, the server, demoux or mayalaran. Keep a living `NM/NOTES.md`. Deliver
`NM/RESULTS.md` with the verdict against the kill criterion first. Hard stop **11:30 UTC**.
Your final message is at most 300 words for the program's director.
