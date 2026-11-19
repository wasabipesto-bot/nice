# The middle-out join: a plan of stacked pull requests (2026-11-19)

Companion to `G2/MAINTAINABILITY.md` (the findings M1–M7 and S1–S9 cited below). Branch `dev/middle-out-join` at
`66259bb0`, 13,300 lines over `origin/main`. Written for a maintainer who has read none of the build notes: every
pull request below must stand on its own description and tests.

## The rules this plan satisfies

One discrete change per PR, stacked; each carries its tests, and every new device test runs on CI's lavapipe jobs;
`just lint` clean and an independent review before each is opened; plain descriptions that say what a wgpu (Vulkan,
Metal) device should expect when a number is CUDA-only; a one-sentence changelog line only where a user sees a
change; **nothing changes the default client** until the maintainer opts in; **no server, schema or API change**;
every new flag, job, script or example needs an explicit yes; the field structure stays a library detail that ties
the project to nothing.

## Before the first pull request (once, on the branch)

1. The must-fixes M1–M6 of the maintainability read: box-only tests out of CI's reach, a CI-sized device test set run
   once under `--features cubecl` (WGSL) and `cubecl-spirv` on lavapipe, the main kernel's dead experiment branches
   removed with SPIR-V identical before and after, the data layouts written down, note references and step labels
   rewritten, the part-field / host-tops / timing APIs made private. These are edits to the final tree, not new
   features; their evidence (identical kernel IR, parity tests) goes into the PR that carries the code.
2. Measure the CI-sized tests' time on a 4-core runner (lavapipe ~70–190 s per slice test on ivory, by the notes).
3. Decide the cuts below with the maintainer's answers to the questions at the end.

## How to turn the history into the series

Do **not** rebase or squash the existing 49 commits: they contain superseded steps (a first expansion replaced a
step later, a timing switch read from the environment and then removed, a coordinate changed, three merges). Build
each PR as **fresh commits on a fresh branch from `origin/main`** (or from the previous PR's branch), taking whole
files from the final, cleaned tree where a PR adds a whole file (`git checkout <clean-tip> -- <paths>`), and for
`gpu.rs`, which four PRs share, by **subtraction**: start from the final file and remove what later PRs add. Each
intermediate state is new code that has never run, so each PR's own tests must run on it (lavapipe at least; the
CUDA box tests at the PR that adds the field path). Final check, worth stating in the last PR: `git diff <clean-tip>
<last-PR> -- common/src/midout` shows only the listed cuts. Keep `dev/middle-out-join` as the archive of everything
cut (the audit harness, the wide path, the benches, the route) until those land.

## The series

**First series (base 64, library only, no client change): PRs 1–6.** Later, each after an explicit yes: 7–12.

