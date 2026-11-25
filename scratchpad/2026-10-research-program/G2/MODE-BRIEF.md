# The `midout` mode of the client, against the proposed endpoints (brief, 2026-11-25 06:00 UTC)

You are a Rust engineer. Work alone (do not start subagents), on this machine (ivory) and the fork's CI only.
**Hard stop 10:30 UTC** (check `date -u`): whatever is not done by then is reported as not done, with the
branch left in a state that compiles and passes what it passed before.

## Why, in the maintainer's words (2026-11-25)

The project ("nice": a distributed exhaustive search; Rust client `nice_client`, an API server, Postgres;
`~/projects/nice`, upstream = remote `origin`, our fork = remote `fork`) has a redesigned GPU search join, the
**middle-out join**, on the fork branch `dev/mo-clean` (head `66305ada`, worktree
`~/projects/nice/.worktrees/midout-clean`; design in `~/projects/nice/scratchpad/2026-11-midout-design/DESIGN.md`).
Today a client reaches it only through a hidden development flag, `--midout-coordinator URL`, served by a local
Python coordinator (`scripts/midout_coordinator.py`). The maintainer has now decided how it becomes real:

- *"The new mode would sit alongside detailed and niceonly, with a new claim endpoint on the server. Not hidden
  from --help."*
- *"This will be option B. This does not have the same semantics as the previous fields so it will not go in
  that table."* (a new table and new endpoints on the server)
- the name: *"That is fine, `middle-out` / `MiddleOut` / `midout`"* (prose / Rust type / command line and wire)
- on a guard in the ordinary client: *"There should be no issue here. Detailed claims are capped and niceonly
  will not be dispensed past b62. A client will have to use midout mode to get fields b64+."*
- tests: *"Same as current testing strategy. Cover as much as feasible in lavapipe and check against CPU results.
  Key PRs and releases get full test coverage on owned or rented cards."*
- the benchmark example (`common/examples/midout_bench.rs`): *"Build it, this will be part of the final
  package."*
- the field definition: *"I'd avoid locking this in until we are closer to merging."* (the coordinate stays a
  parameter that arrives in the claim; nothing may assume digits 5–7)
- *"do not open PRs for this work until I have gone through the design."*

The server side is a written proposal that the maintainer has **not yet approved**:
`~/projects/nice/scratchpad/2026-10-research-program/G2/PROPOSAL-B.md` (read §3 "Endpoints" in full: the
claim and submit shapes, the status codes, the eight checks, the reply statuses). **No server code is written
before their yes.** Your job is the client half and a development server for it, so that when they approve
(or change) the shapes, the client follows with small edits.

## The job

On a new branch **`dev/mo-mode`** from `dev/mo-clean` `66305ada` (worktree `~/projects/nice/.worktrees/mo-mode`;
a cargo target directory inside the worktree, removed at the end):

1. **The mode.** `nice_client midout` beside `detailed` and `niceonly`, shown in `--help` with a one-line
   description in the style of the other two. The hidden `--midout-coordinator` flag goes away; the mode uses
   `--api-base` like every other mode (so a development coordinator is reached with
   `--api-base http://127.0.0.1:PORT`), `--repeat`, `--username`, `--gpu*`, `--threads` (the sampled CPU check),
   `--api-max-retries`, `--telemetry` as far as each applies. Decide and document what the mode does with the
   options that do not apply (`--validate`, `--benchmark*`, `--prefetch-*`, no `--gpu`): a refusal with one clear
   sentence is right wherever the alternative is silent surprise (the join has no usable CPU form for a real
   field: `midout` without a GPU backend must refuse, not crawl). Keep every existing guard of the route
   (`client/src/midout_route.rs`, its module comment lists them: Metal refused, unknown coordinate refused,
   accounts and the sampled CPU check, the panic hook) **except** the refusal of the production address, which
   the mode no longer needs: a server without the endpoint answers 404, and the client must turn that into one
   clear error ("this server does not offer middle-out fields"), not a retry loop.
   - **Do not add a variant to the shared `nice_common::SearchMode`** today: it is stored in the database and
     matched by server code (`api/`, `common/src/db_util/`, `common/src/consensus.rs`), and no server-side file
     may change before the proposal is approved. Give the command line its own mode type in the client
     (`detailed` / `niceonly` / `midout`) that maps to `SearchMode` for the two existing modes; say in the notes
     where the two types would merge once the server change is approved. **No file under `api/`, `jobs/`,
     `schema/`, `web/` or `common/src/db_util/` changes.**
