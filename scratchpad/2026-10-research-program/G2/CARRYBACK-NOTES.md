# The middle-out join, step 8B: the review's changes carried back into `dev/mo-clean` (2026-11-19, 17:58–19:45 UTC)

Brief `G2/BUILD-BRIEF-8B.md`. Branch **`dev/mo-clean`**, worktree `~/projects/nice/.worktrees/midout-clean`, from
`5a048669` to **`c2152084`** (four commits), on ivory and `fork/dev/mo-clean`. No pull request; nothing to
`origin`; the cut branches `pr/midout-field-coordinate` (`c6d9164a`) and `pr/midout-cpu-ref` (`da7f25c3`) and their
worktrees untouched. Box: Vast 61490977, RTX 3080 at the host's 240 W cap, 16 threads visible (CPU quota ~5), CUDA
12.8 image, Mesa lavapipe (LLVM 20.1.2, 256 bits), Rust 1.100.0 (the pin), `just` 1.59.0 (installed; apt's cannot
parse the justfile). Production hosts mapped to 127.0.0.1 and ::1 at 17:59 UTC before anything was built
(`build8b/raw/proof_hosts_block.txt`; every run script re-checks and saves its own `hosts_proof.txt`). Box scripts
`G2/build8b/box/`, raw logs `G2/build8b/raw/`.

## 1. The commits

| commit | piece | what |
|---|---|---|
| `bb9b12c0` | A | the cut branches' `coord.rs`, `cpu.rs`, `arith.rs`, `mask.rs` plus what the branch needs (§2); getters everywhere; per-file lint allowances |
| `a82ad9db` | B | four comments: `tdig_kernel` → `tdigz2_kernel` / `tdigz_kernel`; base-65 sampled check 70–93 s against 55–56 s (two places); `mod.rs`'s "reported with the shape's label" |
| `07a7c60e` | C | the client route refuses an Apple Metal device; `is_metal` predicate and its unit test |
| `c2152084` | D | the route's panic hook installed before the device context; a recorded panic is checked as soon as the context exists |

**One rule broken, not repairable without amending:** `bb9b12c0`'s subject says "brought up to their reviewed
form", which refers to a review. It was pushed before I noticed; I did not amend. Every other message is clean
(no notes, steps, reviews, agents or models), and every commit has a body and the trailer.

## 2. Piece A: the carry-back, and what remains different from the cut branches

`arith.rs` is now byte-identical to `pr/midout-cpu-ref`'s. The rest of the difference between the branch's four
files and `da7f25c3` is (`build8b/raw/four_files_vs_cut.diff`, 210 + / 60 −):

**`coord.rs`** (API chosen: the cut's two names, extended; no second list function)
- `coord_digits(b)` returns the base's default: `(4, 8, 5)` at 64 **and 65**, `(4, 9, 6)` at **68–70** (the cut:
  base 64 only). Why: `FieldJoin::new` and the wide bench call `Coord::for_base(65)`; the wide tests and benches
  use 68–70.
- A private `const OLDER = (4, 9, 6)`, and `is_known()` = the default **or `OLDER` at bases 64 and 65** (the cut:
  the default only). Why: the device paths, the client's claim check and the (4, 8, 5)-vs-(4, 9, 6) tests still
  accept the older coordinate; whether it is dropped is the maintainer's decision. The branch's
  `coord_digits_known` (a list per base) is gone; of its two callers, the partition audit now iterates
  `[(4, 8, 5), (4, 9, 6)]` and asserts `is_known`, and the client's refusal message names the default and
  `midout:4,9,6` (the route and the client already decided by `is_known`).
- Module docs: the cut's (4, 8, 5) formula stays as base 64's (it is the default); a new "Also known" paragraph
  gives the older (4, 9, 6) formula (`H = 2^21`, bits 24–53 to 45–74) as also known at 64 and 65; "Other bases"
  says bases 65 and 68–70 have padded coordinates for the wide path's measurements (the cut: "here only in
  tests").
