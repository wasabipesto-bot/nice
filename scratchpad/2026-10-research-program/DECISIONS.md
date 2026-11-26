# Open decisions for the maintainer (kept current; last updated 2026-11-26 08:20 UTC)

Only what is still open is here. What you have already decided, with your words and what I did about each, is
in `DECIDED.md` beside this file. To answer, write a note under an entry as you did on 2026-11-25 (a line
starting with `%%`), or reply in the chat.

Paths are relative to `~/projects/nice/scratchpad/2026-10-research-program/`.

## 0. Where things stand, in ten lines

- **The middle-out join** (the redesigned nice-only GPU join): built, cleaned, exact on your RX 9070 XT at the
  cleaned head, and measured there on 2026-11-25 at ×4.5 against v3.4.8's join at base 64 (×4.7 by the
  protocol of 11-19, when it was ×4.8; it runs 6–10 % slower while the desktop is in use, which production's
  join does not). ×4.1 on an RTX 3080 and on your RTX 3060; ×3.9 on the M4 through Metal, where it ran for
  the first time on 2026-11-26 and is exact. Branch `dev/mo-clean` on the fork. **No pull request from it until you
  have gone through the design** (`../2026-11-midout-design/DESIGN.md`).
- **Your direction for it (2026-11-25):** a `midout` mode beside `detailed` and `niceonly`, visible in `--help`,
  with a new claim endpoint and its own table on the server; the field definition not locked in yet. **The
  client half exists since 2026-11-25** on the fork branch `dev/mo-mode` (`nice_client midout`, tested end to
  end against a development server; notes in `G2/MODE-NOTES.md`); the server half is the proposal of §1.
- **Pull requests in general are allowed.** Open now: #276 (the crash at bases with no valid residue), #277
  (a `--gpu` client that finds only a software renderer), #278 (the CI check for the SPIR-V atomic-store trap).
- **demoux:** the window of 2026-11-25 ended at 05:53 UTC, well inside the lease; nothing of mine is on the
  machine (`G2/WINDOW3-RESULTS.md`, cleanup proof at the end).
- **Machines (your message of 2026-11-26):** eventeo and mayalaran are set up and in use (`README.md`,
  "Machines"); eventeo is powered off after every job. The rented-card cap in the wrapper is $10 a month from
  2026-11-26; demoux is still asked for each time.

## 1. The server side of the `midout` mode: a proposal to approve or correct

- **What it is:** the written proposal you asked for by choosing "option B": the new tables, the claim and
  submit endpoints, what the database pays, the rollout, tests: `G2/PROPOSAL-B.md`. It contains its own short
  list of sub-decisions (§7: field size per row, how fields are inserted, double-checking, credit) and, since
  the client was built against it, seven questions about the wire with a recommendation and a default each
  (§9: big integers as strings, one shape per base, error bodies, whether a check reports disagreement, what a
  client does on a 503).
- **Why now:** base 62 ends in late December; base 64 on the new join needs this on the server before then, or
  base 64 starts on the old join (about 266 days on your RX 9070 XT against about 55–60).
- **What I do meanwhile, without a yes:** nothing on the server. The client mode on the fork branch speaks
  the endpoint shapes of the proposal, with a development server for the same shapes so it can be tested; if
  you change the shapes, the client follows.
- **If you do not answer:** the client mode stays on the branch with the defaults of §7 and §9; no server
  code is written.

## 2. What should Lean (or a long mathematical effort) be pointed at?

- **Your note:** formalising what we already believe is low-value; you would rather see a falsifiable statement
  of very high value posed and then proved or refuted.
- **My honest reading: I do not have a statement of that kind that I think is reachable.** The candidates:
  - **a. "A second nice number exists."** The prize, and almost surely true (the expected count passes 1 near
    base 131). I know no route. Finding one needs a method that fixes about 90 % of the output digits before
    gambling; every certificate there is fixes 40 %. Structured candidates (n with periodic or patterned
    digits, roots of patterned squares and cubes) were tested on 2026-11-25 across bases 17–329
    (`EXPERIMENTS.md` CX.2). One real effect: n with periodic digits have squares with no repeated digit at
    all (122 distinct of 122 at base 305), but the cube does not follow, and the best structured n at bases
    100–160 still misses 22 % of the digits (random n miss 37 %). A proof by counting would need the joint
    distribution of all digits of n² and n³; what is known covers single digits.
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
- **The proposal, one page: `T2/VALIDATION-PROPOSAL.md`.** In short: `niceonly --validate` stops being
  refused and runs a few fixed fields whose two counts (join survivors, candidates checked) were computed on
  a CPU and are compiled into the client; a device that drops candidates fails by its counts. No server
  change, about 150 lines, one pull request.
- **If you do not answer:** nothing is built.

## 4. Base 65 matters more than I said: an hour of demoux for it, and which base goes first

- **What changed (2026-11-26, `EXPERIMENTS.md` YIELD.1, table in `YIELD/yield.txt`):** I priced each base by
  expected nice numbers per unit of search work under the new join. Base 65 has about the same amount of work
  as base 64 (only one residue class in 64 can hold a nice number there) and 2.7 times its expected count.
  The base after it, 68, costs 12 times more per unit of probability, so **bases 64 and 65 are the whole
  realistic horizon, and base 65 is 73 % of it, in probability and in machine time** (about 150 days of your
  RX 9070 XT at the speed measured on 2026-11-19, against 56 for base 64). I had been calling base 65 "months
  away, not urgent". That was wrong: a gain on base 65's kernel path is worth 2.7 times the same gain at
  base 64.
- **What I am doing about it:** the path that base 65 uses (the "wide" kernels) is profiled on eventeo today,
  and its known levers (a top hierarchy that tests about a fifth of today's 13.4 million top prefixes per
  slice, the shared bottom lists that base 64 already has, the prefilter's arithmetic) become the main
  optimisation work, developed on eventeo.
- **Why your card ran base 65 slowly on 2026-11-25, as far as eventeo can tell** (`EXPERIMENTS.md` B65.1,
  `B65/RESULTS.md`): not a regression (on the RTX 3060 the current branch is 10–13 % faster than the older
  build, through CUDA and through Vulkan). What reproduces it is a busy host CPU: through Vulkan, six busy
  threads make base 65 2.3 times slower with the card a quarter busy, while base 64 loses 5 %. Cause: the
  base-65 path collects its results in about 29,600 small blocking reads per field, each of which stalls when
  the CPU is contended; the base-64 path batches them. Your desktop was in use that day. The fix (batching the
  reads) is being built today on the branch `dev/mo-wide-reads`.
- **What I need from you, when convenient: one hour of demoux**, to confirm on the card itself that the fixed
  build holds base 65 near 3 fs while the desktop is in use, and to measure the next levers there. Until then
  the base-65 numbers I report are from the RTX 3060.
- **A decision for later, not now: which base is handed out first.** At today's speeds the two bases tie in
  expected yield per day; with any gain on base 65's path it goes ahead of base 64. The server proposal now
  carries this as a small question (`G2/PROPOSAL-B.md` §9, item 8: a rank per base instead of the base number).
- **If you do not answer:** I develop on eventeo, do not use demoux, and report base 65's numbers from the
  RTX 3060 only (which says what CUDA does, not what your card does).

## What happens next if you say nothing

1. #276, #277 and #278 wait for your merge.
2. The `midout` client mode on the fork branch `dev/mo-mode` is brought through the full CI matrix (three
   tests of the branch fail on 32-bit and emulated targets) and reviewed; nothing is opened from it.
3. No server code, no Lean work, no validation change, no use of demoux.
