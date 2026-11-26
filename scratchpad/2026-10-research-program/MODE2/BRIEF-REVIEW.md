# Independent review of the `midout` client mode and its development server (brief, 2026-11-26 06:05 UTC)

You are an independent reviewer. You did not write this code. Work alone (do not start subagents), on this
machine (ivory), **reading only: change nothing, build nothing heavy, push nothing, comment nowhere.**
**Hard stop 08:30 UTC.**

## What you review

The "nice" project is a distributed exhaustive search (Rust client, API server, Postgres). On the fork branch
`dev/mo-mode` (worktree `~/projects/nice/.worktrees/mo-mode`; review the nine commits
`git log 66305ada..f61cf79e`, i.e. `git diff 66305ada f61cf79e`) a new client mode `nice_client midout` was added
yesterday, with a development server in Python for testing it. Its author's notes:
`~/projects/nice/scratchpad/2026-10-research-program/G2/MODE-NOTES.md`; the brief it was built to:
`…/G2/MODE-BRIEF.md`; the server-side proposal whose wire it speaks (not yet approved by the maintainer):
`…/G2/PROPOSAL-B.md` §3 and §9. A search result here is a statement that a range holds no solution, so **the one
unforgivable failure is recording a field as searched when it was not, or losing a found number**; a field
searched twice is only waste.

Files that matter: `client/src/midout_route.rs` (the loop: claim ahead, search, submit in the background, the
stop rule), `client/src/midout_route/tests.rs`, `client/src/main.rs` (the client-side `ClientMode`),
`common/src/midout/wire.rs`, `common/src/client_api_async.rs` (the two new calls), `scripts/midout_coordinator.py`,
`scripts/midout_audit.py`, and the three examples under `common/examples/`.

## What to try to break (rank findings: wrong result possible / robustness / quality)

1. **The loop's stop rule and its concurrency.** After a failed search, failed accounts, a recorded panic or a
   refused submission nothing more may be submitted, and the exit must be non-zero. With one claim held ahead and
   one submission in flight: can a result be submitted for a field other than the one searched (claim and result
   crossed)? Can a submission still in flight be dropped silently at exit, or on SIGTERM? Can a panic on another
   thread between "search done" and "submit" let a bad result through? What happens to the claim held ahead when
   the base changes, or when the server answers 204 or an error for it?
2. **Retries and identity.** A lost reply is retried with the same body and must come back `already_recorded`;
   can a retry ever carry a different body for the same claim (telemetry timestamps, a recomputed field)? Is every
   4xx and 5xx handled as the notes' table says? Is there any path that treats a non-200 as success?
3. **The wire types.** Big integers as strings: can a value be truncated or rounded anywhere (u64, f64, JSON
   numbers in the claim)? Does the client check the claim it receives (coordinate known, whole quanta,
   `range_size`) before searching, and the field it submits against the field it claimed?
4. **The development server** as the test double of the proposal: do its eight checks match the proposal's
   table, in order? Where is it weaker than the proposal (so that a client bug would pass the tests here and fail
   on the real server), and where stricter? The durability rule (fsync before acknowledging; yesterday's fix
   `a38c9f4d` for records read at start): is there another path that acknowledges before the record is safe?
5. **The tests:** do the end-to-end tests really run the production loop (not a copy)? Which of the behaviours
   above have no test? Are any tests timing-dependent in a way that will flake on CI?
6. **The option table** (notes §1): any option whose behaviour in `midout` would surprise a user of the other
   modes; any refusal that should be a warning or the reverse.
7. Anything in the nine commits that touches code outside the client mode in a way that could change the
   existing modes' behaviour (the shared `Cli`, `main.rs`, `bench.rs`, `client_api_async.rs`).

Small things you can run are fine (`python3 -I scripts/midout_coordinator.py --help`, `git grep`, a five-line
Python check of the server's arithmetic); no cargo builds (the author's CI results are in the notes §4).

## Deliverable (by 08:30 UTC)

`~/projects/nice/scratchpad/2026-10-research-program/MODE2/REVIEW.md`: a verdict in the first three lines (is it
sound to build on; the count of findings by rank), then the findings ranked, each with file and line, the
scenario, and the smallest fix you would accept; then what you read and ran; then what you could not judge by
reading. A final report to me of at most 15 lines.
