# Open decisions for the maintainer (kept current; last updated 2026-11-25 04:10 UTC)

Only what is still open is here. What you have already decided, with your words and what I did about each, is
in `DECIDED.md` beside this file. To answer, write a note under an entry as you did on 2026-11-25 (a line
starting with `%%`), or reply in the chat.

Paths are relative to `~/projects/nice/scratchpad/2026-10-research-program/`.

## 0. Where things stand, in ten lines

- **The middle-out join** (the redesigned nice-only GPU join): built, cleaned, measured ×4.1 (RTX 3080) to ×4.8
  (RX 9070 XT) against v3.4.8's join at base 64; base 65 runs too. Branch `dev/mo-clean` on the fork. **No pull
  request from it until you have gone through the design** (`../2026-11-midout-design/DESIGN.md`).
- **Your direction for it (2026-11-25):** a `midout` mode beside `detailed` and `niceonly`, visible in `--help`,
  with a new claim endpoint and its own table on the server; the field definition not locked in yet.
- **Pull requests in general are allowed.** Open now: #276 (the crash at bases with no valid residue).
- **Rented machines:** $30 a month, unchanged; about $0.33 is left for November under the wrapper's last-week
  reserve, so until 12-01 builds run on ivory at low priority or in the fork's CI.

## 1. The server side of the `midout` mode: a proposal to approve or correct

- **What it is:** the written proposal you asked for by choosing "option B": the new table, the claim and
  submit endpoints, what the database pays, the rollout, tests: `G2/PROPOSAL-B.md`. It contains its own short
  list of sub-decisions (field size per row, how fields are inserted, double-checking, credit).
- **Why now:** base 62 ends in late December; base 64 on the new join needs this on the server before then, or
  base 64 starts on the old join (about 266 days on your RX 9070 XT against about 55).
- **What I do meanwhile, without a yes:** nothing on the server. On the fork branch I turn the hidden client
  flag into the `midout` mode against the endpoint shapes of the proposal, with the development coordinator
  serving the same shapes so it can be tested; if you change the shapes, the client follows.
- **If you do not answer:** the client mode exists on the branch; no server code is written.

## 2. What should Lean (or a long mathematical effort) be pointed at?

- **Your note:** formalising what we already believe is low-value; you would rather see a falsifiable statement
  of very high value posed and then proved or refuted.
- **My honest reading: I do not have a statement of that kind that I think is reachable.** The candidates:
  - **a. "A second nice number exists."** The prize, and almost surely true (the expected count passes 1 near
    base 131). I know no route. Finding one needs a method that fixes about 90 % of the output digits before
    gambling; every certificate there is fixes 40 %. Structured candidates (rational-type n, n with patterned
    digits, roots of patterned squares and cubes) were tested on 2026-11-25 across bases 15–400: their best
    members are within about one digit of the best of equally many random numbers, and none comes within 17 %
    of a base's digits of being nice (`CX/families/`). A proof by counting would need the joint distribution of
    all digits of n² and n³; what is known covers single digits.
  - **b. "No end-certificate search can do better than the join by more than a stated factor."** A lower bound
    in a precisely defined system (every discard is a set of n on which two output digits are provably equal).
    An earlier exact computation at bases 20–33 put the join within ×1.03–1.11 of the best such search at
    realistic costs; making that a theorem for base 64 is feasible. It would settle the local-optimum question
    and nothing else.
  - **c. "The digits of n² and n³ at fixed middle positions are jointly equidistributed."** Real analytic
    number theory, the rigorous footing of the odds model for pairs of digits; not directly useful.
  - **d. Something you have in mind.** Your note read as if you might; if so, name it.
- **Recommendation:** none of a–c is worth weeks as it stands. I stop Lean work here (the finished proof stays
  on its fork branch) and put the effort into making the `midout` mode real.
- **If you do not answer:** that.

## 3. A known-answer check in validation (your note: validation, not the benchmark)

- **Background:** `niceonly --validate` is refused by the client today ("Configuration not supported"), so
  nice-only results have no validation path at all; detailed validation compares a distribution.
- **Proposal to be written (one page) unless you say otherwise:** validation for nice-only (and later
  `midout`) that compares the client's survivor and check counts for a field with values stored when the
  field was first searched, so a device that drops candidates is caught by counts, not only by a missed nice
  number.
- **If you do not answer:** I write the one page and wait.

## What happens next if you say nothing

1. #276 waits for your merge; two more small pull requests follow as they are ready (the CUDA start-up
   failure as an error with its reason logged; the CI check for the SPIR-V atomic-store trap).
2. The `midout` client mode is built on the fork branch; nothing is opened from it.
3. No Lean work.
