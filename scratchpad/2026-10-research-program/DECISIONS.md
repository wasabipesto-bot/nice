# Open decisions for the maintainer (kept current; last updated 2026-11-28 06:00 UTC)

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
- **Pull requests in general are allowed.** Open now, all green and mergeable: #276 (the crash at bases with
  no valid residue), #277 (a `--gpu` client that finds only a software renderer), #278 (the CI check for the
  SPIR-V atomic-store trap), #279 (`just lint` fails on machines that are not x86-64, your M4 among them).
- **A correction (2026-11-28, §4):** on 2026-11-26 I told you base 65 held 73 % of the reachable odds. Wrong:
  base 64 holds 73 %, base 65 27 %.
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
  - **a. "A second nice number exists."** The prize, and almost surely true (by your published model the
    running total of expected nice numbers passes 1 between bases 110 and 120). I know no route. Finding one needs a method that fixes about 90 % of the output digits before
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

## 4. An hour of demoux when convenient; and a correction: base 64, not base 65, holds most of the odds

- **The correction (2026-11-28; `EXPERIMENTS.md` YIELD.2, table in `YIELD/yield2.txt`).** On 2026-11-26 I wrote
  here that base 65 was 73 % of the reachable probability and might be handed out before base 64. That was
  wrong. My table left out the residue factor R_b that your published model has
  (`../2026-08-cost-probability/METHODOLOGY.md` §2: eight admissible residue classes at base 64, one at base
  65). With your model:

  | | base 64 | base 65 |
  |---|---|---|
  | numbers to search (admissible n) | 4.80e21 | 4.34e21 |
  | expected nice numbers (λ) | 8.5e-4 | 3.2e-4 |
  | share of the odds within reach | **73 %** | 27 % |
  | days of your RX 9070 XT at measured speeds | about 56 | about 150 |
  | odds per day of that card | 1.5e-5 | 2.1e-6 |

  Base 64 goes first on every card (7.3 times base 65's odds per day on your card, 4.5 times on an RTX 3060);
  the question about base order that I had added to the server proposal is withdrawn. Bases 64 and 65 are
  still the whole realistic horizon: base 68 costs 19 times more per unit of odds than base 65.
- **What it changes in my work:** base 64's path comes first again. Its one known open loss is the 6–10 % it
  ran slower on your card while the desktop was in use (2026-11-25). The base-65 work of the last three days
  keeps its measured gains (about 11 % of base 65's 150 days, and base 65 is still 73 % of the time to finish
  both bases), but I had ranked it above base 64 on a wrong number.
- **What I ask, when convenient: one hour of demoux.** First for base 64: the same field at group sizes 16,
  64 and 256 with the desktop in use and the card's clock logged; it tells whether that 6–10 % is the pause
  between groups of slices, which can be closed (`B65/AHEAD-DESIGN.md`; the same sweep runs on eventeo today).
  Then base 65 at the current head, to confirm on the card that the read fix of 2026-11-26 holds it near 3 fs.
- **If you do not answer:** I develop on eventeo, do not use demoux, and report numbers from the RTX 3060 only.

## What happens next if you say nothing

1. #276, #277, #278 and #279 wait for your merge.
2. Work on the middle-out join continues on the fork branch `dev/mo-mode` (base 64's path first, then base
   65's); nothing is opened from it.
3. No server code, no Lean work, no validation change, no use of demoux.
