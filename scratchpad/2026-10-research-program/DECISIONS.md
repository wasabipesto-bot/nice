# Open decisions for the maintainer (kept current; last updated 2026-11-25 08:30 UTC)

Only what is still open is here. What you have already decided, with your words and what I did about each, is
in `DECIDED.md` beside this file. To answer, write a note under an entry as you did on 2026-11-25 (a line
starting with `%%`), or reply in the chat.

Paths are relative to `~/projects/nice/scratchpad/2026-10-research-program/`.

## 0. Where things stand, in ten lines

- **The middle-out join** (the redesigned nice-only GPU join): built, cleaned, exact on your RX 9070 XT at the
  cleaned head, and measured there on 2026-11-25 at ×4.5 against v3.4.8's join at base 64 (×4.7 by the
  protocol of 11-19, when it was ×4.8; it runs 6–10 % slower while the desktop is in use, which production's
  join does not). ×4.1 on an RTX 3080. Branch `dev/mo-clean` on the fork. **No pull request from it until you
  have gone through the design** (`../2026-11-midout-design/DESIGN.md`).
- **Your direction for it (2026-11-25):** a `midout` mode beside `detailed` and `niceonly`, visible in `--help`,
  with a new claim endpoint and its own table on the server; the field definition not locked in yet. **The
  client half exists since 2026-11-25** on the fork branch `dev/mo-mode` (`nice_client midout`, tested end to
  end against a development server; notes in `G2/MODE-NOTES.md`); the server half is the proposal of §1.
- **Pull requests in general are allowed.** Open now: #276 (the crash at bases with no valid residue), #277
  (a `--gpu` client that finds only a software renderer), #278 (the CI check for the SPIR-V atomic-store trap).
- **demoux:** the window of 2026-11-25 ended at 05:53 UTC, well inside the lease; nothing of mine is on the
  machine (`G2/WINDOW3-RESULTS.md`, cleanup proof at the end).
- **Rented machines:** $30 a month, unchanged; about $0.33 is left for November under the wrapper's last-week
  reserve, so until 12-01 builds run on ivory at low priority or in the fork's CI.

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

## 4. Forty-five minutes more of demoux, some time (not urgent)

- **Why:** base 65 gave no result in the window. The wide kernel (bases 65 and up) ran at 4.8–4.9 fs per
  number with the card at half clock (1.53 GHz, 112 W); on 2026-11-19 an earlier build ran 3.02 fs at
  3.08 GHz. Either the changes since then (which gained 10 % on an RTX 3080) hurt this card, or it was the
  session (your desktop was in use, and the host's share of each field was five times what it was on 11-19).
  One run of the old build against the new one settles which, and a bisection names the commit if it is the
  code.
- **What it does not affect:** base 64 (a different kernel, measured and exact). Base 65 is months away.
- **I tried to do it inside the lease** after the main window had cleaned up; the session's tooling refused
  the set-up, nothing ran, and I did not work around it.
- **If you do not answer:** I do not use the machine. The item stays in `LEDGER.md` (W65) until a card is
  available; a rented card cannot answer it (it is specific to this card and driver).

## What happens next if you say nothing

1. #276, #277 and #278 wait for your merge.
2. The `midout` client mode on the fork branch `dev/mo-mode` is brought through the full CI matrix (three
   tests of the branch fail on 32-bit and emulated targets) and reviewed; nothing is opened from it.
3. No server code, no Lean work, no validation change, no use of demoux.