| # | purpose (one sentence) | files | ~lines (code + tests) | CI verifies on its own | risk if merged alone | look hardest at |
|---|---|---|---|---|---|---|
| 1 | Add the field coordinate: a range of a per-base digit permutation `v` whose fields fix three middle digits | `lib.rs` (+1), `midout/mod.rs`, `midout/coord.rs` | 330 + 200 | bijection, quantum = fixed digits, padding counts (CPU, seconds) | none: unused library code, no server | the contract in `coord.rs:30–48` (what a search may rely on) and that nothing claims it is stored anywhere |
| 2 | Add the exact CPU reference of the join and its predicate, checked against brute force | `midout/{arith,mask,cpu}.rs` | 900 + 190 | every field of 11 small bases = brute force, survivors and `checked` (13 s release) | none | `cpu::prefilter` and `q_checked`: the definition of `checked`; a conceptual error shared by CPU and device is caught only here |
| 3 | Build a base-64 slice's tops on the device | `midout/gpu.rs` (tops kernels, host-tops oracle, launch) | 800 + 200 | device tops = CPU tops, 2 slices on lavapipe (WGSL and SPIR-V); certificate unit tests (CPU) | none: not reachable | the certificate arithmetic's range at n near 2^76 and the containment argument of the 64-slice level |
| 4 | Join one base-64 slice on the device: parents, main kernel, record expansion with prefilter, production's check, per-slice accounts | `midout/gpu.rs` | 2,600 + 450 | part of a slice (3 batches of 4 classes) = CPU reference n for n; dropped-stage faults loud by account, on lavapipe | none: not reachable | the data-layout section (M4) and the accounts table: what each count is compared with; the 16-bit class index and 20-bit top index guards |
| 5 | Search a whole field: groups of slices, done words, field accounts, the sampled CPU check, `search_field` | `midout/gpu.rs` | 500 + 200 | the first slices of a field through the field path = per-slice sums = CPU; group sizes agree; sampled check fails on an injected prefilter fault (lavapipe). Whole fields on CUDA: box tests, results in the description | none: no caller outside tests | that `search_field` refuses anything partial or timed, and what the sampled check can and cannot see |
| 6 | Share the parents' root pass across digit 8 inside a field (−3 % per field on CUDA) | `midout/gpu.rs` (`anc8_kernel`, shared lists) | 300 + 150 | shared = unshared counts on 2 slices, and a dropped shared pass is loud (lavapipe) | none | memory (~870 MB of lists) and that the sampled check's rerun stays unshared |
| 7 *(yes)* | A way to run fields on one's own card: `midout_bench` | `common/examples/midout_bench.rs`, `Cargo.toml` | 190 | builds (lint) | none | that it cannot submit anything; the first example in the repo |
| 8 *(yes)* | Every ordinary claim refuses a field marked as a coordinate range | `client_api_async.rs`, `midout/wire.rs` (guard only) | 40 + 70 | loopback test: marked claims refused, plain claims parsed | low: a no-op for every production body today | that it fixes the key name `coordinate` before any server design |
| 9 *(yes)* | A development client route against a local coordinator | `midout/route.rs`, `midout/wire.rs` (rest), `client/src/midout_route.rs`, `main.rs`, `client/Cargo.toml` | 600 + 200 | claim checks refused before work, production host refused, flag absent = unchanged client | low: off unless the flag is given; the flag shows in `--help` unless hidden | the guards' order (production refused first; failed account or panic: nothing submitted) |
| 10 *(yes)* | The local coordinator and its work-list tool | `scripts/midout_coordinator.py`, `common/examples/midout_fields.rs` | 220 | none in CI (Python, stdlib) | none | that it binds 127.0.0.1 and never re-issues unless told |
| 11 | Wide device path, one slice, bases 65–70 (own check kernel) | `midout/gpu_wide.rs` | 3,000 + 500 | base 40 slice and small-base brute force on lavapipe | none: not reachable | `wcheck_kernel`, a second full check never independently audited |
| 12 | Wide path: fields, accounts, sampled check, base-b² prefilter | `midout/gpu_wide.rs`, `route.rs` (base 65) | 900 + 250 | base 40 field part, faults loud (lavapipe) | none | the duplicated driver (S1) |

Sizes are estimates from the final tree's line ranges, after the M3 and §cut deletions; they will move by ±20 %.

### The pull requests, one paragraph each

**1. The field coordinate.** Adds `midout::coord`: one formula `v(n)` with three digit positions, its inverse, the
quantum (the n whose middle digits `[q0, k1)` take one value), `field_digits`, `n_count`. Base 64 only by default:
`(4, 8, 5)`, fields fixing digits 5–7, an exact bit permutation of `[2^75, 2^76)`, 262,144 fields of 2^57; the padded
form for other bases kept for its tests (it is what makes the formula general). The maintainer can verify alone that
every n has exactly one field and that a field is exactly "these three digits in this range" (tests in seconds). Left
out: any second coordinate (cut), any wire or server notion. Merged alone it is unused library code. Look hardest at
the stated contract, because it is what a server would one day store; the description should say in plain words
that this PR proposes no field row, claim format or API, and that the join is free to cut a field any way it likes.