2. **The wire, exactly as the proposal has it** (`common/src/midout/wire.rs` is where it is named):
   `GET /claim/midout` (200 with the claim, 204 nothing claimable, 503 unavailable), `POST /submit/midout`
   with the typed body of §3 (big integers as decimal strings; `field`, `nice_numbers`, `shape`, `survivors`,
   `checked`, `slices`, `telemetry`), reply `{"submission_id": N, "status": "canon" | "check" |
   "already_recorded"}`. The client: retries what is retryable (network errors, 5xx) with the existing backoff
   and `--api-max-retries`; treats `already_recorded` as success; treats 409 and 422 as errors that stop it with
   the server's message (they mean this client and the server disagree about a field); under `--repeat`, a 204
   waits and asks again (choose the wait in line with what the existing modes do when the server has nothing;
   without `--repeat` it says so and exits 0). Types with serde tests against the proposal's two JSON examples
   verbatim.
3. **The card must not wait on HTTP.** A base-64 field takes about 18 s on the fastest card in the fleet, so a
   claim and a submit in series on the search thread idle the card for 1–2 % of the time. Claim the next field
   while the current one is searched and submit in the background, with at most one field held ahead (a claim
   expires after an hour on the server) and with the rule the route has today kept intact: after a failed
   search, a failed account or a recorded panic, **nothing more is submitted** and the process exits non-zero;
   a submission still in flight at exit is finished or reported, never dropped silently. If this cannot be done
   well in the time, keep the serial loop and say so: correctness of the stop rule comes first.
4. **The development server.** `scripts/midout_coordinator.py` serves the same two paths, shapes and status
   codes, with the proposal's checks as far as a Python script reasonably can (all eight are feasible: Python
   integers do the niceness check and the field membership; port the coordinate arithmetic from
   `common/src/midout/coord.rs` only as far as needed and test it against values printed by the Rust), claims
   that expire and are reissued after a duration (default one hour, settable), and the three reply statuses.
   It stays a development tool: say so in its header. `scripts/midout_audit.py` keeps working on its state
   directory. The fault harness of 2026-11-24
   (`~/projects/nice/scratchpad/2026-10-research-program/COORD/harness/`, `run_all.sh`; results and the
   invariants S1–S7, H1–H6, E1–E2 in `COORD/RESULTS.md`) must pass again after your change: adapt its fake
   clients to the new shapes and run it (at least 500 randomized runs; all of it if time allows) at low
   priority. A regression there is a finding, not something to tune away.
5. **Tests, the project's way.** Unit tests for everything pure (the mode parsing and the refusals, the wire
   types, the reply handling, the stop rule with a stand-in search). **One end-to-end test that needs no card:**
   the real client loop against the real coordinator script on 127.0.0.1, with the search either on lavapipe
   at a size lavapipe can do (see the tier table in `common/src/midout/mod.rs` and
   `G2/CLEAN-NOTES.md` §M1 in the research directory for what tier (b) runs and how lavapipe is invoked on this
   machine: a container `lvp26`) or, if no real field is small enough for lavapipe, with the loop generic over
   the search so that the test drives it with the CPU reference on a small base. It must cover: a normal run
   to "nothing left"; a lost reply (the same submission twice → `already_recorded`); a 422; a search error →
   nothing submitted, non-zero exit. `scripts/midout_audit.py` on the coordinator's state must exit 0 after
   the normal run.
