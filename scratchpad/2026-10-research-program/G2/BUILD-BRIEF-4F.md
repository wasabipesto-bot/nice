# The middle-out join, step 4F: a client route against a local coordinator (brief, 2026-11-19 06:05 UTC)

You are an engineer on the fourth step of a build. Work alone (do not start subagents). **Hard stop
11:30 UTC.**

## Why

The middle-out join (trunk `dev/middle-out-join`, head `4abfab5c`, worktree
`~/projects/nice/.worktrees/midout`, code in `common/src/midout/`) searches a field of the new kind exactly and
proves its work ran, but only through a library call and a benchmark example. Nothing can run it the way a
client runs work: claim a field, search it, report. The owner's conditions (read `G2/BUILD-BRIEF-1.md` first:
its decision and rules all apply) rule out any server or schema change for now, so the route to real use is
the proposal's "no server change" option: **a local coordinator that speaks the client's existing wire format
and hands out fields of the new kind**, and a client mode that works against it.

Then read `G2/BUILD-NOTES.md` (§1, §2, §10, §11), `G2/PROPOSAL.md` §2–§6 (what a field of the new kind is on
the wire; the guards against an old client or route being handed one; the no-server-change coordinator), and
`G2/AUDIT-MO.md` §9 (the client must not submit after a runtime-thread panic). Production's client:
`client/src/main.rs` and its GPU routing; the stub API the engineers have used on boxes:
`G2/build1/box/stub_api.py`.

## Your job

1. **A local coordinator** (a small script, standard library only, bound to 127.0.0.1): serves nice-only
   fields of the new kind for a base from a work list (base, coordinate-space start and size per field,
   aligned as `midout::coord` requires), in production's claim and submit wire format with the fewest additions
   needed to say "this field is in the middle-out coordinate of base B"; records every submission as a JSON
   line (field, counters, nice numbers, telemetry, client build); never hands a field out twice unless told
   to; resumable.
2. **A client mode**, explicit and off by default: with it, the client claims from the coordinator's address,
   runs `midout::gpu::search_field` (or the wide form above base 64), and submits. Guards, each with a test:
   - the mode **refuses to start against the production API** (it requires an explicit API address, and
     refuses the production host by name);
   - every other route of the client **refuses a field marked as coordinate-space** (the stride path and the
     overlap join would search the wrong numbers and call the field done);
   - a field whose accounts fail, whose sampled CPU check fails, or during which **any runtime-thread panic was
     logged**, is not submitted: the client exits non-zero with the reason (install the panic hook the audit
     asks for);
   - telemetry names the route, the join's shape and the build, and carries the counters (`survivors`,
     `checked`, slices done).
3. **End to end on the box:** the coordinator serves a list of base-64 fields (at least 20, spread over the
   base) and two base-65 fields; the client processes them with the sampled CPU check on (base 64); the
   recorded results equal `search_field`'s own for the same fields, and the sampled slices equal the CPU
   reference. A negative run for each guard (a fault switch on: nothing submitted, non-zero exit; a memory hog
   as in `G2/build2e/raw/alloc/`: nothing submitted). The client's throughput through this route against the
   library number on the same box in the same session (yesterday: 1.69 fs per admissible n at base 64 with the
   accounts, on this very host): what does the route cost?
4. **Write down for the owner**, in the notes: the exact command lines to run the coordinator and a client
   against it on one machine; what the wire additions are; what would have to change for the real server to
   do the coordinator's job (a list, no code).

The flag's name and shape are for the owner's review later: choose something plain, keep it in one place.
Nothing of this may change what the default client does.

## Machines, branch, rules

- **ivory**: reading, git and notes only; do not build here.
- **One rented box, which I rented and logged in to for you:**

      ssh -p 38876 root@ssh2.vast.ai

  Vast instance 61386517: RTX 3080 (10 GB) capped at 240 W, 16 threads visible (expect a CPU quota of about
  5), 31 GB memory, 40 GB disk, a fresh Ubuntu 24.04 CUDA 12.8 image: install the toolchain (the repo pins it),
  lavapipe if you need it, and **map the production hosts to 127.0.0.1 and ::1 with the proof saved before any
  client binary runs** (`G2/build1/box/` shows how). **Nothing ever claims from or submits to the production
  API**: the client under test talks to your coordinator on 127.0.0.1 only. It destroys itself at about
  12:45 UTC: bundle commits to ivory as you go. Leave it running and idle at the end. Never create or destroy
  instances; never use another machine.
- **Your branch is `dev/mo-client`**, created from the trunk's head, own worktree
  `~/projects/nice/.worktrees/midout-client` on ivory. Another engineer is changing the kernels in
  `common/src/midout/gpu.rs` and `gpu_wide.rs` on the trunk today: do not edit those two files; if you need
  something from the library's surface, add it in a new small file or in `mod.rs` and say so in your notes.
  Before your final report merge the trunk's current head into your branch by an ordinary merge commit and
  re-run your tests. Ordinary commits only (never amend, rebase or force); trailer exactly
  `Co-Authored-By: Claude Fable 5.2 <noreply@anthropic.com>`; bundle to ivory; `git push -u fork dev/mo-client`
  from ivory. No pull request, nothing to upstream. One target directory per worktree.
- fmt and clippy clean; production's suite passes; the default client's behaviour is unchanged (show it: the
  existing client tests, and a run of the unmodified routes against the stub).

## Deliverables (by 11:30 UTC)

1. The branch on ivory and the fork.
2. `G2/BUILD-NOTES-CLIENT.md`: where it stands; the coordinator and the client mode (command lines); the wire
   additions; every guard and its test; the end-to-end results; the route's cost; what the real server would
   need; what is not done.
3. Raw logs under `G2/build4f/`.
4. A final report to me of at most 30 lines.
