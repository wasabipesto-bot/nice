# How far is the middle-out join's pairing from its floor? Exact counts on real slices (brief, 2026-11-20 06:15 UTC)

You are a research engineer. Work alone (do not start subagents). **Hard stop 11:35 UTC; the box destroys
itself at about 11:55 UTC.** This is a counting study on the CPU: no GPU work, no production code changes.

## Background, in one page

The "nice" project searches exhaustively for numbers n whose square and cube together use every digit of a base
exactly once. A redesigned GPU join, the **middle-out join**, lives on the fork branch `dev/mo-clean` (head
`c2152084`, worktree `~/projects/nice/.worktrees/midout-clean` on ivory, this machine). **Read first:**
`~/projects/nice/scratchpad/2026-11-midout-design/DESIGN.md` §1, §2, §5, §6.1–6.7 and its "Terms" paragraph
(slice, top, bottom, parent, child, class, job, probe, chunk, record). Then `common/src/midout/cpu.rs` on that
branch: the exact CPU reference, generic over the base; it is your instrument.

At base 64 a *slice* is every n sharing digits 4–8. Inside a slice, a *top* is n div 64^4 (digits 4–12 known;
its certificate is the set of digits of n² and n³ that are fixed whatever the low four digits L are: about 17
digits), a *child* is n mod 64^10 (its certificate: the low 10 digits of n² and of n³, 20 digits). A *job* is a
(class, unit digit 9) pair: about 472 probes (tops) against about 8,400 children, in chunks of 64 children
transposed into one 64-bit word per digit value. A probe ORs its ~17 digit words over a chunk; a zero bit is a
(top, child) pair with disjoint digits (a survivor). Before that, the *common-mask skip* drops a (probe, chunk)
visit when the probe holds a digit every child of the chunk holds; the children are sorted by an 8-bit key so
chunks share digits, and about 0.49 of visits are kept. This pairing is 60 % of a slice's time on the card that
runs the search. Per slice the design document gives: 33.7M children, about 238k tops, 250M (probe, chunk)
visits of which 123M are kept, 10.9M non-zero words (records), 11.77M survivors.

**The question:** how much of that work could any exact reordering or extra test still remove? My paper
analysis (`CEIL/NOTES.md`, being written beside this brief: read what is there) says generic indexing cannot
help much and that one source of coherence is unused: **the magnitude of L**. For a fixed top T (digits 4–12)
and L in an interval [L1, L2], n = T·64^4 + L is monotone in L, so every digit position p of n² (and of n³) with
floor(n²/64^p) equal at both ends is constant on the interval: **extra certified digits of the top that hold for
that interval only**. If children are sorted by L (n mod 64^4) instead of by key, a chunk of 64 children of one
job spans about 2^17 in L, over which roughly n² positions 17 and 16 and n³ position 30 should be constant. If
such an extended digit already belongs to the top's own certificate (or two extended digits coincide), **no n in
that interval can be nice for this top: the whole chunk is skipped without looking at the children**; where the
extended digits are new, they join the probe's OR set and fewer pairs survive. This competes with the key order
for the same sort, so only counts can decide.

## What to measure (exact counts; every number reproducible from a command you record)

Instrument: an example or test-only binary on a scratch branch **`exp/mo-ceiling`** from `c2152084` (worktree
`~/projects/nice/.worktrees/mo-ceiling`; never commit to `dev/mo-clean`). Use the CPU reference's own tops,
parents, children, classes and masks so the objects are the code's, not a re-derivation. Slices at base 64: 712012851,
502136830, 4977728 (used in earlier parity runs), the first and the last slice of the range, and at least five
more drawn at random with a recorded seed; all 4,032 jobs of each if time allows, otherwise a recorded random
sample of at least 512 jobs per slice with the sampling error stated.

- **Q0, the instrument reproduces today:** with the code's own order and skip: kept fraction of (probe, chunk)
  visits, ORs per kept visit, records, survivors, per slice. They must match the design document's numbers
  (and the counters `cpu.rs` already returns) before anything else is believed.
