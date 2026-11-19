# The middle-out join, step 6C: the branch made fit to be reviewed (2026-11-19, 12:13–17:30 UTC)

Brief `G2/BUILD-BRIEF-6C.md`; specification `G2/MAINTAINABILITY.md` (M1–M7, S1–S9). Branch **`dev/mo-clean`** from
the trunk's head `66259bb0`, worktree `~/projects/nice/.worktrees/midout-clean`, pushed to the fork only. Box: Vast
61441981, RTX 3080 at the host's 240 W cap, 16 threads visible (CPU quota ~5), Ubuntu 24.04, CUDA 12.8, Mesa 25.2.8
lavapipe (LLVM 20.1.2, 256 bits), Rust 1.100.0 (the repo's pin). Box scripts `G2/build6c/box/`, raw logs
`G2/build6c/raw/`. Production hosts mapped to 127.0.0.1 and ::1 at 12:14 UTC before anything ran
(`raw/proof_hosts_block.txt`).

(written as the work proceeds; section 1 is current)

## 2. The must-fix items: what was done and the proof

### M3. The prototype's switches out of the narrow main kernel (`bedb7c48`, `98d1c213`)

- `g2_kernel`'s eight constant comptime knobs (`mode` 2, `noout` false, `xpose` 1, `ept` 2, `ranks` 1, `cut` 0,
  `cmask` 1, `tdg` 1) and every branch for their other values are gone, with the scan form of `plane_rank` /
  `plane_count`; `w` and `fill` stay (they vary: plane width, and 512 children per round below 32 lanes). The launch
  passes `self.w, self.fill` and nothing else; the second commit drops the argument `tmask`, read only by the
  removed per-cube top-digit branch. One redundant barrier (it guarded a removed pass) is kept with a comment, so
  that the generated code stays the audited kernel's.
- **Byte identity is not attainable as such on this toolchain, and why** (measured, `raw/m3/dump/`): two runs of the
  *same* test binary give different SPIR-V modules and different optimised CubeCL IR (`trunk` vs `trunk2`:
  cubecl-opt emits phi nodes and numbers locals in hash order); CubeCL's CUDA source of untouched kernels
  (`scatter3`, the declarations of every kernel) differs between two *builds* in the names and placement of shared
  arrays and the order of declarations, though not between two runs of one binary.
