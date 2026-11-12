# T2.3 brief: a sampled exact re-verification of nice-only submissions, by device and build (2026-11-12)

You are an engineer on the nice research program (repo `~/projects/nice` on this machine, ivory;
upstream `wasabipesto/nice`, fork `wasabipesto-bot/nice`). The project searches for a second
"nice number" (n whose square and cube together use every base-b digit once). Read first:
`../README.md` (rails), the module docs of `common/src/overlap_join.rs`, and in
`../../2026-11-fresh-eyes/`: `NOTES.md` §5, `census_apple.py`, `census_summary.py`,
`verify_m4_list.py`, `demoux_history.py` (how the public API is queried, lightly).

## Why

A nice-only result is one submission per field: nothing cross-checks it. On 2026-11-10 we found
that one device class (an Apple M4, client builds before a race fix) had silently dropped
2–4 in 10,000 of the candidates it should have checked, across 8,369 fields of bases 58 and 60;
it was found only because some fields had been searched twice and the two submissions'
telemetry counts differed. Those fields were re-searched. **Question for you: is any other
(device, build) cell wrong, in bases 58 and 60, and with what confidence can we say it is not?**
A clean answer is part of what the project wants most after a find: a verified "none below
base 62".

## What makes an exact check possible

Each join-route submission's telemetry carries two exact counters,
`telemetry.pipeline.join.survivors` (pairs that pass the digit-overlap test) and
`telemetry.pipeline.join.checked` (pairs that reach the full check), plus `build_sha`,
`hardware.gpu_model`, `client_version`, `pipeline.route`. For a given field and build the two
counters are deterministic and do not depend on the device: an RX 9070 XT on wgpu and an RTX 3080
on CUDA give identical counts on the same build (measured 2026-11-11 and 11-12, several fields).
So: **re-run a random sample of each cell's fields with the same build on a reference card and
compare both counters exactly.** A mismatch is a finding.

Do not assume the counters mean the same thing across builds (kernels changed what they
count more than once): compare only same build to same build. Where the exact build will not
build or run on the box, say so and fall back to the nearest build whose counters you can show
equal the original's on that cell's other fields; mark such cells clearly.

## Tasks

1. **Census (ivory, public API only).** All nice-only submissions of bases 58 and 60 that are
   not disqualified: for each, field id, range, build_sha, client_version, gpu_model, username,
   route, survivors, checked. Group into cells (gpu_model family × build_sha); give each cell's
   share of the base's range. b60's fields are ids 206902034..207064109 (1e16 each); find b58's
   the same way the scripts do. Include the fields the fleet and demoux re-searched after the
   M4 disqualification (they are ordinary submissions now).
2. **Sample.** A seeded random sample per cell, larger for larger cells (aim: with zero
   mismatches, a 95 % upper bound on a cell's per-field error rate of ≤ 5 % for cells over 1 %
   of a base and ≤ 2 % for the three largest), spread over each cell's time span. Write the
   sample list before running anything.
3. **Re-run on the box** with the cell's own build and compare both counters exactly. Choose the
   mechanism after reading the client and the tests; two that should work: (a) the test
   harness that runs a list of fields and prints per-field counts (`NICE_TEST_JOIN_LIST`, on
   fork `exp/b64-profile` 44eee52; `../N13/raw/scripts/patch_harness.py` ports it to another
   tree), or (b) the real client of that build pointed at a small local stub of the claim and
   submit endpoints that hands out the sampled fields and records what the client would have
   submitted. Whatever you choose, show first that it reproduces the original counters exactly
   on a cell that is already known good (current main on demoux's fields).
4. **Report** per cell: fields in the base, sampled, matched, mismatched, the bound; every
   mismatch with both sets of counters and what you could find out about it (does it repeat on
   a second run? is it a deficit, which loses candidates, or an excess?). Then the bottom line
   for each base: what share of the range lies in cells verified clean at the stated bound,
   what share could not be checked and why.

## The box

Rent nothing yourself: the director gives you the instance id in the message that carries this
brief. `python3 vast.py ssh <id>` (from `~/projects/nice/scratchpad/2026-10-research-program`)
prints the ssh command; wait for `/root/READY` (`/root/FAILED` means the start-up clone failed:
clone the fork yourself). CUDA builds: `--features gpu,cubecl-cuda`. Keep one target directory
per build (`CARGO_TARGET_DIR`), since same-version trees share cargo's artifact slots otherwise;
watch the 32 GB disk and delete a build's target directory when its cell is done.

## Hard rules

- **Nothing may ever be submitted to, or claimed from, the production server.** Before any
  client binary runs on the box, make the production API unreachable there (map
  `api.nicenumbers.net` and `data.nicenumbers.net` to 127.0.0.1 in the box's `/etc/hosts`; find
  any other host the client knows in its source), prove it with a failing `curl`, log the proof
  in your results, and always pass the client an explicit local API address. The census runs
  from ivory, never from the box. If you cannot be sure a binary will not reach the server, do
  not run it: use the test harness instead.
- Public API (`https://data.nicenumbers.net`, PostgREST, read-only): only primary-key, `field_id`
  or bounded id-range queries (≤ 100,000 ids a request, ≥ 0.15 s between requests,
  `User-Agent: nice-audit-census`). No ordered or unbounded scans: they time out and load a
  database that has had outages from exactly that.
- Never touch the live fleet, `~/fleet-run`, the server, demoux or mayalaran. Never run
  `vast.py create` or `destroy`.
- ivory writes only under `T2/` in the program directory and, if needed, one worktree
  `~/projects/nice/.worktrees/t2-audit`; no GPU builds on ivory (7.5 GB free; `/tmp` is a small
  tmpfs). Push nothing unless you need a branch on the box, then only a new branch name on the
  fork; never force-push or delete a branch; no PRs; no subagents.
- If a mismatch appears, do not "fix" or re-queue anything: document it. Data corrections are
  the user's decision.

## Deliver

`T2/AUDIT.md` (the census table, the sample design, the mechanism and its validation, the
per-cell table, every mismatch, the bottom line per base, what could not be checked), scripts
and raw outputs under `T2/raw/`. Mark every number measured, derived or assumed. Copy results to
ivory as you go: the box disappears at its TTL. Hard stop **21:30 UTC**; your final message is
a short report for the program's director.
