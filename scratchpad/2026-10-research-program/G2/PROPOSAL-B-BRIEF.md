# A proposal for the server side of the middle-out mode, as the maintainer chose it (brief, 2026-11-25 04:10 UTC)

You are a backend engineer who writes proposals a busy maintainer can approve or correct in one reading. Work
alone (do not start subagents), on this machine only (ivory), **reading only: no builds, no code changes, no
database access, no pushes, no contact with the production API or server.** **Hard stop 07:00 UTC.** The
deliverable is a proposal document, not code.

## What has been decided (the maintainer's own words, written on 2026-11-25)

The "nice" project searches bases exhaustively for numbers with a rare digit property, with a client
(`client/`) and a server (`api/`, `common/src/db_util/`, `schema/`, `jobs/`). A redesigned GPU search join, the
**middle-out join**, exists on a fork branch and needs work units ("fields") that are not ranges of n: a field
is a range of a per-base renumbered coordinate v (every n sharing three middle digits). I gave the maintainer
three server options (`G2/PROPOSAL.md` in this directory tree: read it first, especially §3). Their answers:

- On the client: *"The new mode would sit alongside detailed and niceonly, with a new claim endpoint on the
  server. Not hidden from --help."*
- On the server: *"This will be option B. This does not have the same semantics as the previous fields so it
  will not go in that table."*
- On old clients: *"There should be no issue here. Detailed claims are capped and niceonly will not be
  dispensed past b62. A client will have to use midout mode to get fields b64+."*
- On the field definition: *"I'd avoid locking this in until we are closer to merging."*
- On names: `middle-out` / `MiddleOut` / `midout`.
- On tests: *"Same as current testing strategy. Cover as much as feasible in lavapipe and check against CPU
  results. Key PRs and releases get full test coverage on owned or rented cards."*

Standing rules of this maintainer for server work: a server or schema change gets a written proposal and
their explicit yes before any code beyond a throwaway prototype; migrations always get a proposal; they do
not want a rearchitecture; the server already suffers when scheduled jobs scan large tables (an outage
investigation found database disk starvation from scheduled scans), so anything new must say what it costs
the database.

## What to read (all on ivory)

- The server and its data model at upstream main (`~/projects/nice`, branch state `origin/main`; use
  `git show origin/main:<path>` or a temporary `git worktree add --detach ~/projects/nice/.worktrees/propb-read
  origin/main`, removed at the end): `schema/` (tables, views, migrations as the project keeps them),
  `api/src/main.rs`, `api/src/field_queue.rs`, `common/src/db_util/{bases,chunks,fields,claims,submissions,
  cache,job_state}.rs`, `jobs/`, `scripts/insert_new_fields.rs`, the client's claim and submit code
  (`common/src/client_api_async.rs`, `client/src/main.rs`), the public data API's shape as the web front end
  uses it (`web/`), and `CHANGELOG.md` for how claim queues and check levels evolved.
- The middle-out side on the fork branch `dev/mo-clean` (worktree `~/projects/nice/.worktrees/midout-clean`):
  `common/src/midout/coord.rs` (the coordinate: what a field is, quanta, `n_count`), `wire.rs` (today's claim
  key `"coordinate": "midout:K0,K1,Q0"`), `route.rs`, `client/src/midout_route.rs`, and the development
  coordinator `scripts/midout_coordinator.py` with its failure analysis
  `~/projects/nice/scratchpad/2026-10-research-program/COORD/RESULTS.md` (nine defects found in a 164-line
  coordinator: the invariants there are the ones a server implementation must also keep).
- The design for the maintainer: `~/projects/nice/scratchpad/2026-11-midout-design/DESIGN.md` §3 (what a field
  commits the project to) and §4.

## What the proposal must contain (`G2/PROPOSAL-B.md`, at most 300 lines, plain language)

1. **Half a page first:** what is added, what is untouched, what it costs, what the maintainer must decide.
2. **The data model:** the new table or tables as DDL the project's style would write (names, columns, types,
   keys, indexes, constraints), with one paragraph per table on why each column exists. At least: what
   identifies a field (base, coordinate digits, start and size in v; keep the coordinate a property of the
   row or of the base so the field definition is **not locked in**: say exactly what changing it later would
   take, per the maintainer's wish), its state (unclaimed, claimed, searched, double-checked: map to or depart
   from today's `check_level`, and say why), the claim and submission records, the result (nice numbers,
   counters, telemetry, client version, user), and how many rows base 64 and base 65 mean (262,144 fields per
   base at the current definition; say what a different quantum would change). Nothing in existing tables
   changes unless you show it must.
3. **The endpoints:** the claim endpoint and the submit path for the new mode (paths, request and response
   bodies as JSON examples, status codes, idempotency, what a duplicate or late submission gets, claim expiry
   and reissue, how the server validates a submission against its claim: the coordinator analysis shows what
   goes wrong without each check), and how the client's new mode (`nice_client midout`, beside `detailed` and
   `niceonly`) uses them. Whether double-checking exists for this mode from the start, and how a disagreement
   between two submissions for one field is recorded.
4. **What the database pays:** the queries each endpoint runs with their index use, the claim queue (the
   existing nice-only queue pre-claims fields and has had a duplicate-issue defect and a runaway query: say
   how the new mode avoids both), what the scheduled jobs and caches (`jobs/`, `cache.rs`, the hourly refresh)
   would have to compute for the new tables and at what cost, and what the public data API and the web front
   end need to show a base searched this way (progress, nice numbers, per-user credit) with the fewest new
   views.
5. **Rollout:** additive migration only; the order (schema, server endpoints behind nothing a current client
   calls, client mode, inserting base 64's fields, the first claims from the maintainer's own machine);
   what is reversible at each step; how base 62's remaining nice-only work and base 64's first fields coexist;
   how results searched before the server existed (if any are ever made with the development coordinator)
   could be backfilled, or a statement that they should not be.
6. **Tests** in the project's existing style for server code, and what cannot be tested without the real
   database.
7. **Open sub-decisions**, each with options, your recommendation and what happens by default, kept few:
   for example field size (one quantum per row, or coarser rows), whether fields are inserted per base by a
   script or generated on demand, the double-check policy, credit accounting.
8. **What you could not determine** by reading.

Every claim about existing code carries its file and line. Do not design beyond what the maintainer decided;
where their words leave something open, list it under 7 instead of choosing silently. No reference in the
document to agents, models, notes or internal names: it will be read by the maintainer as it stands.

## Deliverable (by 07:00 UTC)

`~/projects/nice/scratchpad/2026-10-research-program/G2/PROPOSAL-B.md`, then a report to me of at most 15 lines:
the tables and endpoints in one line each, the database cost in two lines, the open sub-decisions, and what
you could not determine. Remove any worktree you added. If the tooling denies something, do not work around
it: note it.