- Tests: `only_base_64_has_a_coordinate` → `known_coordinates` (defaults at 64, 65, 68–70; older known at 64/65
  only; none at 10, 40, 62, 63, 66, 67, 71; the cut's refused digit positions kept); `b65_padded` runs both
  coordinates again with the cut's `pad > 0` assertion; the branch's two (4, 9, 6) base-64 tests are back as
  `b64_older_is_the_bit_renumbering` and `b64_older_quantum_fixes_digits_6_to_8`. The cut's three new tests are
  unchanged.
- `with_digits`' doc: "`is_known` says whether a device path searches it" (the cut: "whether it is its base's
  coordinate").

**`cpu.rs`**
- `Shape::label` re-added. **Finding:** nothing on the branch calls it (the route's telemetry writes
  `"shape": [f0, k]`); it stays because the brief lists it; B corrected `mod.rs`'s claim that counts are
  reported with it.
- `b64_slice_vs_staged` (feature `midout-box-tests`, ignored) re-added; `chunks_exact(16)` became
  `as_chunks::<16>()` because the module-wide allowance that covered it is gone.
- `Shape::for_coord`'s doc: also says the rule gives `(4, 10)` for the older `(4, 9, 6)` of bases 64–70.
- Module doc: "a faster search of a field (the device paths, `gpu` and `gpu_wide`)" (the cut: "the GPU path, in
  later changes", false on this branch).
- `Counts` doc: "No ordinary test checks them: only the card-only audits (`gpu::audit`) compare a device's
  `children`, `chunks` and `flat` with these" (the cut: "no test checks them yet", false on this branch, where
  `audit_sweep` and `audit_faults` compare them).

**`mask.rs`**: `Mask::low64` re-added (both impls, with its `cast_possible_truncation` allowance), and the module
doc's sentence on the device paths' words.

**Everything else the cut brought is in**: private `Coord` fields and the eight getters; `prefilter_digits` /
`prefilter_direct` and the fixed brute-force count; the per-base `whole_base_<b>_vs_brute_force` tests with one join
pass; `top_certificate_equals_its_definition`, `roots_equal_production_residue_filter`,
`prefilter_at_base_64_equals_full_digits`; `Counts` field docs; the counter wording in `cpu.rs` and
`FieldOutcome`; `#[must_use]` / `# Panics` attributes, `sl.fill(0)`, `cpu.rs`'s own `many_single_char_names` and
`slice_join`'s `too_many_lines`.

**Outside the four files:**
- Getters: `gpu.rs` (7 calls), `gpu_wide.rs` (18), `audit.rs` (13), `route.rs` (5), the three examples (13),
  the client (4): a regex over `(coord|c|cn|co|c64|c65|c65b).(field)` plus a compile; `wb.b` etc. are `Base`'s public
  fields and stay.
- `mod.rs`: the ten module-wide clippy allowances removed. With them gone, clippy (all feature sets) flagged only
  `manual_midpoint`, `manual_range_contains`, `manual_rotate` in kernel code of `gpu.rs` and `gpu_wide.rs` (added
  to those files' existing allowance lists with the reason: kernel code is not to change), two
  `must_use_candidate` in `route.rs` (`#[must_use]` added) and the staged test's `chunks_exact`.

Proof per commit: `build8b/raw/runs/qA` (A: `just lint`, the three middle-out clippy sets, tier (a) 279 pass /
0 fail / 65 ignored, client with CubeCL 26 pass), `lintB`, `lintC` (+ client route tests), `lintD` (+ client 27
pass); the head in full in §4.

## 3. Pieces B, C, D

**B** (`a82ad9db`, comments only): `gpu.rs`'s main-kernel argument comment named `tdig_kernel`; now `tdigz2_kernel`
(device tops) and `tdigz_kernel` (host-tops path). `route.rs::cpu_check_default` and `WideOptions::cpu_check` gave
"about 70 s against 55 s"; now "70–93 s measured, against a field of 55–56 s", and the route's doc says the check
would set the field's pace, hence off at base 65. `mod.rs` said counts are "reported with the shape's label";
the route reports `"shape": [f0, k]`. Nothing else false was met.

**C** (`07a7c60e`): production has no Metal predicate of its own; it tells devices apart by the name
`CubeclContext::device_name` builds, `"{adapter} ({wgpu backend:?}, {runtime name})"` (`cubecl_backend.rs`
`new_default`), e.g. `Apple M4 (Metal, wgpu<wgsl>)`, and `JoinCeiling::for_device` matches the paravirtual Metal
device by that name. `is_metal(device)` = contains `"(Metal, "` (a wgpu adapter on the Metal API) or `"wgpu<msl>"`
(CubeCL's MSL compiler). `run_blocking` refuses with one sentence: "middle-out: the join has never been checked on
an Apple Metal device (NAME), so this route refuses it", before any claim. Test `metal_devices_are_refused`: three
Metal names (M4, paravirtual, an msl runtime) refused; RADV, lavapipe, DX12 and two CUDA/HIP-style names not.
**Untested on Apple hardware** (none available): the refusal itself has never run on a Mac.

**D** (`c2152084`): done; it is two lines. `install_panic_hook()` moved above the context's creation, and
`no_panic_so_far()?` runs right after it. Consequence, stated in the commit: a panic that context code catches
itself (`cuda_device_name`'s driver probe under `catch_unwind`, which falls back to a placeholder name) now also
stops the route from submitting. That only makes the route refuse more, never submit more, so I judged it safe.

## 4. Piece E: verification at the head `c2152084`

One session on the box, 18:26–19:29 UTC, one thing at a time (`build8b/box/final.sh`), every device run guarded
by the hosts proof. Binaries (`raw/logs/fin/bins.txt`): head `c2152084` bench md5 `270b1722`, test binary `t_box`
`2ddf864d` (contains the new test names, e.g. `b64_older_is_the_bit_renumbering`; the reference's does not);
reference `5a048669` bench md5 **`c24a7700`, byte-identical to the bench this branch's head was timed with earlier
today** (CLEAN-NOTES §5), which is the proof of what it is (the bench does not embed the build string).

| check | result | time | raw |
|---|---|---|---|
| `just lint` (`just` 1.59.0: fmt, clippy default, clippy `nice_client/gpu,nice_client/cubecl-spirv`) | rc 0 | | `runs/lint_head` |
| clippy `nice_common` with `cubecl-cuda,cubecl-spirv,midout-bench,midout-box-tests`; `cubecl,midout-box-tests`; `cubecl-spirv` | rc 0 each | | `runs/lint_head` |
| production's CI: workspace `cargo test --locked --release --no-fail-fast` | pass (nice_common lib 236, client 24, the rest 0-test binaries) | | `runs/suite_head` |
| production's CI: `nice_common --features gpu --lib` | 292 pass, 0 fail, 72 ignored | 124 s | `runs/suite_head` |
| client with `cubecl-cuda` (the route's tests, incl. the Metal predicate) | 27 pass | | `runs/suite_head` |
| tier (a), release (`nice_common` lib, `cubecl-cuda,cubecl-spirv`, 4 threads) | 279 pass, 0 fail, 65 ignored | 124 s | `runs/head/tier_a_release.txt` |
| tier (a), debug (same, `just test`'s profile) | 279 pass, 0 fail | 1,142 s | `runs/head/tier_a_debug.txt` |
| tier (b), lavapipe, WGSL (8 tests) | all pass | 182 s (faults 84, slice part 57, shared parents 30, rest ≤ 7) | `runs/head/b_wg_*` |
| tier (b), lavapipe, SPIR-V (8 tests) | all pass | 188 s (faults 87, slice part 58, shared parents 30, rest ≤ 7) | `runs/head/b_sc_*` |
| card: tier (b) on CUDA (8) | pass | 115 s | `runs/card_head` |
| card: slice parity, slices 712012851 and 502136830, n for n, every count | equal: 11,768,560 / 337,904 and 11,756,699 / 338,191 (the same as at `5a048669`) | 57 s | |
| card: slice 4977728, prefilter forced to 32-bit, then 24-bit limbs | both equal, 11,830,109 / 339,922 | 29 + 30 s | |
| card: narrow fault test (slices 502136830, 0) | all faults loud (`F_PF_DROP` by the sampled check) | 28 s | |
| card: parent sharing + its faults | pass, all loud | 11 s | |
| card: wide parity, base 65 slice 717171717 | pass, 527,041 survivors, 1,701,945 tops | 102 s | |
| card: wide fault test | all loud | 95 s | |
| client (default features) `--help`; `--midout-coordinator` | 0 lines mention midout; exits 1 before any network | | |

The debug tier (a) is 19 minutes because of production's own tests (six production tests run over 60 s; no
middle-out test does). The middle-out tests alone (filter `midout`, 32 tests, 8 ignored): **11 s release, 54 s debug**, all pass
(`runs/head/tier_a_*_midout.txt`), no test over libtest's 60 s warning.

**Kernels unchanged.** CubeCL's CUDA source of every narrow kernel the field path compiles (15 kernels, the
compile-only path of `gpu_slices_equal_cpu` at W 32, `box/dumpcu.sh`), normalised as in CLEAN-NOTES §M3
(`box/cudanorm.py`): **identical md5 for all 15** between `5a048669` and `c2152084` (`raw/dump/*/cu_sums.txt`,
`raw/runs/cu_sums.diff` empty). The wide path's kernels likewise (14 kernels, from the card-tier wide parity test,
`box/dumpwide.sh`): **identical for all 14** (`raw/dump/w_*/wcu_sums.txt`, `raw/runs/wcu_sums.diff` empty).

**The timing**, RTX 3080 at its 240 W cap (mean 230 W over the session including the gaps, SM ~1,590 MHz, at most
72 °C), the bench's defaults (group 16, parents shared, sampled CPU check on), one warm-up field, then five fields
alternating field by field (reference first on fields 1, 3, 5, head first on 2 and 4), 19:22–19:29 UTC
(`raw/runs/five_head`):

| field t | `5a048669` | `c2152084` |
|---|---|---|
| 13107 | 1.7134 | 1.7176 |
| 65536 | 1.7186 | 1.7178 |
| 117964 | 1.7190 | 1.7127 |
| 170393 | 1.7201 | 1.7187 |
| 222822 | 1.7226 | 1.7143 |
| **mean, fs per admissible n** | **1.7187** | **1.7162 (−0.15 %)** |

Inside drift; the kernels' code is identical. **Exactness:** survivors, checked and nice numbers equal field for
field (e.g. t = 13107: 48,226,335,283 / 1,384,994,357, none nice), and all ten sampled CPU checks equal. **This
host is slower than this morning's**: 1.72 against 1.627 fs for the same reference binary (+5.6 %); a different
Vast host (same card model and cap), so compare the two heads with each other, not with the morning's number.

## 5. Piece F: the maintainer's reading material

On ivory, after the push of `c2152084`, in `~/projects/nice/scratchpad/2026-11-midout-design/` (the only place
outside the repository I wrote, besides these notes). Tool: a line mapper through `git diff -U0 5a048669
c2152084` per file (`build8b/box/remap.py`; it flags a ref whose own line changed), then by hand.

- **The map** (`interactive/midout-map.html`): against the new head `check_refs.py` gave 63 BAD of 87 before and
  **0 BAD of 87** after. 67 middle-out numbers in the `N` array moved; one by hand (`[G,4048,'base 64 only']` →
  4053: the line itself changed, `coord.b` → `coord.b()`). The four places naming the head the references were
  checked against now say `c2152084` (sub-title, the panel's note, the refs comment, `repoNote`). Nothing else
  changed; no screenshots re-rendered (the screenshots still show `5a048669` in the sub-title and panel).
- **`DESIGN.md`**: 86 inline refs printed by `print_inline_refs.py`; every number moved by the mapper; the target
  text of all 86 compared before (files of `5a048669`) and after (worktree at `c2152084`): equal except the five
  whose line was itself changed by this step. Of those, by hand: `gpu.rs:4048–4065` → `4053–4065`;
  `coord_digits_known`, `coord.rs:84` → `coord.rs:105` (now `coord_digits`: **the name in the text is out of
  date**); `gpu.rs:281` → `286` (§9, the comment B fixed). Left pointing where they point: `coord.rs:21–24`
  (§9; now the default's formula, the defect it cites is fixed). Head replaced in the opening paragraph and §10's
  first line (not in the timing table's "head `5a048669` 1.6269", a measurement).
- Not touched: `README.md` there also names `5a048669` twice (as the head of the map's line numbers) and
  `tools/check_refs.py`'s docstring says the head "must be 5a048669"; neither is the map or `DESIGN.md`.

**What in `DESIGN.md` §9 and §10 is now out of date** (for you to edit; I changed no wording):

§9:
1. "Metal: never run ... **the code does not do that today** (`client/src/midout_route.rs:163–192` takes any wgpu
   device)": the route now refuses a Metal device (`07a7c60e`, `is_metal`, unit-tested on names); still never
   run on Apple hardware, and the refusal itself is untested on one.
2. "The cleaned branch has not run on the RX 9070 XT ... on the 3080 the cleanup is +0.17 %": still true; the
   carry-back's own 3080 timing is §4 here (kernels' generated CUDA identical).
3. "**The panic hook is installed after the device context is created**": fixed (`c2152084`).
4. "**The first two pull requests' review fixes are not on `dev/mo-clean`**": carried back (`bb9b12c0`), with the
   differences listed in §2 of these notes; the "(4, 9, 6) under Base 64 (`coord.rs:21–24`)" part is fixed.
5. "Smaller: ... a doc comment in `g2_kernel`'s arguments names `tdig_kernel`": fixed (`a82ad9db`).
6. The base-65 sampled-check bullet is unchanged and still true; the code now says the same range (70–93 s).

§10:
1. "head `c2152084`, **14 commits** on the development trunk `66259bb0`": now 18.
2. The file table's line counts (5a048669 → c2152084): `mod.rs` 76 → 62; `coord.rs` 521 → 634; `cpu.rs`
   902 → 1,150; `arith.rs` 132 → 138; `mask.rs` 74 → 75; `gpu.rs` 4,847 → 4,852; `gpu_wide.rs` 4,588 → 4,594;
   `audit.rs` 872 (same); `route.rs` 167 → 170; `wire.rs` 238 (same); `midout_bench.rs` 198 → 203;
   `midout_wide_bench.rs` 175 → 180; `midout_fields.rs` 56 (same); `client/src/midout_route.rs` 415 → 451;
   `scripts/midout_coordinator.py` 164 (same). The `+N/−M` rows (`cubecl_join.rs`, `client_api_async.rs`,
   `lib.rs`, `Cargo.toml`, `client/src/main.rs`, `client/Cargo.toml`) are unchanged by this step.
3. `mod.rs`'s description "module map; the three test tiers" is still right (it lost only the lint list);
   `client/src/midout_route.rs`'s "guards; panic hook" could add "Metal refusal".
4. "For the long version" does not list these notes (`CARRYBACK-NOTES.md`).
5. Elsewhere, not §9/§10: §3 (line 239) quotes `coord_digits_known` at `coord.rs:105`;
   the function is now `coord_digits` plus `Coord::is_known`.
6. Also not §9/§10: §7 says the mutation result was "measured, on the first-PR branch; see §9"; those tests are
   now on this branch too (the mutants were not rerun here).

## 6. Piece G: production's stride table at bases with no valid residue

Scratch clone of upstream main (`/root/up` on the box, `974d7194`, no branch, nothing pushed); the probe and the
failing test appended to `common/src/stride_filter.rs`'s end are in `build8b/box/g_probe.rs` (the clone's diff:
`build8b/raw/runs/g/scratch.diff`), raw output `build8b/raw/runs/g/probe.txt` (all bases; the windows) and
`runs/g/b43.txt`.

**True, and wider than reported.** `StrideTable::new(base, k)` builds an empty table without complaint when no
residue passes; the first use, `first_valid_at_or_after`, panics at `stride_filter.rs:165`
(`self.valid_residues[idx]`) with **"index out of bounds: the len is 0 but the index is 0"**. Measured, for every
base 3–128 with a `u128` range and k = 1, 2, 3 (where the modulus fits `u32`): the table is empty at bases
**4, 5, 7, 15, 19, 23, 27, 35, 39, 43, 47, 55, 59, 63, 67, 75, 79, 83, 87, 95**, at every k. Apart from 4 and 5
(empty by the LSD filter), these are exactly the bases ≡ 3 (mod 4) that have a range: there `b(b − 1)/2 mod
(b − 1)` is odd while `r² + r³` is always even, so the residue filter (`residue_filter::get_residue_filter`) is
empty and the base can hold no nice number at all. Base 15 is one of them, as the reviewer suspected. (Side
finding: `get_base_range_u128(3)` itself panics, "Range has invalid bounds", instead of returning `None`.)

**When a search panics** (`process_range_niceonly`, the CPU nice-only search, k = 3 as the client uses): the MSD
filter runs first and only the ranges it keeps reach the stride walk, so a window panics only if the MSD filter
keeps something. 64 windows of 10^7 n spread over each range: bases 7, 15, 19, 23, 27 panic in 64 of 64; 35 in
55; 39 in 45; 43 in 30; 47 in 23; 55 in 16; 59 in 15; 63 in 6; 67 in 2. Base 43 in 10^9-n windows (32 spread
over the range): 26 of 32 panic. Test `niceonly_search_of_a_base_without_residues_does_not_panic` (bases 19, 23,
27, the first 10^6 n of each, k = 3) fails with the message above.

**Which user-reachable commands hit it** (by reading `974d7194`, except where marked):
- **The client has no `--base`.** Its bases come from the server: a claim (`/claim/niceonly`, `/claim/detailed`)
  or a validation field (`/claim/validate`). Only nice-only work uses the stride table: the CPU path for bases
  outside 40–64 or fields under 10^13 n (`JOIN_MIN_FIELD_SIZE`) goes to `process_range_niceonly` with k = 3
  (`client/src/main.rs` `process_field_sync`), which panics inside rayon and takes the client down. Detailed
  claims never touch it. The GPU nice-only paths build the same table (`GPU_LSD_K` = 3); whether they panic on
  an empty one I did not determine (not run on the card).
- **The benchmark**: no. Its scenarios are fixed (bases 40, 50, 58, 60, 62, `bench_defs.rs`), none empty.
- **`nice_client niceonly --validate`: yes, probably.** `get_validation_field` draws a random field at check
  level ≥ 2 from ids 10,000–50,000, which its own comment says "are all base 42-43"; base 43 is empty, and its
  whole range is 3.6·10^13 n, so any base-43 field under 10^13 n (a quarter of the
  base) goes to the stride walk, where 26 of 32 10^9-n windows panic. Not run against a server (forbidden); the base and size of the fields at those ids are
  the code comment's, not checked.
- **Can the server issue such a base for a claim?** It claims any row of `fields` by id at the requested check
  level, with no residue check (`db_util/fields.rs` `try_claim_field`); bases enter the table through
  `scripts/insert_new_fields.rs`, which checks only that the base has a range. So a nice-only claim of base 43
  (or any base above) is issued exactly when such a base has fields at check level 0; whether the production
  database holds any is not visible from the code (base 43 exists there per the comment above; whether it has
  check-level-0 fields, I cannot see).
- **`scripts/naive_base_search.rs --base B`** (a rust-script, k = 1): yes for every base listed, by reading (it
  calls `process_range_niceonly` on the whole range in chunks).
- Tests and `process_niceonly` (deprecated, k = 1) likewise, for those bases.