6. **The benchmark examples** (`common/examples/midout_bench.rs`, `midout_wide_bench.rs`, `midout_fields.rs`,
   feature `midout-bench`): the maintainer wants them in the final package. Read them as a stranger would and
   bring them to that standard without changing what they measure: a header that says what each is for and how
   to run it, `--help`/usage for every argument, the output's units named (fs per admissible n and what
   "admissible" means), no dead switches, a refusal with a reason on wrong input. If `midout_wide_bench.rs` and
   `midout_bench.rs` can become one example with the base as an argument at no risk, say so in the notes but do
   **not** merge them today (their numbers are the record of five measurement sessions). Mention the examples
   in the module docs where a reader would look.
7. **Docs in the branch:** the README's usage section gains the mode in the same few lines the other modes
   have (state plainly that it needs a server that offers middle-out fields and a GPU); the `midout` module
   docs and `wire.rs` header describe the new wire, not the old one. No CHANGELOG entry (nothing is being
   opened).

## Rules (all binding)

- **Never contact the production API** (`api.nicenumbers.net`, anything under `nicenumbers.net`), from any
  binary or script, for any reason. Every client run, test and script of yours talks to 127.0.0.1 only; give
  every client invocation an explicit `--api-base http://127.0.0.1:PORT`. If a test would otherwise fall back
  to the default address, that is a defect in the test.
- Never touch upstream: no push to `origin`, no pull request, no issue, no comment anywhere. Pushes go to
  `fork` only, to `dev/mo-mode` (and a throwaway `ci/...` branch if you need the fork's CI); never force-push,
  never amend a pushed commit, never delete a branch. Commit in small, named steps; every commit message ends
  with the trailer `Co-Authored-By: Claude Fable 5.2 <noreply@anthropic.com>` and names no assistant, agent
  or research program anywhere else (messages, comments, docs).
- This machine has 4 cores and other work running: every build and test under `nice -n 19`, `-j 2`, one cargo
  process at a time. `/tmp` is a 3.8 GB tmpfs: do not build there. Check `df -h /` before the first build and
  whenever a build fails oddly; **stop building and report if less than 5 GB is free.** The repository pins its
  toolchain; lint only with `just lint` (the feature sets it runs are the bar).
- Whether the fork's CI runs on a pushed branch: look (`gh run list -R wasabipesto-bot/nice --branch <b>`);
  earlier work used a temporary push-triggered workflow on a side branch. Use it if local builds are too slow
  for the feature sets `just lint` needs; say which results come from where.
- Kill only processes you started, by recorded PID. **Never `pkill -f` / `pgrep -f`.** Coordinator instances
  you start are stopped at the end and their ports and state directories (under your scratch directory,
  `~/projects/nice/scratchpad/2026-10-research-program/G2/mode/`) listed in the notes.
- The proposal's shapes are the contract. Where the proposal is ambiguous or you think it is wrong (a missing
  field, a status that cannot be told apart, a number that does not fit a JSON number), **do not improvise
  silently**: choose the reading that is easiest to change, and list every such point in the notes under
  "Questions the proposal must answer", because the maintainer will read the proposal next.
- If the tooling denies something, do not work around it: note it and report it.

## Deliverables (by 10:30 UTC)

1. Branch `dev/mo-mode` on the fork, every commit compiling; `just lint` clean (say where it ran) and the test
   tiers (a) and (b) passing as they did at `66305ada` (say what ran where, and what did not run).
2. `~/projects/nice/scratchpad/2026-10-research-program/G2/MODE-NOTES.md`: what the mode does option by option
   (a table: option, behaviour in `midout`, why); the wire as built with one real exchange captured from the
   end-to-end test; what was tested and how; what was not; the harness result; "Questions the proposal must
   answer"; where the client-side mode type and `SearchMode` should merge later; anything in the existing route
   you found wrong while moving it.
3. A final report to me of at most 25 lines: head commit, what works end to end, what is not done, the
   questions for the proposal, and anything I must check before telling the maintainer the mode exists.
