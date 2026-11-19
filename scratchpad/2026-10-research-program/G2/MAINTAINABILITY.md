# The middle-out join: a maintainability read of `dev/middle-out-join` (2026-11-19)

Reviewer: one agent, alone, read-only, on ivory, 12:00–15:00 UTC. Branch `dev/middle-out-join` at `66259bb0`
(worktree `~/projects/nice/.worktrees/midout`), compared with `origin/main` (`71eb5fcd`; the branch's base is
`be9cc923`, one commit behind: a `justfile` change, so a rebase is trivial). Nothing was built or run; every
statement about tests running is from reading the code and CI files, and every statement about what ran on a card
is from the branch's own build notes, said as such. Kernel correctness and speed are out of scope (an audit covered
the base-64 device path; see "What the audit did not cover" below). Line numbers are of `66259bb0`.

**Read this first if you have not seen the branch.** The middle-out join is a new nice-only search for base 64
(and, in a second code path, bases 65–70). Its work unit is a *field*: a range of a per-base coordinate `v` (a
fixed permutation of n's digits), which pins three middle digits of n and leaves every other digit free. A field
is cut into *slices* (one value of digits 4–8 of n; 4,096 per base-64 field). Per slice the device builds *tops*
(certificates on the high digits) and *parents* (on the low digits), pairs them in a main kernel that writes
*records*, expands the records into survivor entries with a middle-digit prefilter, and runs production's full
check on them. Two safety nets: *accounts* (each stage counts its own work and the host compares the counts, so a
dropped launch or failed allocation is an error, not an empty field) and a *sampled CPU check* (one random slice
per field recomputed by an exact CPU reference). The *narrow* path is base 64 with 64-bit digit masks
(`gpu.rs`); the *wide* path is bases 65–70 with two-word masks (`gpu_wide.rs`).

## 0. The shape of the diff

The brief's "about 7,000 lines" is low: `git diff --stat origin/main...HEAD` is **13,300 insertions in 20 files**
(49 commits, 3 of them merges).

| part | files | lines | of which tests |
|---|---|---|---|
| coordinate | `midout/coord.rs`, `mod.rs` | 574 | ~240 |
| CPU reference | `midout/cpu.rs`, `arith.rs`, `mask.rs` | 1,103 | ~190 |
| narrow device path (base 64) | `midout/gpu.rs` | 4,795 | ~830 (+ `audit.rs`) |
| audit harness (test module of `gpu.rs`) | `midout/audit.rs` | 813 | all |
| wide device path (bases 65–70) | `midout/gpu_wide.rs` | 4,516 | ~840 |
| route, wire | `midout/route.rs`, `wire.rs` | 407 | ~80 |
| examples | `midout_bench.rs`, `midout_wide_bench.rs`, `midout_fields.rs` | 424 | — |
| client | `client/src/midout_route.rs`, `main.rs`, `Cargo.toml` | 442 | ~110 |
| production edits | `client_api_async.rs`, `lib.rs`, `common/Cargo.toml` | 64 | 44 |
| coordinator | `scripts/midout_coordinator.py` | 164 | — |

For calibration: production's `cubecl_join.rs` is 8,500 lines, so file size alone is not the problem here.

## 1. Must be fixed before any pull request

**M1. CI would run the branch's box-only GPU tests, and fail or time out.** `gpu-parity.yml:62` (lavapipe) and
`gpu-parity.yml:119` (Metal, 30-minute limit) run `cargo test --release --features cubecl -p nice_common --
--ignored`: *every* ignored test in the crate. The branch adds 17 ignored midout tests written for a CUDA box:

- two panic without data that is not in the repository: `cpu.rs:867` `b64_slice_vs_staged` and `gpu_wide.rs:4450`
  `wide_slice_vs_staged` (`expect("MIDOUT_SU_DIR")`, a staged prototype slice);
- `audit.rs:312` `audit_tops_scan` (not CUDA-gated) runs minutes of CPU, then writes to `/root/audit/…`
  (`audit.rs:316`; also `:151`);
- several run whole fields or many slices, hours on lavapipe: `gpu.rs:4482` `field_485_equals_496_slice_by_slice`
  (4,096 slices, then the field again), `gpu.rs:4405` `field_parent_sharing_is_exact_and_loud` (128 slices),
  `gpu_wide.rs:3900`, `gpu_wide.rs:4140` (17 shapes);
- `gpu.rs:4696` `gpu_slices_equal_cpu` defaults to 63 classes per batch (`gpu.rs:4703`), which the branch's own notes
  say exceeds lavapipe's 128 MiB binding limit (the engineers always passed `MIDOUT_CLASSES=4` there).

Fix: box-only tests behind a cargo feature that CI never enables (or deleted, §2 cuts), and an explicit, short set of
CI tests (§4). This is also a maintainer decision (question 3 in the plan).

**M2. The device code has never run on the two paths CI would put it on.** The midout kernels ran on CUDA (RTX 3080)
and on lavapipe through CubeCL's SPIR-V compiler (`--features cubecl-spirv`), 8 lanes per plane. CI's lavapipe step
uses `--features cubecl` (WGSL through naga) and its Metal job uses wgpu → Metal; neither has ever compiled these
kernels (no WGSL or Metal run is recorded anywhere). Conversely, CI's SPIR-V step (`gpu-parity.yml:103`) filters
tests by `cubecl_`, so the one compiler that *was* validated would not run any midout test. Also note that the
prefilter form is chosen by the runtime's *name*: `gpu.rs:2845` `oh64: R::name(&client).contains("spirv")`, so WGSL
and Metal get the CUDA form (`pf`, `gpu.rs:1585`), which ran only on CUDA. Before the first device PR: run the CI-sized
tests once under `--features cubecl` on lavapipe, name them so the SPIR-V step picks them up, and decide Metal
(the wide path divides by comptime constants throughout, the class of code the repo's Apple-division lint at
`gpu-parity.yml:64–85` exists for; midout kernels are not in that lint's required list).

**M3. The narrow main kernel still carries the prototype's experiment switches.** `gpu.rs:237–273`: `g2_kernel` takes
ten comptime knobs (`mode`, `noout`, `w`, `fill`, `xpose`, `ept`, `ranks`, `cut`, `cmask`, `tdg`) and an argument
`tmask` documented as "only for --tdig 0" (`gpu.rs:242`, a flag that does not exist). The one launch passes them as
bare positional literals (`gpu.rs:3482–3491`: `2u32, false, self.w, self.fill, 1u32, 2u32, 1u32, 0u32, 1u32, 1u32`).
About 15 comptime branches in the kernel body serve values the library never uses (e.g. `mode == 0`, `xpose == 0`,
`ranks == 0`, `cut` bits, `tdg == 0`). A reader of a 720-line kernel cannot tell live code from dead. Fix: delete the
dead branches and the unused argument, or at minimum name the constants at the launch. Because the kernel is
audited, do it mechanically and **prove it changed nothing**: the branch already has the tool (the compile-only
path dumps each kernel's SPIR-V on lavapipe, `CUBECL_DEBUG_SPIRV`); identical SPIR-V before and after, plus the
parity tests, is the evidence a PR description can carry. The wide kernel (`gpu_wide.rs:220`) has no such knobs.

**M4. The kernels' data layouts and invariants are not written down in one place.** The pieces a reviewer needs to
follow the pipeline are scattered through argument comments: the record (four words: probe slot + offset, unit,
class, first child-list position, the 64-pair word), the job word (`unit | probe offset << 8`, `gpu.rs:313`), the top
index riding in bits 12–31 of probe word 3 (`gpu.rs:374`), the child-list position formula (`gpu.rs:252–253`), the
survivor entry `(top, r0)` and the 8-word top record (production's layout), the slab layout, and the account vector.
The submodules `kernels`, `prep`, `post`, `dtops` (`gpu.rs:156, 954, 1469, 1903`) and `wk`, `wp`
(`gpu_wide.rs:151, 820`) have no module docs. The file's own header is stale: `gpu.rs:6–7` says tops are made on
the host (the device makes them; host tops are a non-default fallback) and `gpu.rs:8–10` says the preparation and
main kernel are "unchanged" from the port (both changed: shared parents, `scatter3`'s children count, records,
child lists, accounts). Fix: one "data layouts" section and one "stages and what each proves" table in the module
docs (the account table already exists in prose, `gpu.rs:108–139`; it should say what each count is compared with,
as `gpu.rs:128–129` does for the main kernel).

**M5. The code cites documents the repository does not have, and the history of the two days.** 56 references to
internal notes (`BUILD-NOTES`, `AUDIT-MO`, `PROPOSAL`, `RESULTS`, `REVIEW`; 33 of them in `audit.rs`), e.g.
`coord.rs:22–27` (`G2/PROPOSAL.md §2`, `G2/bases/RESULTS.md §5`), `gpu.rs:85` (`AUDIT-MO §3.4`, though the proof is
then given inline, which is right), `route.rs:67` (`BUILD-NOTES §11.4`), `cpu.rs:862` (`G2/bench/su64_*`). About 40
"step 3A / 4S / 5L" labels, branch names (`audit.rs:1` "(dev/mo-audit)"), dates and box words ("the box's 5-core
quota", `gpu.rs:3874`; "on demoux", `gpu.rs:1425`) and doc comments for flags of the prototype (`gpu.rs:1097`
"--prep2 1 (default)", `gpu.rs:1374` "--scan 1 (default since 2026-11-18)", `gpu.rs:1425` "--prep3"). A pull
request cannot refer to the notes, so each reference must become a self-contained sentence or go.

**M6. Public functions that can return a field result that is not a whole, checked field.** None is reachable from
the client today, but each is `pub` in a library a later caller will use:

- `gpu.rs:3991` `search_field_part` returns a `FieldOutcome` for the field's first K slices; the type is the same as
  a whole field's (only `slices` differs). Make it crate-private or bench-only.
- `gpu.rs:3868–3875` `GpuOptions { device_tops, host_threads }`: `device_tops: false` selects the host-tops path,
  which has no tops accounts (the branch's notes say so; the accounts table in `gpu.rs:108–139` is for device tops).
  The route always passes `true` (`route.rs:103`). Remove the host path from the shipped API (keep `slice_tops`,
  `gpu.rs:2447`, as the tests' oracle).
- `gpu.rs:2890` `set_timing_stop` and `gpu.rs:3560`: with a stop set, `finish_group` returns empty counts without
  any account. `search_field` refuses a stop (`gpu.rs:3954`), which closes the hole the audit reproduced, but the
  bypass still lives in the production driver; `time_field`/`time_field_part` (`gpu.rs:4019, 4048`) are `pub`.
  Same on the wide path (`gpu_wide.rs:2801`). Move timing behind the bench (a feature) or test-only.
- `route.rs:44` accepts bases 65–70 for the wide path; bases 68–70 have not run since the wide branch was merged
  (and 68 does not fit a 10 GB card). Accept 64 (and 65 if the wide path is in) only.

**M7. The client flag is new, visible surface in every release build.** `client/src/main.rs:337–343` adds
`--midout-coordinator URL` to `Cli` unconditionally (not `hide = true`, not cfg-gated), so it shows in the release
client's `--help` even in builds without CubeCL, where it exits 1 (`main.rs:1749–1758`). The maintainer has not
said yes to it. Not a defect, but it must not ride in on another pull request: its own PR, after an explicit yes,
probably hidden.

## 2. Leftovers of the two days

**Superseded alternatives still in the tree** (each a second way to do one thing, kept for A/B):

| what | where | status |
|---|---|---|
| (4, 9, 6) coordinate beside the default (4, 8, 5) | `coord.rs:85–91`, `coord.rs` tests, `gpu.rs:4482`, `gpu_wide.rs:3900`, client tests | kept "known"; a field `t` means a different set of n in each |
| wide prefilter digit by digit (`pf_w`) beside base b² (`pf_w2`) | `gpu_wide.rs:946, 1018`; switch `set_prefilter_b2` `:2794` | old form kept for A/B |
| narrow prefilter: CUDA form `pf` and SPIR-V form `pf24` | `gpu.rs:1543, 1585, 1622`; choice by runtime name `:2845` | both live, by backend |
| host tops field path | `gpu.rs:3293 queue_prep`, `:3830 run_slice`, `:4162` thread pool | non-default, fewer accounts |
| parent sharing switch | `gpu.rs:2899 set_parent_sharing`, bench `--no-share-parents` | on by default |
| prototype comptime knobs in the main kernel | `gpu.rs:263–272` | M3 |

**Experiment switches and environment variables.** No environment variable is read by library code: every one of
the ~40 `MIDOUT_*`/`AUDIT_*` reads is inside tests (e.g. `gpu.rs:4407–4761`, `gpu_wide.rs:3905–4452`,
`audit.rs`), the benches read `MIDOUT_STOP` (`midout_bench.rs`, `midout_wide_bench.rs`), and the client reads
`NICE_MIDOUT_FAULT` only when built with `midout-fault` (`midout_route.rs:136–144`, `cfg!`). That part is clean.
But the tests' behaviour depends on ~40 undocumented variables (slices, classes, shapes, fault cases, `MIDOUT_CUDA`
to pick the runtime), so "run the tests" has no single meaning for a new reader. Two tests set an environment
variable with `unsafe { std::env::set_var(…) }` inside the multi-threaded test harness (`audit.rs:438`,
`gpu_wide.rs:4405`), for `MIDOUT_STOP`, which the library no longer reads: the tests are now near-vacuous and the
`set_var` is the kind of thing Rust 2024 made `unsafe` for a reason.

**Test-only fault injection, and whether it can leak.** Fault bits are a runtime `u32` argument of production kernels
(`g2_kernel` `gpu.rs:256–259`, `hist2` `:1113`, `expand_kernel` `:1766`, `tops1` `:2045`, and the wide kernels), set
by `pub(crate) fn set_fault` (`gpu.rs:2761`, `gpu_wide.rs` likewise) and, from outside the crate, only by
`route::FieldJoin::set_test_fault` under the `midout-fault` feature (`route.rs:147`). `midout-fault` is in no umbrella
feature (`common/Cargo.toml:37–39`, `client/Cargo.toml:33–35`), nothing in CI, the justfile or the Docker builds uses
`--all-features`, and the branch's notes record `strings` finding no `NICE_MIDOUT_FAULT` in a release-feature binary.
**So no test switch can reach a release build today.** What remains is that release kernels carry the fault branches
(always 0) and their extra argument; making `fault` a comptime parameter that only tests set would remove them from
release kernels entirely. Should, not must.

**Diagnostics and examples that are benchmarks.** `gpu.rs:4601` `expansion_bits_profile` (a profiling test),
`with_width`/`MIDOUT_FORCE_W` (a compile-only path to dump 64-lane SPIR-V for offline preflight,
`gpu.rs:4712`, `gpu_wide.rs:2658`, 130 lines), the timing stops (M6), `midout_bench.rs` (193) and
`midout_wide_bench.rs` (175) are benchmarks; `midout_fields.rs` (56) is a work-list tool for the local coordinator.
`common/examples/` does not exist on main: the examples are a new kind of surface for this repository. Box-only
harnesses in `audit.rs` (sweep, tops scan, OOM with a memory hog, key and group independence; ~600 of its 813 lines)
are research tools, valuable but not CI tests.

**Duplication between the narrow and wide paths.** `gpu_wide.rs:6–10` states the policy: "a second path, not a width
parameter … what the narrow path gains must be ported here by hand." Measured by text: 478 of the wide file's 1,791
non-trivial lines (27 %) are verbatim lines of `gpu.rs`, about 1,440 lines align as matching blocks, and 19 host
functions have the same name in both (`new`, `with_width`, `queue_prep`, `queue_batch`, `finish_group`,
`check_slice`, `run_slice`, `set_fault`, `set_timing_stop`, `upto`, `mk`, `rd`, …). The two account vectors use the
same names with different indices (`A_H2_CUBES = 6` narrow, `A_H_CUBES = 5` wide; `ACC_WORDS` 20 vs 16), and the
wide path has its own full check kernel (`gpu_wide.rs:2181` `wcheck_kernel`, because production's check holds digits
in one 64-bit mask). The branch's own history shows the cost: accounts, guards, the top hierarchy, the prefilter and
the 4S tuning were each ported or not ported by hand, a step apart; parent sharing is narrow-only.

*Is one generic path realistic in CubeCL 0.10?* My judgement, not tested: **for the kernels, a trap; for the host
driver, worth it later.** The kernels differ in more than a type parameter: digits by shifts against digits by
division (`% b`, base-b² limbs), 6-bit against 7-bit digit fields, 65 against `(b + 1) | 1` slice rows, ballot
transposes for digits 64..b, a different shared-memory budget (the branch's preflight: 21,504 B narrow against
24,576 B wide, which changes occupancy), and a different check kernel. In CubeCL 0.10 that means either a mask trait
with `#[cube]` methods or comptime branches everywhere; both put two kernels' worth of reading into one function and
make every narrow change re-validate the wide path and vice versa, and base 64's tuned instruction counts would have
to be re-proved. The host side (queueing, group synchronisation, accounts check, field driver, sampled check) is
ordinary Rust whose differences are buffer sizes and a few constants; sharing it would remove most of the
same-named functions and the index drift. Until then, a correspondence table (narrow item → wide item) in the module
docs is the cheap fix.

## 3. Production files: what changed, and is each edit really additive

| file | change | verdict |
|---|---|---|
| `common/src/lib.rs:34` | `pub mod midout;` | additive. Note: `coord`, `cpu`, `arith`, `mask`, `wire` compile into **every** build (they are not behind `cubecl`); only `gpu`, `gpu_wide`, `route` are. |
| `common/Cargo.toml:37–39, 85–91` | feature `midout-fault = ["cubecl"]`; two `[[example]]` entries (`required-features = ["cubecl"]`) | additive; the first examples in the repository |
| `client/Cargo.toml:33–35` | feature `midout-fault` | additive; in no umbrella |
| `client/src/main.rs:42–43, 337–343, 1747–1759` | module (cfg `cubecl`); a `Cli` field; dispatch before any backend is set up when the flag is given | additive when the flag is absent; the flag itself is new visible surface (M7) |
| `common/src/client_api_async.rs:122–130` | every ordinary claim now reads the body as bytes, runs `midout::wire::refuse_coordinate_space`, then `serde_json::from_slice` (what `reqwest`'s `.json()` did) | **behaviour-equivalent for every body without a `coordinate` key** (a null key also passes); one extra JSON parse per claim; a body-read failure now has its own error context. Errors here are not retried (`retry_request_async` retries only 5xx and transport errors), so a refused claim fails once and does not claim again. But it is a change to the claim path of every client, and it fixes the key name `coordinate` and its meaning before any server design: its own PR, or deferred (question 6). |
| `common/src/cubecl_join.rs`, `join_check.rs` | unchanged; used (`check_kernel`, `CheckShape`, `TOP_REC_WORDS`, `ballot_append`) | production's private `RAN_WORDS` and `CHECK_CUBES` (`cubecl_join.rs:133, 170`) are **copied** as constants at `gpu.rs:140–145`; a change in production would silently desynchronise the copy. Make them `pub(crate)` (a two-word production edit) or assert equality in a test. |

Nothing changes the default client's behaviour: the claim edit is a no-op for every production body, and the route
runs only with the flag. The branch's notes record the default routes giving identical submissions to the trunk's
client on a local stub (stride, overlap join, CPU, detailed). Nothing touches the server, schema or API crates.

## 4. Tests: what is fast, what needs a GPU, what CI would exercise

**CPU, default build (would run in `rust-build-test.yml`'s `cargo test --release` and in `just test`, debug):**
`coord` (7 tests), `cpu` (3 + 1 ignored), `arith` (1), `wire` (3), `client_api_async::ordinary_claims_refuse…` (a
loopback server). The heaviest is `cpu.rs:727` `whole_small_bases_vs_brute_force`, 13 s in release by the notes;
`just test` runs debug, where it will be several times slower (not measured).

**CPU, compiled only with `cubecl` (would run in `rust-build-test.yml:70`, `--features gpu --lib`, not ignored):**
`gpu.rs:4308` `top_cert_b64_equals_the_reference` (20,000 prefixes), `gpu.rs:4335`
`slice_tops_equal_the_reference_units`, `gpu_wide.rs:3854` `wide_bases_fit_the_layouts`, `audit.rs:568`
`audit_coord_slices_partition` (iterates every slice key of base 64 and 65, ~2.2e9 steps). None needs a device;
their CI time is not measured (I expect seconds to a minute in release). The client's two route tests compile only
with a CubeCL feature.

**GPU (all `#[ignore]`):** 17 midout tests plus the 9 CUDA-only audit tests. What actually ran, by the notes:

| test | CUDA (3080) | lavapipe SPIR-V, W 8 | lavapipe WGSL | Metal |
|---|---|---|---|---|
| `gpu_slices_equal_cpu` (slice parity, n for n) | 5+ slices | 2–4 slices, 4 classes/batch, ~70–110 s each | never | never |
| `accounts_faults_are_loud` (`audit.rs:493`) | yes | 1 slice, ~190 s | never | never |
| `gpu_check_rebuilds_the_survivors` | yes | — | never | never |
| `field_parent_sharing_is_exact_and_loud`, `field_485_equals_496…` | yes | one shared slice via `gpu_slices_equal_cpu` only | never | never |
| `wide_slices_equal_cpu` | b30–b65 | b40, b65 one slice each | never | never |
| `wide_faults_are_loud` | b65, b64 forced | b40 | never | never |
| `wide_whole_small_bases_vs_brute_force` | 17 shapes | not recorded | never | never |
| audit sweep (1,073 slices), OOM, group/key independence | yes (CUDA-only by `cfg`) | — | — | — |

**What CI would exercise today if the branch were merged as is:** the CPU tests above (fine); and, in
`gpu-parity.yml`, every ignored midout test on WGSL-lavapipe and on Metal, a combination never run, with panics and
hours-long runs among them (M1, M2). The SPIR-V step would run none of them. **Covered only by box runs recorded in
notes:** the whole of CUDA (the production target for the fleet's NVIDIA cards), whole fields, the audit sweep, the
OOM behaviour, the client route end to end, both coordinates' equality, base 65 fields, and every timing.
**Covered nowhere:** 64-lane planes on a real device (the RX 9070 XT; compiled and validated offline only),
lavapipe at 16 lanes (aborts in lavapipe), bases 68–70 since the merge, the route on any wgpu device, Metal.

**A CI-sized set that exists in the code today** (by reading; run times are the notes' lavapipe figures on a 4-core
machine): `gpu_slices_equal_cpu` on one slice with 4 classes per batch, or part of a slice (`MIDOUT_BATCHES`, 3
batches), against the CPU reference n for n; `accounts_faults_are_loud` on one slice; device tops against CPU tops;
`wide_slices_equal_cpu` at base 40 (small). These need their environment defaults changed to the CI values (or
constants), `cubecl_` in their names for the SPIR-V step, and a measured time on a GitHub runner.

**What the audit did not cover.** The independent audit read `coord.rs`, `cpu.rs` and `gpu.rs` at `91ac0761`, before
the accounts, before (4, 8, 5), parent sharing and the step-4S tuning, and **not `gpu_wide.rs`** (whose full check
kernel, `wcheck_kernel`, is new code that decides niceness and is checked only against brute force at bases 10–25
and the CPU reference on slices). A maintainer should know the base-65 path has had no independent read.

## 5. Documentation the repository would need

1. **Module docs of `midout` as the design note** (`mod.rs`, today 22 lines of index): what a field, slice, shape,
   top, parent, record and survivor entry are; the stages per slice and the data each hands the next; the accounts
   and what each proves, and what only the sampled check can see (the notes have a good list of what is invisible to
   the accounts: a wrong certificate, a wrong `parent()` mask, a false common-mask skip, a too-strict prefilter); the
   sampled check's coverage (probability of catching a defect touching a fraction f of slices after k fields); the
   capacity limits and their measured margins (the audit's table: tops 1.9×, class size 3.8×, PMAX handled by a
   second instance, MAXPOP 17 proved). Everything a PR description would otherwise point at the notes for.
2. **The coordinate's contract** in `coord.rs` is already well written (`coord.rs:1–48`); remove the note
   references and the non-existent "join module" (`coord.rs:50`), and state plainly that no server stores it.
3. **How to run the device tests**: which runtime, which variables, which tests are CI-sized and which are box-only,
   on what kind of card; one short block, not ~40 variables discovered from the source.
4. **The data layouts** (M4) and a narrow ↔ wide correspondence table (§2).
5. **The coordinator and route**, only in the PR that adds them: the how-to in `BUILD-NOTES-CLIENT.md` §2 is the
   right content (build, cut a work list, start the coordinator, run the client), and must live in the script's
   header or the route's module docs. Also what the real server would need (that note's §8) belongs in an issue, not
   in code.
6. A one-sentence CHANGELOG line per user-visible PR only (none of the library PRs is user-visible).

## 6. Should (before the PR that carries the code, or soon after)

- **S1.** Narrow/wide duplication (§2): add the correspondence table now; plan a shared host driver later; do not
  attempt a generic kernel.
- **S2.** Two prefilter forms on the narrow path chosen by `R::name(...).contains("spirv")` (`gpu.rs:2845`): a string
  match on a runtime's name is fragile (a renamed runtime silently switches arithmetic). Use an explicit option, or
  one form for all runtimes.
- **S3.** Long functions without internal structure: `g2_kernel` 720 lines (`gpu.rs:239`), `wide_kernel` 610
  (`gpu_wide.rs:220`), `field_run` 246 (`gpu.rs:4062`), `wexpand_kernel` 237 (`gpu_wide.rs:1944`), wide
  `queue_prep` 226 (`gpu_wide.rs:2835`), `finish_group` 174 / 154 (`gpu.rs:3558`, `gpu_wide.rs:3224`). The kernels
  should stay one function (CubeCL), but need phase headers that match the doc's stage list; the host functions can
  be split (account checks out of `finish_group`).
- **S4.** Module-wide lint allowances: 35 clippy lints plus rustc's `unused_assignments` and `unused_mut` in both
  device files (`gpu.rs:24–60`, `gpu_wide.rs:39–75`), ten more on the whole module (`mod.rs:26–37`). Narrow the rustc
  ones at least: they hide exactly the dead-code leftovers of M3.
- **S5.** The copied production constants (§3).
- **S6.** Fault bits as a runtime kernel argument (§2): make them comptime and test-only.
- **S7.** `unsafe set_var` in tests (`audit.rs:438`, `gpu_wide.rs:4405`): drop or run in a subprocess.
- **S8.** Small doc errors: `audit.rs:4` "every test is ignored" (`audit_coord_slices_partition` is not);
  `midout_bench.rs:3` "tops on the host"; `cpu_slice` hard-codes `Shape { f0: 4, k: 10 }` (`gpu.rs:3891`) where
  `Shape::for_coord` exists.
- **S9.** `arith.rs` re-implements nice-ness (`unique_digits`) and the residue roots that production has
  (`client_process.rs:47, 223`, `residue_filter`). Defensible for an independent oracle; say so in its doc, or the
  next reader will "fix" it by reusing production's.

## 7. Later

- The sampled CPU check is off at base 65 by default (`route.rs:68`; its CPU slice takes longer than the field), so a
  base-65 kernel that computes wrongly while every account holds would be submitted; fine until base 65 is searched.
- Shared parent lists are sized for a 10 GB card (`gpu.rs:2648–2649`: 64 × 3.4M roots, ~870 MB); a longer list is an
  error, never seen.
- The route: no prefetch between fields, panic hook installed after the device context, coordinator bound to
  127.0.0.1 without authentication (all stated in the code or its notes).
- cubecl-spirv emits a duplicate `ArrayStride` decoration for `scatter3`/`wscatter` (spirv-val rejects, RADV and
  lavapipe accept): worth an upstream note.
- Lavapipe at 16 lanes aborts; bases 68–70 need a 16 GB card to run at all.