**2. The CPU reference.** Adds the join's exact CPU reference, generic over the mask word (`u64` and `u128`, so it
covers base 65 too): certificates, bottoms, parents, the slice join, the prefilter, the field search, and the
brute-force predicate. The test searches every field of eleven small bases in one or two shapes and compares
survivors, `checked` and the nice numbers (69 at base 10) with brute force: this is the only place a mistake in the
*definition* (shared by CPU and device) can be seen, which is why it deserves a slow read. `arith.rs` deliberately
re-implements nice-ness and the residue roots (an oracle should not reuse what it checks; say so). **Stop point A:**
after PR 2 the repository has a documented, tested definition of the search and of its unit of work, with no GPU code
and no commitment.

**3. Device tops.** The tops kernels (`tops5` per 64 slices, `tops1`, `tscan`, `tops2`, the digit and top-record
kernels) and the host's `slice_tops` as their oracle. Test on lavapipe: device tops equal the CPU's (h, digits, mask)
for two slices, plus the 20,000-prefix certificate test on CPU. This PR needs a small per-slice driver that PR 4
extends: it does not exist in the final tree and must be written by subtraction (cost: a day; benefit: the tops are
reviewable alone). If the maintainer prefers one larger PR, fold 3 into 4.

**4. One slice on the device.** The parents' preparation (`hist2`, `scan16`, `scatter3`, `hsort`), the main kernel
(from the earlier G2 prototype, with child lists and record words added), the expansion with production's
middle-digit prefilter, production's unchanged `check_kernel`, the per-slice account buffer, the guards, and
`run_slice_dev`. Tests on lavapipe: a CI-sized part of a slice against the CPU reference n for n, and the fault test
showing a dropped main kernel, dropped tops, a dropped probe and a dropped parent each fail an account (the fault bits
as comptime test-only switches, S6). The description must say: exactness was shown on CUDA and on lavapipe; nothing
has run on a 64-lane device; no time is claimed for wgpu. This is the large one (~3,000 lines); the reviewer should
not read the main kernel line by line against the prototype but check the layout section, the accounts, and the
evidence (parity n for n, the audit's 1,073 slices on CUDA, which the description can summarise in numbers).

**5. A whole field.** Groups of slices on one stream with one synchronisation per group, the done word per slice (the
field's slice count comes from the device), the field-level checks (each reported n lies in the field), the sampled
CPU check on a host thread, and `search_field` returning `FieldOutcome` (nice numbers, `survivors`, `checked`). Tests
on lavapipe: the field path over a field's first few slices equals the per-slice runs and the CPU reference, at group
sizes 1 and 4; the sampled check fails on an injected too-strict prefilter that every account passes. CUDA box tests
(a whole field, the OOM test) stay ignored behind a box-only feature, with their results in the description.
**Stop point B:** after PR 5 (or 6) a maintainer with a CUDA card can search a base-64 field from a test, exactly and
with every account; nothing in the client has changed.

**6. Parent sharing.** One new kernel and the field driver's choice to build 64 shared lists at a field's start. On
by default inside the library (the library has no caller yet, so "default" changes nothing users run). The test
compares shared and unshared counts slice for slice. It is a discrete optimisation and is the reason the coordinate
fixes digits 5–7 rather than 6–8; that is worth one sentence in PR 1's description too.

**7–10 (each needs an explicit yes).** 7 is a benchmark example (no example exists in the repo today; an ignored
test with documented variables is the alternative). 8 is the only change to a production code path in the whole
series (every client's claim) and it names a wire key; it is either landed early so released clients carry the guard
before any server work, or kept for the server design (question 6). 9 adds `--midout-coordinator`: off unless given,
production refused, nothing submitted after a failed account, a differing sampled check or a panic on any thread
(the process-wide panic hook is installed only by the route). 10 is the coordinator script and its work-list cutter.
Their how-to belongs in the script's header and the route's module docs.

**11–12 (the wide path).** As two PRs on the same pattern as 4–5, after base 64 has run in production. PR 11 carries
the second full check kernel; it should get the same kind of independent read the narrow path had.

## What not to propose yet

- Anything that stores a coordinate on the server: field rows in `v`, a coordinate id column, the claim path
  `?coordinate=midout`, the `"coordinate"` claim key as a server feature, a separate queue, interval-query changes
  for base 64, a backfill of locally searched fields. The branch's wire module (`wire.rs`) and the coordinator encode
  one possible design for all of these; landing them early would make that design the default answer.
- Bases 68–70 (not run since the wide merge; base 68 does not fit a 10 GB card).
- The 64-lane (RX 9070 XT) claims: compiled and validated offline only.

## What I would cut from a first series

| cut | lines | saves the reviewer | costs |
|---|---|---|---|
| The wide path (`gpu_wide.rs`) and its bench, to PRs 11–12 | 4,700 | a second 600-line main kernel, a second full check, a duplicated driver: a third of the diff | base 65 is not ready when base 64 ends; every narrow change before then widens the hand-porting gap (S1) |
| The (4, 9, 6) coordinate (keep only (4, 8, 5)) and the tests comparing the two | ~350 | a second meaning of "field t"; one test that runs 4,096 slices twice | the cross-coordinate equality test (an extra consistency check; the CPU reference covers the same ground) |
| The host-tops field path (`GpuOptions::device_tops`, `host_threads`, `queue_prep`, `run_slice`, the thread pool); keep `slice_tops` as test oracle | ~300 | a non-default path with fewer accounts | a fallback no one uses (device tops are the default) |
| Timing stops, `time_field*`, `search_field_part` from the shipped API (to PR 7 or tests) | ~150 | two APIs that return non-results | the bench's per-stage timing until PR 7 |
| The audit harness except the fault test: sweep, tops scan, OOM with a memory hog, key/group independence | ~600 | box-only research tools, `/root` paths, ~20 environment variables | re-running the sweep needs the archive branch |
| Offline 64-lane preflight tooling (`with_width`, `MIDOUT_FORCE_W`) and `expansion_bits_profile` | ~250 | diagnostics | the offline RX 9070 XT preflight needs the archive branch |
| Tests against the staged prototype (`b64_slice_vs_staged`, `wide_slice_vs_staged`) | ~110 | tests whose data is not in the repository | none (the CPU reference covers the slices) |
| The wide prefilter's old form (`pf_w`, `set_prefilter_b2`) | ~80 | a superseded A/B alternative | none |
| Route, wire, client flag, claim guard, coordinator, work-list tool, benches (PRs 7–10) | ~1,500 | all new surface | no end-to-end run from a client until the maintainer says yes |

With these cuts the first series is PRs 1–6, roughly **5,500 code + 1,400 test lines** instead of 13,300.

## Questions for the maintainer (one line each)

1. Is base 65 (the wide path, ~4,700 lines) in the first series, or after base 64 has run on the fleet?
2. Keep one coordinate only, `(4, 8, 5)` at base 64 (fields fix digits 5–7), and drop `(4, 9, 6)` from the code?
3. Long GPU tests: keep them out of CI's blanket `--ignored` run by a cargo feature (e.g. `midout-box-tests`), and should midout device tests run on the Metal job at all?
4. For running fields on your own card: an example binary `midout_bench` (the repo's first example), or ignored tests only?
5. The client route: yes or no to a development flag `--midout-coordinator URL` (hidden from `--help`?), and does the coordinator script belong in `scripts/` or outside the repo?
6. The claim guard (ordinary claims refuse a body with a `coordinate` key): land it early so released clients carry it, or only with the server design?
7. Names: `midout` / "middle-out join" for the module, telemetry route and features, or another?