- **Q1, what a sort key can buy:** kept fraction of the common-mask skip with the children ordered by a k-bit
  key for k = 0, 2, 4, 6, 8, 10, 12 (the code's key construction extended), and by two stronger orders
  (lexicographic on the full mask in descending digit frequency; a greedy clustering that grows each chunk by
  the child sharing most digits with the chunk so far); also chunk sizes 32 and 128. This gives the measured
  curve "kept fraction against bits of key" and a practical upper bound for any chunking of one job.
- **Q2, the magnitude order (the new idea):** children of a job sorted by L, chunks of 64 consecutive. For each
  (probe, chunk): the extended digits (positions of n² and n³ below the top's certificate that are constant
  between the chunk's first and last L; prove the monotonicity argument in your notes, including that the
  certificate's own positions are constant a fortiori) and then: (a) the fraction of visits dead by
  self-collision (an extended digit in the top's set, or two equal); (b) the fraction dead by the common-mask
  test under this order, with the extended digits included in the probe's set; (c) both; (d) the distribution
  of the number of extended digits; (e) records and survivors when the extended digits join the OR set.
  **Exactness check, mandatory:** the set of survivors that are finally nice-candidates must be unchanged:
  every pair the new tests discard must be one whose n fails the full digit test (check by brute force on the
  discarded pairs of at least one whole slice: none may be a survivor that passes production's prefilter and
  full check; and argue it in general).
  Then **hybrid orders**: sort by (the top j bits of L, then the key) for j = 1…6, with the interval taken as
  the j-bit cell: kept fraction by (a), (b), both. Report the best exact combination.
- **Q3, the same idea from the other side:** digit 10 of n² and of n³ is an affine function of the top's digit
  10 (call it a0) once the child is fixed. For each (child, a0): is the child's own extended set (20 digits +
  those two) still all distinct? The fraction of (child, a0) pairs dead; and the reduction in records if each
  (chunk, a0) carried a 64-bit "dead for this a0" word that probes OR in. No skip of visits is expected from
  this one; say what it does to records and what it would cost in word operations to build.
- **Q4, sharing between probes:** with a job's probes in the best order you can find (by top value; by mask),
  the number of ORs if consecutive probes reuse the OR of their shared digits (a trie over the probes' digit
  sets), against the plain sum of digits.
- **Q5, one cost model for all variants:** (i) OR count per slice (kept visits × digits ORed); (ii) **lane
  slots**: on the card a wave is 64 chunks of one job running side by side, and a probe costs the whole wave an
  iteration unless every lane skips it; so lane slots = Σ over waves of 64 × (number of probes kept by at least
  one chunk of the wave), and busy fraction = kept visits / lane slots. Today's measured busy fraction on the
  card is 60.5 %: your model of today's order must come out near it, or say why not. Report (i) and (ii) for
  today's order and for the best variant of Q1, Q2 and the hybrids, and the per-visit decision each needs
  (what data per probe and per chunk, how many operations).
- **Q6, base 65** (two-word masks; `cpu.rs` is generic): Q0 and Q2 on two slices, to see whether the picture
  differs where the wide path runs.

**The decision rule I have written down in advance:** if the best exact variant cuts the main kernel's work
(lane slots × ORs per slot) by less than ×1.3 against today's order and skip, the line is closed and your table
is the measured ceiling; at ×1.3 or more it gets a kernel prototype. Report what you find, not what would be
nice to find; a clear "no" with numbers is a full result. If the instrument shows something I did not ask
about that matters more (for example that most kept visits yield no record), measure it and say so.

## A small rote job first, in the background on the same box

The CPU reference's mutation test (27 mutants; script `~/projects/nice/scratchpad/2026-10-research-program/G2/build7p/box/mut2.py`,
results of the first run in `G2/PR12-NOTES.md` §6) was run on a cut branch; rerun it on `dev/mo-clean`
`c2152084` (line numbers will have moved: the script remaps by text) and report the table: which mutants
survive. Expected: the same three. Give it one clone and target directory of its own and let it run while you
build the instrument.

## Machines and rules

- **ivory**: reading, git and notes only; do not build here (4 cores, 4.5 GB of disk free).
- **One rented box, which I rented and logged in to for you:** the ssh line is at the end of this brief. CPU
  work only. Install the Rust toolchain the repository pins; clone from
  `https://github.com/wasabipesto-bot/nice.git`. Nothing here needs a client binary; do not run one, and never
  contact the production API. Never create or destroy instances; never use another machine. Leave the box
  idle at the end.
- Branch `exp/mo-ceiling`: ordinary commits (never amend, rebase or force), trailer exactly
  `Co-Authored-By: Claude Fable 5.2 <noreply@anthropic.com>`; bundle to ivory and `git push -u fork
  exp/mo-ceiling` from ivory as the archive. No pull request; nothing to upstream.
- Long runs under `nohup` with logs, polled; foreground `sleep` on ivory is blocked (wait with a background
  `until …; do sleep N; done` loop).

## Deliverables (by 11:35 UTC)

1. `CEIL/RESULTS.md` (under `~/projects/nice/scratchpad/2026-10-research-program/`): the tables for Q0–Q6, each
   number marked measured (with the command and raw file) or derived; the exactness evidence for Q2; the
   verdict against the decision rule; what you would build first if anything, and what you could not finish.
2. Raw output under `CEIL/raw/`, scripts under `CEIL/box/`.
3. The mutant table (a short section of `CEIL/RESULTS.md`).
4. A final report to me of at most 25 lines.

## The box

    ssh -p 20230 root@ssh4.vast.ai

Vast instance 61586715: 20 threads of a Xeon E5-2630 v4 (a quota of about 19 CPUs), **15 GB of memory and
13 GB of disk** (keep to two clones and two target directories, release builds of `nice_common` only, and
watch `df -h /`; a base-64 slice's lists fit in memory one slice at a time, so do not run several slices in
parallel without checking `free -g`), a fresh Ubuntu image. It has an RTX 3060 that you do not need. ivory's ssh
key is accepted; I logged in at 05:59 UTC. It destroys itself at about 12:00 UTC.