- **What was proved instead** (`box/dump.sh`, `box/cudanorm.py`): CubeCL's CUDA source of every kernel, normalised
  for exactly those things (locals renamed in order of first use, shared-array offsets dropped, declarations
  sorted; the normalisation gives identical output for two runs of one binary). For `g2_kernel`, trunk → M3:
  identical except the removal of three dead selects (the scan form's flags), one repeated comparison and eight
  zero or copy assignments that the removed branches left (the whole structural diff is in
  `raw/m3/dump/g2_structural_diff.txt`); M3 → M3b: identical but for the parameter list and the renumbering of the
  later buffers (the removed argument appears nowhere else). Every other kernel's normalised source is
  identical (the per-kernel md5s in `raw/m3/dump/*/cu_sums.txt`; the one other line that differs is the log's
  header of `g2_kernel`, which lists its comptime arguments and sits in the previous kernel's chunk).
- **Exactness** (CUDA, RTX 3080, on `98d1c213`'s binary, `raw/par_m3b/`): two whole slices (712012851, 502136830)
  n for n against the CPU reference with every count equal (269 s, mostly the CPU reference), the check's rebuild,
  and every fault loud on the full-size fault test (69 s). The ten-field timing against the trunk: §5.

### M4. The data layouts and stages written down (`fa7d9b3e`)

`gpu.rs`'s header, which said the tops are made on the host and that the preparation and main kernel are unchanged
from the port (both untrue), is replaced by: a **stage table** (tops, parents, main kernel per batch, expansion
per batch, production's full check per batch, done) with the kernels of each, what each hands the next, and which
account word proves it ran and what the host compares it with (taken from `check_slice` and `finish_group`, not
from the notes); the two conservation laws; what no account can see (the sampled check's job); and a **data-layouts
section**: parent record and its `cacc` packing, top (`thd`, `tmask`, `tmhi`, segments, `tdig`'s 6-bit fields),
production's top record, job word (`c`, `d | poff << 8`), probe word (top index in bits 12–31 of word 3, digits
15–16 in bits 0–11, why 20 bits suffice and where the host checks it), child-list position formula, record, survivor
entry `(top, r0)` with `n = P·64^5 + r0`, counters, account. `gpu_wide.rs`'s header gets the same section for where
the wide layouts differ (its record names probe slot, unit and class; 7-bit digit fields in 5 words; `rf | mask hi
<< 25`; the account's different indices). The six device submodules (`kernels`, `prep`, `post`, `dtops`, `wk`,
`wp`) have module docs; the bench headers say where the tops are made. Comments only: no code changed (the same
binaries' generated code; lint and tests at the next commits).

### M5. No references outside the repository (`b5ff7e5a`)

Every reference to the build notes, the audit (`AUDIT-MO §…`), the proposal, the research results, `G2/…` paths,
step labels (`(step 3A)`, `4S`, `5L`, `3W`), `(midout)` / `(audit)` / `(audit, dev/mo-audit)` tags, branch names,
dates, machines (`demoux`, "the box"), the prototype's flags (`--prep2`, `--prep3`, `--scan`, `--multi`,
`--tdig 0`, `--debug-lanes`), "the trunk's", "form D", "day one's" and "today" in `common/src/midout`, the
examples and the client route is gone: replaced by the fact a reader needs (the coordinate's formula in full; what
a kernel does instead of which flag once selected it; the measured number with its card; "an independent
implementation outside this repository" for the two staged-reference tests) or removed. `grep -rnE
"§|BUILD-NOTES|AUDIT-MO|PROPOSAL|RESULTS|REVIEW|G2|step [0-9][A-Z]|dev/mo|demoux|2026-|trunk|prototype|--prep"`
over those paths is empty (the `AUDIT_*` environment variables of the in-repo audit harness stay). Also: `coord.rs`
no longer names a nonexistent `join` module and says no server stores the coordinate; `arith.rs` says why it
re-implements nice-ness and the residue roots (S9).

### M6. No public call returns less than a whole, checked field (`326ed0a3`)

- `search_field_part`, `time_field`, `time_field_part`, `time_field_wide`, `GpuJoin::set_timing_stop`,
  `WideJoin::set_timing_stop`, `WideJoin::stop_set`: behind a new feature **`midout-bench`** (in no umbrella), which
  the two bench examples now require; the stop setters stay available to the crate's own tests. `search_field`
  still refuses a join with a stop (defence in depth).
- `GpuOptions`: `device_tops` and `host_threads` are crate-private; `GpuOptions::new(group, cpu_check)` builds the
  only public form (device tops, every account); `with_host_tops(threads)` (bench feature only) selects the
  host-tops path, documented as having no tops accounts.
- `FieldJoin::new` accepts bases 64 and 65 only (66–70 refused, documented why); the client's claim check likewise.
- Proof: `just lint`'s three commands clean, and clippy with `cubecl-cuda,cubecl-spirv,midout-bench` (the bench
  examples) clean (`raw/lint_m67/`).
- Not done: `GpuJoin::run_slice` (host tops, one slice) and `run_slice_dev` stay `pub`: they return one slice's
  counts and survivor list, not a field result, and the read did not list them.

### M7. The client flag hidden (`2539ccec`)

`--midout-coordinator` has `hide = true` (still parsed). Proof: §4 (the client's `--help` on the box).

### M1. Tests in three tiers that CI can run (`4e50cabd`)

**A defect found on the way:** `audit_coord_slices_partition`, an ordinary (not ignored) test that CI's
`cargo test --release -p nice_common --features gpu --lib` runs, **failed on the trunk** (`b64 slice 16777216 not in
field 0`): it hard-coded the old `(4, 9, 6)` coordinate's digit positions and the default became `(4, 8, 5)`. It now
reads the fixed digits from the coordinate, checks every known coordinate of bases 64 and 65, passes, and takes
139 s on this box, so the full form went to tier (c) and a sampled form (16 fields per coordinate plus both ends,
2,000 n) is in tier (a).

The tiers (written in one place: the `midout` module docs, `common/src/midout/mod.rs`):

| tier | what | selected by | run here (box, `raw/m1/`) |
|---|---|---|---|
| (a) ordinary | coordinate, CPU reference vs brute force, top certificate vs reference, slice tops vs reference units, wire, route logic, sampled partition, wide layouts | not ignored; every `cargo test` (device modules' with a CubeCL feature) | the whole `nice_common` lib suite with `cubecl-cuda,cubecl-spirv`: 265 passed, 0 failed, 123 s at 4 threads |
| (b) device, CI-sized | `cubecl_midout_slice_part_equals_cpu`, `..._shared_parents_slice_part_equals_cpu`, `..._check_rebuilds_the_survivors`, `..._faults_are_loud`, `..._wide_b40_slice_equals_cpu`, `..._wide_b40_faults_are_loud` (+ two timing-stop refusals and both prefilter forms from §M2/S7) | `#[ignore]` + the `cubecl_` prefix: CI's lavapipe WGSL step (`--features cubecl -- --ignored`), its SPIR-V step (`--features cubecl-spirv -- --ignored cubecl_`), both Metal steps | all pass on lavapipe with both compilers: WGSL 2.4 min, SPIR-V 2.7 min in all (faults 79 / 89 s, slice parts ~30 s each, the rest seconds) |
| (c) card or long | whole slices and fields, (4, 8, 5) vs (4, 9, 6), CUDA audits (sweep, key/group independence, OOM, group vs single), full partition, staged-data tests, expansion profile, env-driven full-size parity and faults | feature `midout-box-tests` (in no default or umbrella set; CI never builds them) | §4 (the card tier) |

Tier (b)'s sizes are constants (no environment needed; `MIDOUT_CUDA=1` selects CUDA where the build has it); tier
(c)'s come from the documented `MIDOUT_*` / `AUDIT_*` variables. No test writes to a fixed path: the sweep and the
tops scan write only to `AUDIT_OUT`, which they now require. Lint: `just lint`'s three commands, plus clippy of
`nice_common` with `cubecl-cuda,cubecl-spirv,midout-bench,midout-box-tests`, with `cubecl,midout-box-tests` and with
`cubecl-spirv` alone: all clean (`raw/lint_m1/`).

Not measured: the tier-(b) time on a 4-core GitHub runner (this box has a ~5-CPU quota; the notes' older lavapipe
figures on a 4-core machine were 1.5–3× these).

### M2. The kernels on the compilers CI uses (`a1ddc976`)

**WGSL (naga) on lavapipe: nothing failed.** Every tier-(b) test, base-64 and wide, ran on lavapipe through WGSL as
well as through CubeCL's SPIR-V compiler, first on the trunk's own binary (`raw/wg_trunk`, `raw/wg2_trunk`,
`raw/wg3_trunk`: slice part, rebuild, all faults, b40 slice and b40 faults: all pass; the one early failure, a
wide b40 run that asked for an 889 MB buffer, was my own omission of the 4-classes-per-batch setting, not a WGSL
defect) and then at every commit since M1 (`raw/m1`, `raw/m2`, ...). So no WGSL fix was needed.

**The prefilter form chosen by the runtime's name** (`R::name(&client).contains("spirv")`) is replaced by an
explicit, documented choice: `Caps::prefilter: Option<PrefilterForm>` (`Limbs32` = `pf`, `Limbs24` = `pf24`), with
`None` meaning `PrefilterForm::for_runtime::<R>()`: `Limbs32` on CUDA (decided by the runtime's type, not its
name), `Limbs24` on every other runtime. **This changes what WGSL, Metal and HIP run** (the trunk gave them `pf` by
accident of the name match; `pf24` is the form designed for the non-CUDA compilers). Both forms are exact and both
are now exercised by tier (b) on every compiler CI runs: `cubecl_midout_slice_part_equals_cpu` runs one slice's
first batch with each form; on the card both forms ran on a whole slice (§4).

**Metal: the reading, and one defect fixed.** Production's rule (`scripts/wgsl-lint.py`, `cubecl_detailed_fd.rs`,
`cubecl_join.rs`): Apple's GPU compiler (M4, macOS 26.3) miscompiles an unsigned division or remainder by a
non-power-of-two constant whose dividend is `x >> 16` or a u64's high word. I ran production's own lint over the
WGSL CubeCL generates for **all 27 middle-out kernels** (narrow and wide, dumped by `CUBECL_DEBUG_LOG` from three
tier-(b) tests, `box/wgsllint.sh`): on M1 it **flagged one site** in `hist2` (`parent()`:
`u32(pip >> 32) % 63`, the slice key's high word); fixed by taking the key's low word only (a slice key is 30
bits); on M2: **0 flagged sites in 27 shaders** (`raw/wgsllint_m1`, `raw/wgsllint_m2`). Reading by eye: the narrow
path's other constant divisions are `% 63` of small sums and `% 997` of a root (fault injection only); the wide
path's ~360 constant divisions by `b`, `b²` and `m` (comptime) have limb sums or digit products as dividends, never
a half-width shift (the lint agrees; its header lists what it cannot see, e.g. a shift hidden behind a loop-carried
value). The midout kernels are not in CI's lint `--require` list (adding them is a CI change: proposed, not made).

**What CI's macOS job would exercise** (not run here: no Mac): both of its steps run every tier-(b) test,
`--features cubecl -- --ignored` (WGSL → naga → MSL) and `--features cubecl-metal -- --ignored cubecl_` (CubeCL's
MSL compiler), on the runner's paravirtual Apple GPU, 32-lane planes, `pf24`. Risks I cannot measure: (1) memory:
the paravirtual device hangs above ~1 GiB of command-buffer footprint (`join_plan.rs`), and a base-64 join with 4
classes per batch allocates several hundred MB (not measured on Metal); (2) time: the job's 30-minute limit
already holds 9–16 minutes of production tests, and tier (b) adds about 2.5 minutes per step on this box; (3) the
kernels have never run on any Metal device. Whether midout tests should run on the Metal job at all is question 3
of `PR-PLAN.md`.

## 3. The "should" items (`MAINTAINABILITY.md` §6), in its order

| item | done? | commit | what |
|---|---|---|---|
| S1 narrow/wide duplication | table only (as the read advises) | `35fdb1d6` | `gpu_wide.rs` docs: each base-64 kernel, host function and type → its wide counterpart; the two features the wide path lacks. No shared host driver (later), no generic kernel (the read: a trap). |
| S2 prefilter form by runtime name | done | `a1ddc976` | see M2 |
| S3 long functions without structure | doc part | `5a048669` | `g2_kernel`'s doc lists its phases as the body's `phase 1`…`phase 4` comments name them. **Not done:** splitting `finish_group`'s account checks out (a host restructure; time and the "no taste" rule) and phase headers in `wide_kernel`, `wexpand_kernel`. |
| S4 module-wide lint allowances | rustc part | `d4e1bdf8` | `unused_mut` gone; `unused_assignments` only on the five `#[cube]` modules (CubeCL's comptime branches assign a variable declared before them: 13 sites, all in kernels); host code linted in full. The 35 clippy allowances are untouched. |
| S5 copied production constants | done | `bc46062e` | `RAN_WORDS`, `CHECK_CUBES` made `pub(crate)` in `cubecl_join.rs` (visibility only) and imported; `JOIN_WG` used for the check's cube size. |
| S6 fault bits as a runtime kernel argument | **not done** | — | making them comptime changes every faultable kernel's signature and generated code (production's included), which would need the full M3-style re-verification; left for the PR that carries the kernels. No test switch reaches a release build today (the read's finding stands). |
| S7 `unsafe set_var` in tests | done | `888ec48d` | both tests (tier c) replaced by tier-(b) tests that a join with a timing stop is refused, without touching the environment (the library no longer reads `MIDOUT_STOP`). |
| S8 small doc errors | done | `fa7d9b3e`, `4e50cabd`, `3860818b` | `audit.rs` "every test is ignored" (now the tier list), the bench's "tops on the host", `cpu_slice`'s hard-coded shape. |
| S9 `arith.rs` re-implements nice-ness | done (doc) | `b5ff7e5a` | says why (an oracle should not reuse what it checks). |

Every should-item commit was tested as the combined state `s1` (`raw/s1`, `raw/lint_s1`: tiers (a) and (b) on
both compilers, all lint sets); they touch independent lines, and the last one (`5a048669`) is a doc comment; the
head itself is verified in full in §4.

## 4. What was verified, per commit and at the head

| commit(s) | verified on the box |
|---|---|
| `bedb7c48`, `98d1c213` (M3) | build; CubeCL CUDA source of every kernel normalised and compared with the trunk's (§M3); CUDA: two whole slices n for n, the check's rebuild, every fault loud (`raw/par_m3b`) |
| `2539ccec`, `326ed0a3` (M7, M6) | `just lint`'s three commands + clippy with `midout-bench` (`raw/lint_m67`) |
| `fa7d9b3e`, `b5ff7e5a` (M4, M5) | comments and docs only; fmt; linted and tested with M1's state |
| `4e50cabd` (M1) | tier (a) (`nice_common` lib, CUDA+SPIR-V features: 265 pass) and tier (b) on lavapipe through WGSL and SPIR-V (`raw/m1`); lint incl. the new feature sets (`raw/lint_m1`) |
| `a1ddc976` (M2) | the same (`raw/m2`, `raw/lint_m2`) + production's Apple lint over the 27 kernels' WGSL (`raw/wgsllint_m1` flags 1 site, `raw/wgsllint_m2` 0) |
| `bc46062e` … `35fdb1d6` (S5, S8, S4, S7, S1) | as one state (`raw/s1`, `raw/lint_s1`): tiers (a), (b) both compilers, all lint sets |
| head `5a048669` | everything below, in one session |

**At the head `5a048669`** (one session, 13:21–14:30 UTC; binaries' md5 in `raw/build_logs/fin/bins.txt`):

- Lint: `just lint`'s three commands (fmt, clippy default, clippy `nice_client/gpu,nice_client/cubecl-spirv`) and
  clippy of `nice_common` with `cubecl-cuda,cubecl-spirv,midout-bench,midout-box-tests`, `cubecl,midout-box-tests`,
  `cubecl-spirv`: all clean (`raw/lint_head`).
- Production's CI test commands (`raw/suite_head`): the workspace's `cargo test --locked --release --no-fail-fast`
  (pass), `nice_common --features gpu --lib` (278 pass, 0 fail), `nice_client --features cubecl-cuda` (26 pass).
- Tier (a) (`nice_common` lib with CUDA + SPIR-V features): 265 pass, 137 s at 4 threads. Tier (b) on lavapipe,
  WGSL: 8 tests, all pass, 3.7 min; SPIR-V: 8 tests, all pass, 3.1 min (`raw/head`).
- **The card tier on CUDA** (RTX 3080 at its 240 W cap, `raw/card_head`, every run guarded by the hosts proof):

| test | result | time |
|---|---|---|
| tier (b) on CUDA (all 8) | pass | 114 s |
| slice parity, two whole slices (712012851, 502136830), n for n, every count | equal (11,768,560 / 337,904 and 11,756,699 / 338,191 survivors / checked) | 57 s |
| slice parity, slice 4977728, prefilter forced to 32-bit, then 24-bit limbs | both equal (11,830,109 / 339,922) | 29 s each |
| full-size fault test, slices 502136830 and 0, 63 classes, clean reruns | all five faults loud (four by account, `F_PF_DROP` by the sampled check) | 28 s |
| parent sharing, 128 slices of (4, 8, 5) field 77777: shared = unshared slice by slice; five faults loud | pass | 10 s |
| wide parity, base 65 slice 717171717 | pass (527,041 survivors, 1,701,945 tops) | 102 s |
| wide fault test, base 65, slices 717171717 and 0 | all six loud | 95 s |
| client (default features) `--help` | no line mentions midout (139 lines); `--midout-coordinator` still parses and exits 1 in a build without CubeCL, before any network | — |

## 6. What is left (for the series, not for this branch)

- **Byte-identical generated code** is not a usable proof on CubeCL 0.10 (non-deterministic SPIR-V and IR between
  runs, CUDA declaration order and shared-array placement between builds); the normalised CUDA comparison
  (`box/cudanorm.py`) plus parity and timing is what a PR description can carry for M3.
- **Metal**: not run (no Mac). The midout kernels pass production's Apple lint; the paravirtual device's memory and
  the job's 30-minute limit are the risks (§M2); adding the midout kernels to CI's `wgsl-lint --require` list is a CI
  change I did not make.
- **Tier (b) on a 4-core GitHub runner**: not timed (3.1–3.7 min per compiler here, ~5 CPUs).
- **Decisions this branch kept open on purpose** (the brief): the wide path, the `(4, 9, 6)` coordinate, the client
  route and the claim guard are all still there; the host-tops path is still in the library (bench-only now). The
  `midout-bench` and `midout-box-tests` features are new surface the maintainer must accept (PR-PLAN questions 3
  and 4); without them the alternative is deleting the benches and the box tests from the series.
- **Not done from the read**: S6 (fault bits as comptime), S3's host split of `finish_group`, the shared host driver
  of S1, the 35 clippy allowances of S4, `run_slice` / `run_slice_dev` still `pub` (one slice, not a field).
