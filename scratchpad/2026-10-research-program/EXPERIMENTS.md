# Experiments

One section per experiment, newest first. Each records: lead id, date, box (Vast id
and GPU, or host), commit(s) under test, exact commands, raw data path, the table,
and the one-line conclusion. Benchmark claims follow PROPOSAL.md §5: same box,
interleaved A/B, ≥3 rounds, median and spread per scenario, no scenario −2 %.

## MO.5 Accounts that prove the work ran (step 3A): every fault the audit showed silent is now loud; cost +2.5 % (2026-11-19 01:25–03:06 UTC, engineer; `G2/BUILD-BRIEF-3A.md`, `G2/BUILD-NOTES.md` §1 and §10, `G2/build3a/`; trunk `dev/middle-out-join` 91ac0761 → c0ad3f4a (merge of dev/mo-audit 7a9fd414, then 197c1e94, a7d3099a, 46c99784, c0ad3f4a; on the fork); box 61286074, RTX 3080 at 240 W)

- **Now loud** [M, test `accounts_faults_are_loud`, on CUDA (two slice sets) and lavapipe at 8 lanes through
  SPIR-V]: dropped main kernel ("main-kernel job instances done: 0, want 8064"); dropped tops ("tops1 valid
  parents examined: 0, want 405593"); a dropped probe ("probes run = 8 x tops: 1906740, want 1910856"); a
  dropped parent ("parents certified (hist2) = listed"); an over-strict prefilter through the sampled CPU check
  (checked 337,845 against 338,191). Everything that was loud before still is.
- **The two reproductions** [M]: a failed device allocation (in-process with 9,216 MiB filled, and a helper
  process holding 7,680 MiB): both slices now fail with "expansion ran 0 of 4096 cubes"; `MIDOUT_STOP` in the
  environment: ignored by the library (the slice gives its full 11,768,560 survivors), and a timing stop set
  through the bench-only call makes `search_field` refuse.
- **Still visible only to the sampled check:** a kernel that does all its work but computes wrongly (a wrong
  certificate, `parent()` mask, child mask, common-mask skip, segment table, or prefilter). Visible to nothing:
  a defect the CPU reference shares; the 64-lane paths (never run on the library path).
- **Cost** [M, one session]: ten fields 1.6505 fs before (the evening's 1.647 repeated) → 1.6911 fs with the
  accounts (+2.5 %, ×3.91 against main's 6.615) and 1.6980 fs with the sampled CPU check as well (+2.9 %,
  ×3.90); survivors and checked equal field for field. Per slice 7.714 → 7.891 ms. The sampled check uses one
  host core for about 27 of a field's 30.6 s and never made the host wait. A first version cost 0.55 ms per
  slice (checks at the kernel's end); once per job before the rounds fixed it.
- **Guards in:** 16-bit class index, 20-bit top index, bounded child list, plane check in the preparation,
  slice count from the device, nice numbers checked to lie in the field, groups capped at 256, MAXPOP's proof
  written at the constant.
- **Left from the audit:** a panic hook that aborts after a runtime-thread panic (belongs to the client route);
  reading back large buffers at start (the accounts catch that failure at the first group); the 64-lane parity
  run; lavapipe at 16 lanes; tops accounts on the host-tops path; the wide kernels.
- **Other checks** [M]: a 100-slice subset of the sweep equal; parity on 5 slices, host-tops path, a part
  slice, probe mode, lavapipe on 2 slices; production's 214 tests; fmt and clippy clean.
- **Conclusion:** end to end ×3.9 on the RTX 3080 with execution proven per stage and one slice per field
  recomputed on the CPU.

## CEIL.1 The pairing of the middle-out join is within ×1.2 of the best any order or skip test can do; the magnitude-of-L idea loses; only the width of a lane's word is left (2026-11-20 06:05–09:20 UTC, engineer + the director's note; `CEIL/BRIEF.md`, `CEIL/NOTES.md`, `CEIL/RESULTS.md`, `CEIL/raw/`, `CEIL/box/`; scratch branch `exp/mo-ceiling` 52120649 on c2152084, on the fork; box 61586715, 20 threads, CPU only, 3.2 h)

- **Instrument** [M]: the CPU reference's own tops, children and classes, re-sorted per variant; on all 12 slices
  (10 at base 64, 2 at base 65) and in every pass its walk equals `cpu::slice_join` field for field (slice
  712012851: 33,705,647 children, 250,486,772 flat visits, 123,163,397 kept (0.4917), 10,929,765 records,
  11,768,560 survivors, 337,904 checked). The lane model reproduces the card's 60.5 % busy lanes (0.6050) with
  the kernel's real rounds of 16 chunks: a probe costs the 16 lanes of a round if any of its chunks keeps it.
- **What a sort key can buy** [M, 8 slices]: kept fraction 1.00, 0.738, 0.593, 0.518, **0.492**, 0.488, 0.488
  for a key of 0, 2, 4, 6, **8 (today)**, 10, 12 bits; lexicographic on the full mask 0.459; greedy clustering
  0.406. Lane slots do not move: lexicographic ×1.0045, greedy ×0.83 (worse). Busy lanes are a property of the
  round, not of the key.
- **The magnitude of L (the new idea)** [M, 8 slices; my prior in `CEIL/NOTES.md` §4 was ×1.0–1.25]: with a
  job's children sorted by L, self-collision of the top's extended certificate kills 0.506 of visits without
  reading a child (prior 0.47–0.55), 2.37 extended digits per visit; but the common masks become empty (0.0003),
  so kept is 0.494 against 0.492 today, and each kept slot ORs 18.7 digits: **work ×0.893 of today's (worse)**.
  Hybrids (j leading bits of L, then the key): best j = 1, ×0.923. Records ÷6.8, survivors ÷7.3 (only the
  expansion, 8 % of a slice, would feel it).
- **Exactness of the extended tests** [M + P]: 1,095,468,692 survivors discarded by the variants (32.8M of them
  passing the prefilter) all taken through brute force on the full digits of n², n³: 0 nice, 0 claim failures;
  monotonicity proof in `CEIL/RESULTS.md`.
- **From the bottom's side** [M]: 0.538 of (child, top digit 10) pairs are dead by the child's own digits
  (prior 0.54); records ×0.48, no visit skipped, one more OR per slot: ×0.94 or less.
- **Sharing ORs between consecutive probes** [M counts, J lane model]: ×1.26 in summed ORs, ×1.13–1.17 once a
  wave pays its slowest stream (×1.16–1.20 by the table's two wave widths).
- **Bounds** [M]: 91.1 % of kept visits produce a zero word; a free and perfect skip test would give ×1.99 at
  base 64 (×1.66 at base 65): the ceiling of the whole skip family in this lane layout.
- **Base 65** [M, 2 slices, all jobs]: today's skip is weaker (kept 0.615, busy 0.711); L order ×1.14, hybrid
  j = 5 ×1.19, with probe sharing ×1.35–1.39 in counted work. The per-(top, cell) certificates it needs cost
  about three times what they save when priced from the tops stage's measured time [J].
- **Verdict by the rule written in advance (×1.3):** **closed.** Best exact variant at base 64 ×1.18 (probe
  sharing with a lexicographic order); at base 65 nothing net of its decision data.
- **Left open, not a count:** chunks of 128 or 256 children halve or quarter the lane slots at the same bytes
  (kept 0.552 / 0.626, busy 0.678 / 0.767): ×1.0 if a slot is bound by shared-memory bandwidth, up to ×2.0 /
  ×3.9 if by instructions; a two-part model from the kernel benchmark gives ×1.33 / ×1.6 [J]. One
  microbenchmark of the word phase on a card decides it.
- **Mutants** [M]: the 27 mutants of the CPU reference rerun on `dev/mo-clean` c2152084: 24 killed (one after a
  quoting fix in the list), 3 survive, the same three as on the cut branch (two change only work counters, one
  edits an exemption no test base reaches).

## SE.2 Independent review of the stride empty-table fix: ready with fixes, nothing must-fix in the code (2026-11-19 20:10–20:35 UTC, independent reviewer; `G2/STRIDE-EMPTY-REVIEW-BRIEF.md`, `G2/STRIDE-EMPTY-REVIEW.md`; branch `pr/stride-empty-residues` 3701a353; box 61490977, own clone)

- **Soundness** [P and M by the reviewer]: the parity argument for b ≡ 3 mod 4 re-derived; the guard fires only on
  an empty table, so it can only turn a panic into an empty result; for bases 3–128 the only empty tables are 4,
  5 and the b ≡ 3 mod 4 bases; brute force over whole ranges finds no nice number at 4, 5, 7, 15, 19, 23, 27
  (control: base 10 gives 69).
- **Paths** [by reading, and 30 client runs against a local stub, all exit 0]: production lookups go only through
  `walk_masked`; the lookups in the GPU files are in test modules; every `--gpu-backend` value goes through
  `begin_niceonly`. **At bases 4 and 5 `--gpu` falls back to the CPU walk (`gpu_route.rs:154–158`) and so
  panicked on main too** (toy bases).
- **Findings:** S1, the test's base-43 field is id 30000, which the MSD filter rejects whole (0 ranges kept; no
  panic without the guard): use 60991418181959–60992418181959 (id 49999), which does panic. S2, wording names
  only b ≡ 3 mod 4; bases 4 and 5 are covered too. Notes: fields of 1e13 or more at bases with a join never
  reached the walk; the changelog line is long; six of the 20 test bases never reach the walk.
- **CI forms in the reviewer's own clone** [M]: `just lint` rc 0; workspace release suite 208 + 24 pass;
  `nice_common --features gpu --lib` 262 pass. The test takes 7.2–7.8 s in debug, 0.65 s in release.
- **Applied 20:43 UTC** [M, the author, same box]: `pr/stride-empty-residues` 3701a353 → **82108efb** (one more
  commit, on the fork): the base-43 field is its own test on 60991418181959–60992418181959 (alone, with the guard
  removed in a scratch copy: the index-out-of-bounds panic, rc 101; with it: pass); bases 4 and 5 named in the
  `# Panics` doc and the changelog line; the changelog line shortened. At the head: `just lint` clean; workspace
  release suite passes (nice_common lib 209, client 24); `nice_common --features gpu --lib` 263 pass; the tests
  take 0.81 s + 0.02 s in release, 7.0 s + 0.16 s in debug. Description: `G2/STRIDE-EMPTY-PR-BODY.md` (244
  words). Not opened: DECISIONS D16.

## SE.1 Production's stride table at bases with no valid residue: a CPU nice-only claim panics; `--validate` does not; no such field exists in production (2026-11-19 19:00–20:10 UTC, engineer on box 61490977, then the director's read-only API check; `G2/CARRYBACK-NOTES.md` §6 and §7, `G2/build8b/raw/runs/g/`, `runs/g2/`; fix branch `pr/stride-empty-residues` 3701a353 on upstream main 974d7194, on the fork, no PR)

- **In the library** [M, upstream main 974d7194]: `StrideTable::new(base, k)` is empty at bases 4, 5, 7 and every
  base ≡ 3 mod 4 with a range (15, 19, 23, 27, 35, 39, 43, 47, 55, 59, 63, 67, …, 95), at k = 1, 2, 3; its first
  use panics at `stride_filter.rs:165`, "index out of bounds: the len is 0 but the index is 0". For b ≡ 3 mod 4:
  n²(n+1) is even, the required residue (b−1)/2 mod (b−1) is odd and b−1 is even, so no residue passes [P].
  `process_range_niceonly` panics only where the MSD filter keeps part of the field (base 43: 26 of 32 windows of
  1e9 n).
- **Through the real client against a local stub serving four real rows** [M; rows read by me from the public
  data API: ids 25000 (base 42), 30000, 40000, 49999 (base 43), each 1e9 n, check level 3]:
  - `niceonly --validate`: **refused before any request** on CPU, CUDA and lavapipe ("Configuration not
    supported: Validation && Niceonly", `client/src/main.rs:1732`). **The engineer's first "yes, probably" and my
    message to the user at about 19:50 UTC that it "may crash about half the time" were wrong.**
  - `detailed --validate` on 30000: runs, no panic.
  - the same rows as `niceonly` claims, CPU: 25000, 30000, 40000 exit 0 with no numbers (the MSD filter rejects
    30000 and 40000 whole); **49999: exit 101, nothing submitted, the panic above**.
  - CUDA and wgpu: fine on all four (`begin_niceonly` answers residue-empty bases through
    `residue_empty_result`).
- **Reach in production** [M, public data API, `/bases`]: the residue-empty bases in the database are 15, 19, 23,
  27, 35, 39, 43, 47, all fully checked (`checked_niceonly` = `range_size`, `minimum_cl` ≥ 2); none above 50
  exists (55, 59 were never inserted). So no check-level-0 field of such a base exists and **no production
  client can hit this today**; it would take inserting such a base (the insert script does not refuse one).
- **Fix** [M]: `walk_masked` returns no numbers for a table without residues before its first lookup; test
  `residue_empty_bases_search_to_nothing` (20 bases at k = 3 and the real field 30000) fails without the guard
  and passes with it; `just lint` clean; production's suite passes (workspace; `--features gpu --lib` 262); the
  fixed client exits 0 with an empty submission on all four claims. Independent review: SE.2 (below, when
  back).

## MO.16 The review's fixes carried back into `dev/mo-clean`; Metal refusal; panic hook first; kernels and speed unchanged (2026-11-19 18:00–19:36 UTC, engineer; `G2/BUILD-BRIEF-8B.md`, `G2/CARRYBACK-NOTES.md`, `G2/build8b/`; `dev/mo-clean` 5a048669 → c2152084 (bb9b12c0, a82ad9db, 07a7c60e, c2152084; on the fork); box 61490977 on m11295, RTX 3080 at 240 W)

- **What changed** [by reading the diff]: `coord.rs`, `cpu.rs`, `arith.rs`, `mask.rs` are the cut branches' files
  plus what the rest of the branch needs (the older coordinate (4, 9, 6) as "also known" at 64/65 via `is_known`;
  coordinates of 65 and 68–70; `Mask::low64`, `Shape::label`, the staged box-only test); `coord_digits_known`
  is gone (`coord_digits` is the default per base). `Coord` fields private with getters everywhere. Four stale
  comments fixed. The client route refuses a device whose name says Metal (`is_metal`, unit-tested on names;
  **not run on a Mac**). The panic hook is installed before the device context.
- **Verification at c2152084** [M, one session, `G2/CARRYBACK-NOTES.md` §4]: `just lint` and three extra clippy
  sets clean; production's suite passes (workspace; `--features gpu` 292; client 27); ordinary tests 279 pass
  (124 s release, 1,142 s debug, of which the middle-out tests are 11 s / 54 s); device tests on lavapipe 8/8
  through WGSL (182 s) and 8/8 through SPIR-V (188 s); on CUDA: slice parity n for n on two slices (counts equal
  to 5a048669's), both prefilter limb forms, both fault tests, parent sharing, wide parity at base 65 and the
  wide fault test, all pass.
- **Kernels unchanged** [M]: the normalised generated CUDA source of all 15 narrow and 14 wide kernels is
  identical between 5a048669 and c2152084.
- **Timing** [M, five warm base-64 fields, alternating field by field, 19:22–19:29 UTC]: 5a048669 1.7187,
  c2152084 1.7162 fs per admissible n (−0.15 %, inside drift); survivors, checked and nice equal field for field;
  10 of 10 sampled CPU checks equal. The box read 5.6 % slower than the morning's box for the byte-identical
  reference binary (same machine id; not investigated): compare heads with each other only.
- **Not done:** the mutants were not rerun on this branch; nothing on the RX 9070 XT or Metal.
- **Process deviation:** the subject of bb9b12c0 says "brought up to their reviewed form" (names a review); not
  amended.

## MO.15 Review of the first two pull requests, its fixes, and the branches as they will be opened (2026-11-19 16:10–17:30 UTC, independent reviewer, then the author, then the director; `G2/PR12-REVIEW-BRIEF.md`, `G2/PR12-REVIEW.md`, `G2/PR12-NOTES.md` §6, `G2/PR1-BODY.md`, `G2/PR2-BODY.md`, `G2/build7p/raw/` (incl. `mut_after/`); box 61441981, destroyed 17:28 after 5.29 h)

- **Verdicts: both "merge with fixes".** PR 1's code needed nothing (bijection, coverage, overflow margins and every
  figure checked by algebra and by the reviewer's own runs); its description had one false sentence (re-cutting
  fields "without searching anything again": a re-cut field is not a union of finished fields) and two overstated
  ones. PR 2's reference is correct as far as tested: its nice numbers equal production's `process_range_niceonly`
  on whole bases 10–29 (base 10 gives [69]); `roots` equals `get_residue_filter` for bases 3–128; the base-64
  prefilter equals full digits on 200k random n; all 11.8M + 11.7M survivors of two real base-64 slices re-check
  true [M, the reviewer's runs].
- **Mutation testing** [M]: 27 mutants; 9 survived the author's tests, among them one that silently drops nice
  numbers (the top certificate's upper part taking position k + 1; only base 10 has a nice number and its
  prefilter is exempt). After three independent tests were added (the top certificate against its definition
  including f0 = 0 shapes; `roots` against production's residue filter; the base-64 prefilter against full
  digits on 100,000 random n): 3 survive, two that change only work counts and one that edits an exemption no
  test base reaches.
- **Other fixes applied:** `Coord`'s values private behind getters; the whole-base test split per base and the
  join run once per base (the midout tests now take 11.3 s in release and 55.2 s in debug, under libtest's
  60-second warning); the `Counts` fields documented and marked untested; descriptions corrected.
- **At the reviewed heads** [M]: `just lint` clean; CI's workspace test command passes (nice_common lib 213 and
  230 passed); `nice_common --features gpu --lib` passes (267 and 284).
- **Branches to open** (made by me with `git commit-tree`, one commit each, trees identical to the reviewed heads
  a695951e and 47222239, so every result above carries over; the development history had an intermediate merge
  that did not compile): **`pr/midout-field-coordinate` c6d9164a** (566 insertions) on upstream 974d7194 and
  **`pr/midout-cpu-ref` da7f25c3** (+1,312 / −3) on top of it; both on the fork; not opened.
- **To do before opening:** shorten the two descriptions (871 and 1,393 words: too long for this maintainer),
  fill PR 1's number into PR 2's.
- **To carry back to `dev/mo-clean`:** the getters across the device, route, wire and client code; the new
  tests; the per-base split; the `Counts` docs (`PR12-NOTES.md` §6).
- **Noted, outside these PRs** [reviewer, not verified by me]: production's `StrideTable` panics at
  `stride_filter.rs:165` for bases 15, 19, 23 and 27 (an empty residue list).

## MO.14 The first two pull requests cut from the cleaned tree (step 7P; 2026-11-19 15:05–16:00 UTC, engineer; `G2/BUILD-BRIEF-7P.md`, `G2/PR12-NOTES.md`, `G2/PR1-BODY.md`, `G2/PR2-BODY.md`, `G2/build7p/`; branches on the fork, not opened: `pr/midout-coordinate` cf27bc89 (on upstream 974d7194), `pr/midout-cpu-reference` 06d55495 (stacked); box 61441981)

- **PR 1, the field coordinate** (520 lines: `midout/coord.rs` 502 of which 213 are tests, `mod.rs` 17, one `pub mod`
  line): six CPU tests, 0.18 s in release. Only the coordinate that fixes digits 5–7.
- **PR 2, the CPU reference** (1,157 lines: `cpu.rs` 941 of which 183 tests, `arith.rs` 138, `mask.rs` 65): the ten
  midout tests take 13.3 s in release (CI's form) and 66–67 s in debug (`just test`), mostly base 25.
- **Both heads** [M, on the box]: `just lint`'s three commands clean; CI's workspace test command passes (nice_common
  lib 213 and 217); the `gpu` feature's lib tests pass (267 and 271). No features, dependencies, ignored tests,
  dead-code allowances or changelog line.
- **A test gap in the cleaned tree, found and fixed** [M]: the brute-force test counted `checked` with the
  reference's own prefilter, so a wrong prefilter rule passed it (shown: a prefilter that ignores the top's
  digits passes on the pre-fix head). A direct recomputation from the full digits of n² and n³ now fails that
  fault. Two other one-line faults fail before and after.
- **Changes against the cleaned tree to carry back** (`PR12-NOTES.md` §2): the coordinate module's docs still gave
  the old definition's formula (rewritten); `coord_digits_known` → `coord_digits`; ten module-wide lint allowances
  replaced by two narrow ones; the box-only staged test, `Shape::label` and `Mask::low64` left out.
- **Review:** an independent reviewer started 16:10 UTC (`G2/PR12-REVIEW-BRIEF.md`, the same box, to 17:40): the
  diffs read cold, the reference against production's CPU search and by mutation, the descriptions.

## MO.13 The branch cleaned for review: seven must-fix items done; exactness and speed unchanged (step 6C; 2026-11-19 12:15–14:52 UTC, engineer; `G2/BUILD-BRIEF-6C.md`, `G2/CLEAN-NOTES.md`, `G2/build6c/`; branch `dev/mo-clean` 5a048669, 14 commits on the trunk's 66259bb0, on the fork; box 61441981, RTX 3080 at 240 W)

- **M3** (prototype switches out of the narrow main kernel): eight fixed comptime switches, their dead branches and
  an unused argument removed; the launch passes only the plane width and the fill. Byte identity cannot be shown on
  CubeCL 0.10 (two runs of one binary give different SPIR-V and IR; two builds give different CUDA declaration order
  and shared-memory placement [M]); the proof is CubeCL's CUDA source compared after normalising exactly those
  things: the main kernel differs by three dead selects, one repeated comparison and eight zero or copy
  assignments, every other kernel is identical; plus parity, fault tests and timing.
- **M4** a stage table (what each stage proves, what the host compares it with) and the data layouts in both device
  modules. **M5** every reference to notes, step labels, dates, machines and prototype flags replaced or removed
  (the grep is empty). **M6** part-field, timing and stop functions behind a feature `midout-bench`; host-tops
  options crate-private; the route accepts bases 64 and 65 only. **M7** the client flag hidden from `--help`.
- **M1** three test tiers, documented in the module docs: ordinary CPU tests; eight device tests named
  `cubecl_midout_*` that CI's lavapipe jobs select; card-only and long tests behind a feature `midout-box-tests`;
  nothing writes to fixed paths. Found on the way: an ordinary test of the trunk (`audit_coord_slices_partition`)
  assumed the old coordinate and failed: CI would have gone red; fixed.
- **M2** the device tier passes on lavapipe through WGSL (naga) as well as SPIR-V: nothing failed. The prefilter
  form is now an explicit rule (32-bit limbs on CUDA, 24-bit elsewhere), which changes what WGSL, Metal and HIP
  would run; CI tests both forms. Production's Apple lint over all 27 midout kernels found one of the known
  miscompile patterns (`u32(pip>>32) % 63` in the preparation): fixed, the lint reports 0. Metal itself not run.
- **Should items:** seven of nine done (among them the production constants now shared, not copied).
- **At the head** [M]: `just lint` and the new feature sets clean; production's CI test commands pass; 265 ordinary
  tests; the device tier on lavapipe in 3.7 min (WGSL) and 3.1 min (SPIR-V) and on CUDA; the card tier on CUDA
  (two whole slices n for n, both prefilter forms, the fault tests, sharing with faults, base-65 parity and
  faults). **Timing** [M, eight alternating runs in two blocks]: 1.6269 fs at the head against 1.6242 at the
  trunk (+0.17 %, inside the 0.4 % drift between blocks); per-stage times equal; every count equal (80 of 80
  sampled checks).
- **Not verified:** the cleaned head at 64 lanes on the RX 9070 XT (the lease measured the trunk before the
  cleanup); Metal.

## MO.12 The library path on the RX 9070 XT: exact at 64 lanes; ×4.79 against main end to end; the client route run there (2026-11-19 13:55–14:29 UTC, director, demoux under the user's 2-hour lease (35 minutes used); `G2/WINDOW-PLAN-2.md`, `G2/build4s/window_1119/` (go.out, 45 logs and samples, `route/` with the coordinator's records and the client log); builds on demoux from the bundle: trunk 66259bb0 with `--features cubecl-spirv`; Mesa 26.1.6 RADV; production client stopped by the user and never touched)

- **Exact at 64 lanes** [M]: "the device path ran at W 64"; seven narrow slices in three processes (four through
  the shared depth-8 lists), device tops = host tops and n-for-n parity against the CPU reference; the wide path at
  b40 and b65; the fault test; one whole field under the old coordinate with the sampled CPU check: all pass.
- **Whole base-64 fields, pipelined, five fields per run after a warm-up** [M]: 0.9953, 1.0054, 0.9714 fs per
  admissible n at 2,82–2,88 GHz and 303 W (about 210 busy samples each); survivors and checked equal field for
  field across runs.
- **Main in the same session** [M]: field 2 in 91.60 s and field 6 in 101.92 s (11-18: 90.83, 100.41), at
  3,12–3,14 GHz and 304 W: base mean 4.707 × 1.0118 = 4.762 fs.
- **Ratio: ×4.79 (median of three runs; best run ×4.90)**; the offline model had said ×4.87 (band ×4.54–5.25).
  Outcome T1 of the plan.
- **Stage profile, field 77777, ms per slice by cumulative stops** [M, the first two off the operating point]:
  tops 0.759 and parents 0.476 (both measured with the card at about 1.55 GHz and 90 W, since those stages alone
  do not load it: not comparable with the model's 0.12–0.24 and 0.31–0.35); main kernel 2.607 (model 3.09–3.35);
  expansion 0.356 (model 0.43–0.56); check and the rest 0.112; whole slice 4.312 ms (model 4.01–4.64).
- **Sampled CPU check** [M]: slice equal; an 18.45 s field with the CPU thread busy 9.22 s; the host never waited.
- **Wide path, base 65** [M, two fields including the warm-up]: 3.117 fs per admissible n, about ×3.2 of base 64
  on this card (×2.17 on the RTX 3080): the wide kernels are untuned for this card (shared memory over the
  12-wave threshold, MO.7).
- **The client route on the card** [M]: `nice_client` built with `cubecl-spirv`, a local coordinator on
  127.0.0.1 with twelve base-64 fields under (4, 8, 5): all twelve claimed, searched and accepted, 17.92–18.61 s
  each (median 18.16 s = 0.992 fs per admissible n), exit 0. For the seven fields the benchmark also ran, the
  route's survivors and checked equal the benchmark's; field 77777's (48,216,914,309 and 1,384,731,444) equal
  the RTX 3080's of MO.9: the counters are device-independent across CUDA at 32 lanes and RADV at 64. I read the
  route's code before running it there: it checks the address against the production domain and sends every
  request to the coordinator's address only.
- **Conclusion:** on the card that does 86 % of the search the middle-out join is exact and ×4.79 faster than
  v3.4.8's join at base 64, end to end, tops and checks included, and it runs as a client against a local
  coordinator. Base 64 on that card alone: 4.83e21 admissible n × 0.99 fs ≈ 55 days against ≈ 266 at main's
  4.76 fs [D].

## SRA.5 PR #270 merged; its tests on the RX 9070 XT; a test of #263 that forces a form production never uses there (2026-11-19 14:01–14:28 UTC, director, same lease; `G2/build4s/window_1119/p_pr270.log`, `p_qtest.log`; fix branch `pr/queue-test-plane-width` fd33d84d on upstream 974d7194, local, not yet reviewed or pushed)

- **The user merged #270 at about 14:00 UTC** (upstream 974d7194) before the tests on a Vulkan card had run.
- **On the card** [M]: `cubecl_dropped_launches_fail_the_field` (the new test) passes on all three stride paths
  including the plane-scoped queue: the new count works at 64 lanes. `cubecl_queues_check_every_survivor_on_
  partly_filled_planes` (from #263, 2026-11-15) **fails**: all 16 runs that force the ballot form fail the queue
  account loudly ("checked −38 … −10,145 fewer survivors than they queued"), and all 16 scan-form runs are
  exact (30,449 of 30,449).
- **Cause** [read]: production picks the ballot form only where a plane fits one ballot word
  (`ballot_append(plane_size_max) = plane_size_max <= 32`, `cubecl_join.rs:195`); on this card (64 lanes) it
  takes the scan form. The test (mine, in #263) forces both forms on every wgpu device. A defect of the test,
  present since 11-15, never seen because the test had only run on lavapipe (8 lanes) and CUDA (32). Production's
  stride path on the card is the scan form, which passes; the failure mode of the forced ballot is loud.
- **Fix** (12 lines, test only): run the ballot form only where `ballot_append` allows. With it, on the card:
  32 runs, 0 wrong; both tests pass. To be reviewed, then opened as a small PR.

## MO.11 A maintainability read and a pull-request plan for the branch (2026-11-19 11:57–12:07 UTC, independent reviewer, ivory, read-only; `G2/PRPLAN-BRIEF.md`, `G2/MAINTAINABILITY.md`, `G2/PR-PLAN.md`)

- **Size, corrected:** `git diff --shortstat origin/main...HEAD` at 66259bb0 is **13,300 insertions in 20 files, 49
  commits** (I had been saying 6,500 to 7,000): the wide path is 4,516 of them and tests about 2,800.
- **Must fix before any pull request** (file and line in `MAINTAINABILITY.md` §1): (M1) CI would fail or time out:
  its lavapipe and Metal jobs run every ignored test in nice_common, and the branch adds 17 written for a CUDA
  box (two need staged data that is not in the repo, one writes to /root, several run whole fields, one exceeds
  lavapipe's binding limit); (M2) the kernels never ran through WGSL (naga) or Metal, the compilers CI uses, and
  CI's SPIR-V step filters on a name no midout test has; the prefilter form is chosen by the runtime's name;
  (M3) the narrow main kernel carries 10 comptime switches and about 15 dead branches from the prototype, launched
  with bare literals; (M4) the data layouts are written down nowhere and the module docs are stale; (M5) 56
  references to notes outside the repository and about 40 step labels; (M6) public functions that can return
  something that is not a whole, checked field; (M7) the client flag shows in every release build's `--help`.
- **Fine as it is:** no test switch can reach a release build; the edits to production files add behaviour
  without changing any (two private constants are copied and could drift). 27 % of the wide file is verbatim
  copy of the narrow one and 19 host functions exist twice: one generic kernel in CubeCL 0.10 is judged a trap,
  a shared host driver worth doing later.
- **Proposed series** (`PR-PLAN.md`): 1 the field coordinate (CPU, ≈ 530 lines); 2 the exact CPU reference
  against brute force (≈ 1,090); 3 device tops (≈ 1,000); 4 one slice on the device with accounts (≈ 3,050);
  5 a whole field and the sampled CPU check (≈ 700); 6 parent sharing (≈ 450); then, each needing the
  maintainer's yes: 7–10 a bench example, the claim guard, the client route and flag, the coordinator script
  (≈ 2,000); 11–12 the wide path (≈ 4,650). Stop points after 2 and after 5 or 6. Built as fresh commits from a
  cleaned final tree, the branch kept as the archive. A first series without the wide path, the old coordinate,
  the host-tops path, the timing functions and most of the audit harness is about 5,500 code and 1,400 test
  lines.
- **Seven questions for the maintainer** (in the report).
- **Acted on:** step 6C (cleanup on `dev/mo-clean`, `G2/BUILD-BRIEF-6C.md`) started the same hour.

## MO.10 The 64-lane pre-flight repeated at the new head; card memory; predicted ×4.87 (2026-11-19 10:50–11:56 UTC, the offline engineer resumed, ivory only; `G2/BUILD-NOTES.md` §14, `G2/build4s/preflight_h5l.md`, `G2/WINDOW-PLAN-2.md` (top section), `G2/build4s/window/`, `G2/build4s/window_dryrun2/`; trunk e09ad7b0 → 66259bb0 (one test-only commit), on the fork)

- **Pre-flight** [M, static]: every kernel of both paths compiled for 64 lanes, validated and run through ACO for
  GFX1201. The new `anc8_kernel`: 48 VGPRs, 32 waves, 148 VALU cycles, plane check present, the ballot's second
  word handled at 64 lanes: about 0.002 ms per slice. The wide expansion with the base-b² prefilter: 1,193 → 771
  cycles in the prefilter loop, 60 → 48 VGPRs, 24 → 32 waves. Everything else within 2 % of the earlier listing.
  Nothing found that would stop a window; nothing needed fixing.
- **Card memory per join** [D from buffer sizes; peak estimated at the 1.93× the 3080 showed]: b64 with sharing:
  2.56 GB of buffers (870 MB the shared lists), peak ≈ 4.9 GB; b65 wide: 4.30 GB, peak ≈ 8.3 GB. Both fit a
  10 GB and a 16 GB card beside production's 2 GiB budget. Untested: the largest single buffer (the b65 child
  list, 1.1 GB) has never gone through wgpu / RADV; a refusal would be loud.
- **Model** [P]: parents 0.48–0.52 → 0.31–0.35 ms per slice; slice 4.01–4.64 ms = 0.97 fs per admissible n:
  **×4.87 against the card's main, band ×4.54–5.25**; the main kernel binds (74 %).
- **Window plan** (22 minutes, 24 with PR #270's tests as an optional step 0 from their own binary): exactness
  on seven slices (four through the shared lists, three unshared under (4, 8, 5)), the wide path alone
  afterwards, one whole field under the old coordinate with the sampled CPU check; timing on the same field
  indices under the new coordinate; outcomes T1 ≥ ×4.54, T2 ×4.0–4.54, T3 < ×4.0. Dry run on lavapipe: every
  step rc 0; PR #270's two tests pass there. Not exercised in the dry run: sharing inside a whole bench field.

## MO.9 Fields that fix digits 5–7, parents shared across digit 8, the wide prefilter in base b²: ×4.09 on the RTX 3080 (step 5L; 2026-11-19 08:40–10:40 UTC, engineer; `G2/BUILD-BRIEF-5L.md`, `G2/BUILD-NOTES.md` §1 and §13, `G2/BUILD-NOTES-CLIENT.md` §11, `G2/build5l/`; trunk cc0a9e04 → e09ad7b0, seven commits, on the fork; box 61386517, RTX 3080 at 240 W, destroyed 10:45 after 4.99 h)

- **The coordinate (4, 8, 5)** (default at bases 64 and 65 since 4925122a; (4, 9, 6) still supported, and the
  default at 68–70): a base-64 field fixes digits 5–7 of n, still a bit permutation, still 262,144 fields of 2^57,
  4,096 slices of the (4, 10) join each; digits 4 and 8 free inside a field. **Exact** [M]: all 4,096 slices of
  (4, 8, 5) field 77777 equal the same slices run inside the 64 (4, 9, 6) fields that hold them (48,216,914,309
  survivors, 1,384,731,444 checked in total); at base 65, 195 slices of field 13731 likewise and the whole field
  through the production path; coordinate tests (bit permutation, padded form, whole slices); three slices
  against the CPU reference number for number; the client route claimed and submitted four fields in both
  coordinates, counts equal to the library's.
- **Parent preparation shared across digit 8** (on by default since 7e682f05): 64 depth-8 lists per field,
  covering 20.3 % of the roots (FS.1 counted 21.9 %); each slice's parent pass runs over its list; 870 MB of card
  memory. Every count equal with and without it; the new fault switch `F_SKIP_ANC` is loud and the old ones stay
  loud; checked number for number against the CPU reference on CUDA (4 slices) and on lavapipe at 8 lanes.
  **Worth** [M, 240 W, one session]: parents 0.728 → 0.525 ms per slice, slice 7.766 → 7.568 ms; ten fields
  1.6706 → 1.6189 fs per admissible n (−3.1 %; FS.1 derived ≈ 3 %): **×4.09 against main's 6.615**.
- **The wide prefilter in base b²** [M]: exact by brute force (17 shapes) and on b30–b65 slices on CUDA and
  lavapipe; saves only 0.31 of the 3.61 ms base-65 expansion (3.565 → 3.498 fs). A run with no prefilter at all
  gives 3.64 ms: **MO.6's "the prefilter adds 2.6 ms to the wide expansion" was wrong**; the cost is elsewhere in
  that kernel and wants a probe build before more code.
- **Base 65 against base 64 at the head** [M, one session]: 3.468 / 1.600 fs = ×2.17 (MO.6: ×2.08 against a
  slower base 64): 0.48 card-years for base 65 on this capped card.
- **Head state** [M]: GPU tests, fmt, four clippy sets, production's suite (221 passed), client tests (24, 26).
- **Not built:** parent sharing on the wide path (estimated −0.4 ms per b65 slice); (4, 8, 5) at bases 68–70; a
  whole shared field on lavapipe (one slice ran there). **Not yet through the 64-lane pre-flight** (the offline
  engineer is re-running it at this head).

## MO.8 A client route against a local coordinator: 26 fields end to end, every guard tested; the trunk exact on CUDA at ×3.94 (step 4F; 2026-11-19 05:50–08:28 UTC, engineer; `G2/BUILD-BRIEF-4F.md`, `G2/BUILD-NOTES-CLIENT.md`, `G2/build4f/`; branch `dev/mo-client` cc0a9e04 (six commits on 4abfab5c and a merge of the trunk's 9b790647), fast-forwarded into the trunk by me at 08:30 and pushed; box 61386517, RTX 3080 at 240 W)

- **What runs** [M]: a local coordinator (`scripts/midout_coordinator.py`, standard library, 127.0.0.1, state in
  files, resumable) served 24 base-64 fields spread over the base and two base-65 fields; one client process
  (`nice_client niceonly --midout-coordinator URL --repeat`) claimed, searched and submitted all 26. All recorded
  results equal the library's own for the same fields (survivors, checked, slices, nice numbers); all 24 sampled
  base-64 slices equal the CPU reference. Three rounds (two wire forms, then after the merge), all equal.
- **Wire:** production's claim and submit format plus one addition: the claim names its coordinate,
  `"coordinate": "midout:K0,K1,Q0"` (`midout:4,9,6` at base 64 today); the client builds its coordinate from it
  and refuses one its device path was not built for (`midout:4,8,5` is refused today, by test).
- **Guards, each with a test and a negative run that exits non-zero with nothing submitted** [M]: the production
  API refused by name (three spellings); every ordinary route (nice-only GPU and CPU, detailed CPU and GPU)
  refuses a field marked as coordinate-space; misaligned field, wrong size, unknown coordinate refused; failed
  accounts (main kernel dropped); failed sampled CPU check (prefilter fault); a runtime-thread panic (hook);
  a memory hog holding 7.5 GB; the coordinator never hands a field out twice (also across a restart), rejects a
  submission whose route is not `midout` and a second submission for a field.
- **The route's cost** [M, same session]: 1.6935 fs per admissible n through the client against the library's
  1.6914 (×1.001; the other round ×0.9999); + 2 s once when the route switches from base 64 to base 65.
- **Default client unchanged** [M]: common suite 217 passed, client suite 24 / 26; fmt and clippy clean on three
  feature sets; on the stub the trunk's client and this branch's give equal submissions on five routes. The route
  touches production files additively: `client/src/main.rs` (+24), `common/src/client_api_async.rs` (+52/−2: the
  refusal at the ordinary claim).
- **The trunk's 4S changes on CUDA** [M]: exact (slice parity on 5 slices, `accounts_faults_are_loud` with
  yesterday's account values to the unit, wide parity at bases 30–65, the wide fault test, probe, stop-variable
  and in-process OOM tests). Ten-field base-64 timing: 1.672 fs without the sampled check (yesterday 1.691),
  1.681 with it: **×3.94 against main's 6.615**; every field's counts identical to yesterday's.
- **Not done:** several clients on one coordinator; a coordinator on another machine; long runs; the route on
  Vulkan; bases 68–70; the sampled check at base 65 (off: its CPU slice is too slow); no overlap between fields
  (the client claims the next field only after submitting the last); the panic hook is installed after the
  device context is created.

## MO.7 The library path prepared offline for the RX 9070 XT: clean at 64 lanes as far as can be told; predicted ×4.69 (step 4S; 2026-11-19 05:50–07:55 UTC, engineer, ivory only; `G2/BUILD-BRIEF-4S.md`, `G2/BUILD-NOTES.md` §12, `G2/WINDOW-PLAN-2.md`, `G2/build4s/` (SPIR-V and ACO listings, `preflight_*.md`, `model_4s.py`, exactness logs, the window driver and its dry run, a bundle); trunk 4abfab5c → 9b790647, seven commits, on the fork)

- **Pre-flight at 64 lanes** [M, static]: every library kernel compiled for plane width 64 without a device
  (`MIDOUT_FORCE_W=64` through a test-only `with_width`), run through `spirv-val` and through ACO for GFX1201
  (Mesa 26.0.8 RADV on drm-shim): 14 narrow kernels including production's check, 12 of 13 wide kernels at b65.
  No spills, no scratch, all wave64 except the 32-thread done kernels; the main kernel has the tuned prototype's
  shape (120 VGPRs, 21,504 B shared memory, 12 waves). `spirv-val` passes with two features RADV has, except
  for a duplicate ArrayStride decoration CubeCL emits in `scatter3` / `wscatter`, which lavapipe and RADV's
  front end accept. Code reading found no plane-width or lane-0 assumption that 8 or 32 lanes would have hidden.
  The wide kernel's ballot rows have never run at 64 anywhere. The one risk only the card can settle: RADV
  choosing wave32 (the plane checks and accounts would catch it).
- **Model** [P]: slice 4.17–4.80 ms, 1.00 fs per admissible n, **×4.69 against the card's main (4.707 fs), band
  ×4.38–5.04**; the main kernel binds (3.09–3.35 ms, 72 %), then preparation 0.48–0.52, expansion 0.43–0.56,
  tops 0.12–0.24, check 0.04–0.08. The same model gave ×4.32 before this step's changes.
- **Changes**, each exact first on lavapipe at 8 lanes (two-slice parity n for n and the fault test) [M counts]:
  `scatter3`'s children count in 32-bit operations (1,317 → 956 VALU cycles); the expansion's prefilter in one
  loop over both records of a take (4.55 → 3.68 rounds per take); on the SPIR-V path one-hot digits by 64-bit
  shifts and the prefilter in 24-bit limbs (290 → 197 cycles per round); CUDA keeps its measured form. Also a
  defect fixed: a `cubecl-spirv`-only test build did not compile. New `search_field_part` / `time_field_part`
  and `--slices K` for dry runs; `search_field` and `FieldOutcome` unchanged.
- **Checks at the head** [M]: lavapipe parity on six narrow slices, the fault test, wide parity at b40 and b65
  and the wide fault test; production's 214 tests; fmt and clippy clean. **None of the changes has run on
  CUDA** (the client-route engineer runs the device tests and the ten-field timing at the merged head today).
  Release builds on ivory needed LTO off (fat LTO was OOM-killed on 7 GB).
- **Window plan** (`WINDOW-PLAN-2.md`; driver dry-run end to end on lavapipe): build beforehand; exactness at 64
  lanes first (six b64 slices, the wide path at b65, the fault test; about 4 minutes; any failure stops it);
  two rounds of five whole b64 fields around main's bracket fields 2 and 6 in one session, the stage profile
  and the sampled check's cost; about 20 of 45 minutes; stop line ×4.0.
- **Not done** (about 1 % each or needing the card first): four records per lane in the expansion; tops in
  32-bit limbs; u16 child lists; the wide kernel's shared memory (3 KB over the 12-wave threshold).

## SRA.4 The hand-written CUDA backend under an allocation failure: no false empty found (2026-11-19 05:47–07:20 UTC, engineer; `SRA/HC-BRIEF.md`, `SRA/HC-RESULTS.md`, `SRA/raw/hc/`; box 61386568, RTX 3080 20 GB at 220 W, driver 580.126.09, destroyed after the run; clients v3.4.5 (auto backend) and upstream main 71eb5fc (`--gpu-backend cuda`, `NICE_JOIN_ROUTE=stride`), local stub only, production hosts blocked and proven)

- **Code** [read, v3.4.5 and main]: every device call ends in `?` (context creation, NVRTC and module load,
  residue upload, per-field buffers, descriptor uploads, `cuLaunchKernel`, event syncs, readbacks); errors from
  `begin_field` and `launch` go to the dispatcher's `first_error`, the next field's end takes it and the field
  fails; `wait` synchronises the end event, which also returns faults from inside a kernel; any `Err` exits 1.
  An all-zero result cannot be told from a kernel that did not run (the count starts at 0), so the protection
  is that CUDA reports each failure and the client propagates it.
- **Card** [M, 88 runs]: the four base-54 1e13 fields of the census with the most work left, and a base-10
  control containing 69; memory squeezed before start at many sizes, a few seconds in, between fields, and by a
  greedy hog that takes whatever the client frees. **No false empty:** base-54 results equal the healthy runs;
  all of about 228,000 control fields returned `[69]`. Allocations can only fail at three points (the process
  keeps about 256 MiB in cudarc's pool from its first allocation): context creation; the first nice-only
  allocation (255 MiB free fails, 256 works); on main, a later plan upload for a new base. Each was reached and
  each ended in exit 1 with nothing false submitted.
- **Not covered:** allocation failures inside a field once the pool exists (could not be provoked); failures
  that are not allocations (launch errors, kernel faults, Xid, resets: the code propagates them; not producible
  without code changes); one card and driver.
- **Also:** when v3.4.5's auto selection cannot create the CUDA context it moves on at info level to CubeCL on
  wgpu; such runs would be labelled `cubecl`, so the census's 15,046 `cuda` rows did run this backend.
- **Conclusion:** the 15,046 stride submissions on the hand-written backend are not exposed to the failure that
  PR #270 fixes. With SRA.3, the defect has no known effect on any production result. Still unmeasured: the
  wgpu runtime under memory pressure on a real card (by the code, the failed launch surfaces at the next sync).

## FS.1 The field structure attacked: not shown wrong; fix digits 5–7 instead of 6–8 (≈ 3 %); fields can be re-cut without redoing search (2026-11-19 05:45–06:13 UTC, independent reviewer, ivory CPU; `G2/FS-BRIEF.md`, `G2/fs/REVIEW.md`, `G2/fs/proto/` (prototype copy with a `levels` command), `G2/fs/code/`, `G2/fs/raw/`)

- **Question (the user's, 2026-11-18):** does the new field structure tie the project to one implementation or
  block later optimisations ("a hill climb to a local optimum")?
- **Proven (by the definitions):** (1) any join that splits n into a top part and a bottom part sees every digit
  of n on one side, so a field defined by fixing digits of n is a list-level filter for today's overlap join and
  for every middle-out variant; (2) any field whose fixed digits lie in 4–8 is a union of whole slices, so shape,
  kernel, chunking, pairing and mask width stay free, and **fields can be re-cut later without redoing any
  search** (only the server's rows change).
- **What a field can influence at all** [M stage times, D]: tops and parent preparation: 13 % of a slice at b64,
  23 % at b65; so no grouping of the same work beats another by more than ×1.15 (b64) / ×1.30 (b65); the kernel
  (71 %) costs the same under every definition.
- **The one real loss found:** slices that differ only in digit 8 could share their parents' preparation, and
  fields fixing 6–8 scatter them over 64 fields. **Fields fixing 5–7** (coordinate (4, 8, 5), the same 262,144
  fields of 2^57 at b64, still a bit permutation) leave digits 4 and 8 free: tops share across digit 4 (built),
  parents across digit 8. Exact counts: the per-slice root pass falls to 21.9 % (b64) / 22.4 % (b65) of its
  size against 76.8 % / 77.1 % for the best that 6–8 allows [M]. Price ≈ 3 % net at b64, 3–4 % at b65 [D/G; no
  card measurement]. Memory 0.48 / 0.59 GB of root indices.
- **Alternatives priced** [M counts, D costs]: the k = 9 shape has ×1.9–2.0 the pairs and kept words; contiguous
  n fields break even with today's main only at ≥ 1/18 of the base; leading-range × middle rectangles lose about
  15 % per halving; keys on low digits, residues or classes rebuild one side per field; coarser fields (fix 7–8)
  make a b65 field 62 minutes on a 3080 (past the one-hour claim); finer (fix 5–8) means 16.8M fields; hashed
  slices lose neighbour sharing; a three-way join with the middle enumerated is this structure; one parent
  order shared by 64 slices costs +4.2–7.0 % kept words [M].
- **Corrections to the engineers' permits / forbids list** (`BUILD-NOTES.md` §2): parents are shared across
  digit 8, not digit 4; "forbids k ≤ 9 / f0 ≥ 7" is overstated (+0.15 fs for (4, 9)); today's join *can* search
  such a field by restricting its tops, at about ×1.9 without its leading-digit prune; changing the coordinate
  after fields exist costs bookkeeping, not compute.
- **What would falsify it:** a search method that is not a prefix–suffix join (BX found none: negative evidence,
  not proof); fields forced down to ≲ 64 slices (for example for CPU clients); a card measurement showing
  preparation sharing worth much more than derived.
- **Not done:** no card measurement of the depth-8 sharing; no trunk run with (4, 8, 5); whether a shape that
  varies across the base pays (unpriced); CPU clients.
- **Conclusion:** the commitment is weaker than feared: within the top/bottom family it is reversible in compute
  terms and bounded at ×1.15–1.30 in what it can cost. Adopt 5–7 unless a card measurement says otherwise; the
  coordinate stays a per-field parameter on the wire (told to the client-route engineer the same hour).

## MO.6 One trunk: the wide kernels merged and brought level; base 65 is ×2.08 of base 64 (step 3W; 2026-11-19 03:15–04:48 UTC, engineer; `G2/BUILD-BRIEF-3W.md`, `G2/BUILD-NOTES.md` §1 and §11, `G2/build3w/`; trunk `dev/middle-out-join` c0ad3f4a → 4abfab5c (merge 23ce3cf6 of dev/mo-wide, f246d9fd accounts and guards on the wide path, 4abfab5c top hierarchy and prefilter on the wide path; on the fork); box 61286074, RTX 3080 at 240 W, destroyed 04:50 after 12.1 h)

- **State of the head** [M]: fmt and clippy clean (default and GPU features); production's 214 tests pass; the
  trunk's fault and parity tests and the wide exactness tests pass. No side branch was needed.
- **Exact** [M]: against brute force on whole bases 10–25 in 17 shapes (survivors, listed n = checked; the
  device's check finds 69 at base 10); against the CPU reference n for n with every count at b30, b40, b50, b64
  forced wide, and b65 slices 717171717, 532260419 (the range start's clipped top) and 1160290624 (the last
  slice); whole survivor sets with the prefilter off; lavapipe at 8 lanes through SPIR-V at b40 and b65.
- **Wide faults now loud, by test** (b65, b64 forced wide, lavapipe b40) [M]: through the accounts: dropped main
  kernel, dropped tops, dropped probe, dropped parent, a failed device allocation (8,192 MiB filled), a stop
  variable in the environment (ignored); through the sampled CPU check only, as designed: a wrong parent (a new
  switch) and an over-strict prefilter.
- **The number** [M, one session, warm fields, sampled check off, 240 W]: base 64 narrow 1.710 fs per admissible
  n; base 65 wide 3.561 fs: **×2.08 of base 64** (MO.3: ×2.04 on an uncapped card before the accounts);
  0.49 card-years for all of base 65 on this card.
- **Where the wide path stands against the trunk's narrow one:** the accounts cost it about +9 % (×2.26 before
  the speed port); the top hierarchy saves about 1 ms per slice and the prefilter about 1.8 ms of check, but the
  prefilter's digit-by-digit wide arithmetic adds about 2.6 ms to the expansion (3.71 of a 13.8 ms slice), so
  the port won back only 7.8 %. The sampled CPU check does not fit at b65 (a CPU slice takes 93 s against a
  56 s field): off by default there.
- **Not done:** the cheaper expansion on the wide path (little to gain with one root); the staged-prototype
  test (its slice went with the wide branch's box); bases 68–70 (b68 does not fit a 10 GB card).
- **Next for the wide path** [E]: the prefilter's arithmetic reusing each record's fixed high part or 32-bit
  limbs: about 2.9 fs at b65, roughly ×1.7 of b64; then the children's `% b` tests; a multithreaded CPU
  reference so the sampled check fits.

## SRA.3 Census: which production submissions ran the exposed path (2026-11-19 03:15–03:40 UTC, director, ivory, read-only API; `SRA/census/` (`probe.py`, `census.py`, `census.log`, `state.json`, `rows.jsonl`, `followup.py`, `analyze.py`, `msd_check.py` and their outputs))

- **Method:** every nice-only submission since 2026-08-28 (the day v3.4.0, the first release with CubeCL's stride
  kernel, was tagged): submission ids 245,600,000–297,600,000 in 520 primary-key ranges of 100k, two requests per
  range 0.25 s apart, 682 s in all, no retry or error. Request 1 counted version, backend and route of every
  nice-only row; request 2 stored the rows with an explicit non-join route or with the CubeCL CUDA backend and
  no route field, with their field's base and size.
- **984,248 nice-only submissions** [M]:

  | client | backend | route | submissions |
  |---|---|---|---|
  | 3.3.0 – 3.4.5 | none (CPU) | none | 142,904 |
  | 3.4.2 – 3.4.5 | cubecl (wgpu) | none (stride) | 360,041 |
  | 3.4.2 – 3.4.5 | cuda (hand-written) | none (stride) | 15,046 |
  | **3.4.3** | **cubecl-cuda** | **none (stride)** | **451** |
  | 3.4.5 (pre-release builds) | cubecl (wgpu) | join | 150,310 |
  | 3.4.6 | none (CPU) | none / join | 1,901 / 226 |
  | 3.4.6 | cubecl (wgpu) / cuda | join | 121,836 / 62,837 |
  | 3.4.7, 3.4.8 and their dev builds | cubecl (wgpu) | join | 105,354 |
  | 3.4.7, 3.4.8 | cubecl-cuda | join | 23,342 |

- **Since v3.4.6 no GPU submission took the stride route**: every GPU row from 3.4.6 on reads `route: join`
  (0 rows with any other route value in the whole scan).
- **The exposed combination (nice-only, CubeCL's stride kernel, CUDA runtime) occurs in exactly 451
  submissions**: v3.4.3, user `vast-pipeline-test`, 2026-09-03 14:30–14:54 (−04:00), base-54 fields of 1e13,
  339 on an RTX 4090 and 112 on an RTX 3060, none disqualified.
- **All 451 fields had already been searched on the CPU** [M]: each has exactly one other nice-only submission,
  from v3.2.15 (`vast-test`, 450 fields) or v3.2.14 (1 field). No field rests on the exposed runs alone.
- **No sign that any of the 451 dropped its launches** [M + exact arithmetic]: 30 of them returned in under 15 %
  of their card's median processing time; for every field I computed the share that survives the leading-digit
  test (binary splitting to 4,096 pieces, exact integers). The 30 fast runs are the fields with at most 7.7 %
  surviving (27 of them 0), and time rises with the share bin by bin (minimum time over median: 0.17, 0.30,
  0.47, 0.61, 0.69, 0.88, 1.00 for shares 0.1–0.2 … 0.7–0.8). A run that dropped its launches would be fast
  with a large share; there is none (smallest share among the 421 normal runs: 0.059).
- **Not examined** (different runtimes, mechanism not shown there): the 15,046 stride submissions on the
  hand-written CUDA backend (v3.4.2–v3.4.5) and the 360,041 on wgpu (v3.4.2–v3.4.5, almost all the RX 9070 XT).
- **Conclusion:** the defect PR #270 fixes has no known effect on production's results. It was reachable by
  default only from v3.4.7 on and only for stride-routed fields, and no such field was ever submitted.

## SRA.2 Review of the stride fix, its fixes, and PR #270 (2026-11-19 01:30–03:10 UTC, independent reviewer then the author; `SRA/REVIEW-BRIEF.md`, `SRA/REVIEW.md`, `SRA/raw/review/`, `SRA/RESULTS.md` "After review", `SRA/PR-BODY.md`; branch `pr/stride-ran-account` 0f3a4542 + changelog link 05f18331; https://github.com/wasabipesto/nice/pull/270; box 61303619, destroyed 03:10 after 8.2 h)

- **Verdict: merge with fixes; no defect found in the code.** The reviewer ran everything on its own clones:
  `just lint`, clippy with cubecl-cuda, the suite in CI's form (231) and `-p "*"` (278), the gpu unit tests
  (261), the Metal `cargo check`, CUDA stride and detailed device tests, lavapipe WGSL (41) and SPIR-V (32), the
  WGSL lint; and with the host check removed the new test fails on CUDA, WGSL and SPIR-V. Read and confirmed:
  every reader and writer of the 4-word count buffer, the single reader every consumer goes through, barrier
  legality on all three kernel paths, the detailed path's histogram check, the test switch only in test builds.
- **Must-fix (description):** (M1) the plane-scoped queue path, which Vulkan GPUs take by default with SPIR-V,
  has run with the new count on CUDA only; lavapipe cannot stand in (its plane path already mis-runs on main:
  72 of 30,449 survivors accepted as Ok, which the new count turns into "0 of 2 cubes"); the description now
  says so, names the two tests to run on a Vulkan card before merging and the consequence if it were wrong
  (stride fields would stop with an error, not be lost). (M2) Metal: only the PR's macOS CI job.
- **Should-fix, applied:** (S1) the regression test launched one cube per launch and could not tell per-cube
  from per-launch counting; it now launches two halves of 9 cubes, asserts 18, and fails for a kernel that
  counts once per launch ("finished 2 of 18"); (S2) "same launch counts per field" removed (they vary run to
  run in both builds; results identical). Description cut by a third.
- **PR #270 opened 03:08 UTC** by me, body from `SRA/PR-BODY.md` (checked for forbidden references), changelog
  line linked in a follow-up commit. Not yet verified: CI on the PR; the two tests on a real Vulkan card.

## SRA.1 The stride path proves its cubes ran: the three false-empty reproductions now end in an error (2026-11-18 23:25 – 2026-11-19 01:26 UTC, engineer; `SRA/BRIEF.md`, `SRA/RESULTS.md`, `SRA/PR-BODY.md`, `SRA/raw/`; branch `pr/stride-ran-account` 7cf0c40d, 3940f8a9 on upstream be9cc923, on the fork, no PR yet; box 61303619, RTX 3080 20 GB)

- **Change:** `common/src/cubecl_backend.rs` (+78/−5 outside tests, tests +84), `CHANGELOG.md` (one sentence).
  Kernel: a helper at the very end of `niceonly_kernel`, after all three of its paths, waits for the cube and
  unit 0 adds 1 to a fourth word of the field's count buffer (the join's `cube_done` rule). Host: the run sums
  the cubes it launches; `read_niceonly_hits` fails the field unless the kernel's count matches (mod 2^32)
  before the queue account and the hits are read: "the device did not run every launch: its kernels finished X
  of Y cubes". A test-only switch counts a launch without running it. No flag, no retry.
- **Detailed path** [read + tests]: no gap: every candidate adds 1 to one histogram bin and the host already
  requires the total to equal the range size; the browser runner has the same check.
- **On the card** [M]: the three cases that submitted `[]` on v3.4.8 (b64 1e13 forced stride with 400 and
  520 MiB left; b62 5e12 by production's own routing with 290 MiB left) now exit 1 with "finished 0 of 277,280 /
  282,373 / 200,319 cubes" and submit nothing. Healthy runs give v3.4.8's results and launch counts; about 5,900
  base-10 filler fields each found 69.
- **Timings** [M, three interleaved rounds of three fields, medians]: b62 2.05 → 2.14 s (inside the 0.44 s
  round-to-round spread); b64 forced stride 7.80 → 7.77 s; device wait per field unchanged.
- **Tests** [M]: `just lint` passes; whole suite passes; lavapipe with both compilers (41 WGSL, 32 SPIR-V
  tests); the new regression test passes on CUDA, WGSL and SPIR-V and fails on all three with the host check
  removed. One join test fails on a 5.26 GB allocation when run after the others in one process on this card,
  on main as well. Metal: compiles; never generated or run.
- **Review:** independent reviewer started 01:30 UTC (`SRA/REVIEW-BRIEF.md`, hard stop 03:15); the PR opens after
  its fixes.

## MO.4 Independent soundness audit of the trunk: 1,073 slices equal the CPU reference; every host account is satisfied by all zeros (2026-11-18 22:05 – 2026-11-19 01:20 UTC, auditor; `G2/BUILD-BRIEF-3S.md`, `G2/AUDIT-MO.md`, `G2/audit1/` (logs, sweep JSON); branch `dev/mo-audit` dbbbc043, c00c018e on 91ac0761, on the fork; trunk unchanged; box 61286074, RTX 3080, CUDA)

- **Parity sweep** [M]: 1,073 real base-64 slices (1,000 seeded across the base, 49 extremes from a tops scan of
  16,384 slices, 24 from the base's first and last fields): tops, prefiltered lists n for n (361.7M entries),
  whole survivor sets with the prefilter off (12.59G survivors) and every count equal to the CPU reference. The
  first and last fields also ran whole with every account passing; the group path equals single slices; slice 0
  genuinely has no survivors.
- **Class 1, a candidate or count lost silently** [M, reproduced]: (1.1) a failed device allocation on CUDA:
  tops 0 and survivors 0, or tops run but the main kernel does not (a 2.59 GB pool page refused) and children,
  survivors and checked are 0; `Ok`, all accounts pass, `nice()` gives `Ok([])`; (1.2) `MIDOUT_STOP` left in the
  environment: `search_field` returns `Ok` in 5 s with survivors 0; (1.3) by fault injection, each passing the
  accounts with lower counts: main kernel dropped, tops kernel dropped, one probe per job dropped (−0.21 % of
  survivors), 1 parent in 997 dropped, a prefilter that rejects 1 in 1,024 too many.
- **Why:** the accounts are conservation laws on the records → list → check plumbing; every counter starts at
  zero and all zeros satisfy every one of them. Nothing asks for positive evidence that a stage ran
  (`AUDIT-MO.md` §4.1 lists the evidence each stage should return).
- **Class 2, lost but loud** [M]: probes past 2·PMAX, popcount past MAXPOP, a lost record, a stale slab count,
  the slab and list caps, a dropped check.
- **Class 3, robustness:** the 16-bit pending parent index is unchecked (largest class seen 17,060: ×3.8
  margin); the top index rides in 20 bits, safe only by the tops cap; the child-list write has no per-batch
  bound; MAXPOP 17 has no margin but 17 is a proven maximum at base 64 only; the slice count compares a host
  counter with itself; reported nice numbers are not checked to lie in the field.
- **Class 4, test gaps:** 64 lanes has never run on the library path; SPIR-V has two slices on lavapipe; the
  base-64 oracle is the CPU reference, not brute force.
- **Clean:** the coordinate layer (a new test shows the slices of all fields at base 64 and padded base 65
  partition the slice keys; 200k n per base including both range ends land in the right field, slice and
  lead); neither known SPIR-V defect shape occurs in the kernels.
- **Conclusion:** correct kernels on a healthy card lose nothing in 1,073 slices, and a kernel that does not
  run is invisible. Step 3A (started 01:25 UTC, `G2/BUILD-BRIEF-3A.md`) adds execution accounts, conservation
  laws and a sampled CPU check, with the audit's fault switches as acceptance tests.

## SRA.0 Production's v3.4.8 client can submit an unsearched field as empty after a CUDA allocation failure, on the stride route only (2026-11-18 22:52–23:30 UTC, engineer; `G2/build2e/ALLOC-FAILURE.md`, `G2/build2e/raw/alloc/` (memory-hog program `hog.cu`, harness `arun.sh`, one directory per run); box 61303619, RTX 3080 20 GB; client 8c267de5 = tag v3.4.8, features `gpu,cubecl-cuda`, local stub only, production hosts blocked and proven)

- **Setup:** a CUDA program holds all but N MiB of the card before the client starts or a few seconds in.
- **Stride route, false empties** [M]: (1) a base-62 field of 5e12, which production routes to the stride path
  itself (below the join's 1e13 minimum), with 290 MiB left: two allocations fail, 50 launches do nothing, the
  client submits `nice_numbers: []` with no error (device wait 0.09 s against 0.64 s; I read the SUBMIT line and
  the 50 panics in `runs/nat_hog290_qn62/` myself); (2), (3) forced-stride base-64 1e13 fields with 400 and
  520 MiB left: 78 and 89 launches dropped, both submitted empty. At other memory points the host panics on an
  unwrapped error and submits nothing.
- **Join route, caught** [M]: with 800–7,800 MiB left the client warns that kernels finished [0,0,0,0] cubes,
  shrinks its layout and submits correct counts; with 330 or 450 MiB left it exits with an error and submits
  nothing; a failure after the buffers exist changes nothing (buffers are reused).
- **Mechanism in CubeCL 0.10.0** [read, file and line]: the allocation panics at
  `cubecl-cuda/src/compute/server.rs:124` (`reserve(size).unwrap()`); `cubecl-common/src/device/handle/
  channel.rs:466, 480` catches it, logs "Task failed" and drops the task, the caller keeping a handle to memory
  that does not exist; every later launch binding it panics at `cubecl-runtime/src/stream/event.rs:268` →
  `cubecl-cuda/src/compute/stream.rs:101` and never runs; on CUDA that is never recorded as a stream error, so
  `sync()` and production's fences return Ok. On wgpu a launch that cannot bind is recorded and the next sync
  fails with `ServerUnhealthy` (seen on lavapipe; production's client on wgpu under memory pressure not
  measured).
- **What catches it:** the join's `ensure_ran` (`cubecl_join.rs:4400` at v3.4.8) compares cubes finished with
  cubes launched. The stride path's `queue_complete` (`cubecl_backend.rs:3202`) passes at 0 − 0, `wait` (`:3301`)
  reads only the hit count.
- **Exposure:** the stride route serves nice-only fields under 1e13 and bases outside 40–64; today's base-62
  fields are 1e17 and take the join. Nothing in a submission marks a false run. **Whether any past submission
  was produced this way is not known**; the condition needs the card's memory nearly exhausted at allocation.
- **Also seen:** with 150–230 MiB left the CUDA context cannot be created and the client switches without an
  error to wgpu on llvmpipe (CPU): results correct, speed useless (a b64 1e16 field unfinished after 240 s).
- **Next:** a fix branch `pr/stride-ran-account` (SRA.1, started 23:25 UTC): the stride path proves its cubes
  ran, as the join does; the detailed path checked for the same gap. A census of which past submissions took
  the stride route on CUDA goes to the next cycle.

## MO.3 Masks wider than 64 bits: base 65 exact on a GPU at 3.48 fs per admissible n; base 68 exact on two slices at 2.13 fs (2026-11-18 19:00–22:50 UTC, engineer; `G2/BUILD-BRIEF-2E.md`, `G2/BUILD-NOTES-WIDE.md`, `G2/build2e/raw/`, `G2/build2e/box/`; branch `dev/mo-wide` a8a76315 (4 commits on 7ba982c7, on the fork); box 61303619, RTX 3080 20 GB at a 320 W limit, one session)

- **Design:** a second file `common/src/midout/gpu_wide.rs` (two-word masks, digits by division, 7-bit digit
  fields, more slice rows, the padded coordinate, jobs split into up to 12 parts of 576 probes, its own full
  check: production's check holds digits in one 64-bit mask and refuses bases above 64). `gpu.rs` untouched, so
  base 64 pays nothing and tonight's trunk merges without conflict. (b, f0, k) are compile-time values, so the
  wide code also runs at small bases and at base 64 against the references there.
- **Exact at base 65** [M], on CUDA at 32 lanes and on lavapipe at 8 (SPIR-V): the device equals the u128 CPU
  reference on 5 real slices including both range ends and the slice where the range start clips a top (survivor
  sets n for n, every count, the check's distinct-digit count for every survivor); equals the staged prototype
  slice 717171717 unit by unit; every slice of 17 whole small bases (10–25) equals brute force and the device's
  own check finds 69 at base 10. Base 64 through the wide path equals day one's counts; 15 whole b64 field runs
  give the narrow path's survivors. Production's 214 tests pass; fmt and clippy clean.
- **Numbers** [M, whole fields, end to end, one session, 303–320 W]:

  | run | fs per admissible n | card-years on one RTX 3080 |
  |---|---|---|
  | base 64, narrow path | 1.709 | 0.26 |
  | base 64, wide path forced | 1.772 (+3.7 %) | |
  | base 65 (5 warm fields) | **3.484** (3.473–3.490) | **0.48** (study: 0.34–0.58) |
  | base 68 (one warm field) | 2.129 (2.187 cold) | 5.6 (study: 3.5–5.4) |

  Base 65 costs ×2.04 base 64's per admissible n (the study predicted ×2.5); its kept fraction is 0.615, the
  study's number exactly. Where base 65's time goes: tops 0.69 fs, main kernel 1.70, check with no prefilter
  0.54, expansion 0.30, parents 0.27. This branch predates tonight's trunk work (prefilter, top hierarchy).
- **Base 68:** exact on two slices of about 143M survivors each, including the range-start slice. Will not
  launch on Vulkan yet (the tops grid has 348k cubes in x, over the usual 65,535 limit: needs a 2D grid). Bases
  69 and 70 have not run; base 70's (4, 11) shape needs a 64-bit slice value.
- **Defects found and fixed on the way** [M]: (1) tops clipped by the range ends paired with every child, so n
  just outside the range came out as survivors (base 20: 58,862 below the start 58,945), caught by brute force;
  (2) a top with no certified digit read one entry past the common-mask table and lost survivors when a launch
  held enough jobs (base 20 slice 6 lost 10 of 37): cannot happen at base 64 or above, where tops always
  certify digits; the narrow kernel would write 64 into a 6-bit field there (matters only if it is ever run at
  small bases).
- **A soundness finding beyond this branch** [M, `build2e/raw/m2_oom_failed/`]: with another process holding
  13.8 GB of the card, CubeCL's CUDA server failed an allocation and **every later launch silently did nothing**;
  the narrow and wide paths then reported whole b64 fields as "survivors 0 = checked 0" and passed their
  accounts. The wide path now counts job instances that ran and requires the number queued. The trunk's narrow
  path lacks that account. **Whether production's client can report a false empty field this way was not
  checked: under test since 22:55 UTC (`G2/build2e/ALLOC-FAILURE.md` when done).**
- **Conclusion:** the join runs exactly above base 64 on a GPU, at a cost close to the CPU study's prediction.
  Merging with the trunk needs tonight's `gpu.rs` changes ported by hand to the wide kernels, and a prefilter
  with a second mask word.

## MO.2 The cost around the kernel (pieces B, A, C): ×4.02 against main on the RTX 3080; the ×4.4 target missed (2026-11-18 19:05–22:15 UTC, engineer; `G2/BUILD-BRIEF-2A.md`, `G2/BUILD-NOTES.md` §1, §6, §9, `G2/build2a/`; trunk `dev/middle-out-join` 7ba982c7 → 91ac0761 (7 commits, on the fork); box 61286074, RTX 3080 at a 240 W cap, same box session as its main run)

- **The number** [M]: the same ten base-64 fields as MO.1: **1.647 fs** per admissible n (21:31–21:36 UTC)
  against main 6.615 fs (21:42–21:57; identical to 0.1 s in all three of the day's runs on this box): **×4.02**
  (MO.1: 1.752 fs, ×3.78).
- **Per slice, field 77777, before → after in one session** [M] (at 03091f72): tops 0.47 → 0.36 ms; expansion
  0.96 → 1.11 (it now contains the prefilter); check 0.58 → 0.12; around the kernel 2.00 → 1.59; whole slice
  8.05 → 7.72 ms. Parents 0.65–0.67 and main kernel 5.40–5.46 ms unchanged.
- **What each piece gave** [M]: B (records name their top and their position in the child list: no probe walk)
  −0.07 ms; A (production's middle-digit prefilter inside the expansion, CPU mirror, `checked` now production's
  meaning; 2.87 % of survivors pass) −0.05 ms net, then −0.11 with 32-bit limbs; C (coarser level certified once
  per 64 slices, slice tops only under the 19 % of parents that are valid) −0.13; two records per lane −0.05.
  A first form of B (entries written by the main kernel) slowed the kernel by 1.2 ms and is superseded in the
  tree (it stays in history).
- **Dropped as neutral or worse** (ten variants, list in `BUILD-NOTES.md` §9).
- **Exact** [M]: CPU reference = brute force on whole bases 10–25 including `checked`; device = CPU on 5 slices
  on CUDA at every commit from C on (tops, prefiltered lists n for n, all counts) and on 2 whole slices on
  lavapipe at 8 lanes; production's check rebuilds the lists; all ten fields' survivor counts equal MO.1's;
  production's 214 tests pass; fmt and clippy clean.
- **Where the rest is:** the main kernel is 71 % of a slice (5.4 of 7.7 ms); the expansion 1.1 ms, apparently
  bound by load latency (a timing-only probe: reading the records 0.32 ms, with top and child loads 0.94, full
  1.17); parents 0.66 ms. The engineer's estimate: the expansion near its floor is worth ≈ ×4.3; ×4.4 needs the
  main kernel or the preparation as well.
- **Conclusion:** end to end the join is ×4.0 on NVIDIA at base 64 today, with exact device-independent
  counters and production's prefilter and check. The RX 9070 XT has not run the library path.

## MO.1 The middle-out join in the client library, day one: exact end to end at base 64; ×3.78 against main on an RTX 3080 (2026-11-18 16:43–18:51 UTC, lead engineer; `G2/BUILD-BRIEF-1.md`, `G2/BUILD-NOTES.md`, `G2/build1/box/`, `G2/build1/raw/`; branch `dev/middle-out-join` 7ba982c7 (7 commits on upstream be9cc923), on ivory and on the fork, no PR; box 61286074, RTX 3080 at a 240 W cap, i9-9900 with a 5.12-CPU quota)

- **What runs** [M]: `midout::gpu::search_field` on whole base-64 fields `(64, 2^75 + t·2^57, 2^57)` (digits 6–8
  fixed, 4,096 slices): tops, parents, the port's main kernel (form D), record expansion and production's
  `check_kernel`, all on the card; slices queued without waiting, one synchronisation and a full account check
  per 16 slices. Additive: `common/src/midout/` (4,300 lines), one example, one line of `lib.rs`; no route
  reaches it; production's 214 tests pass; fmt and clippy clean.
- **Exact** [M]: the CPU reference equals brute force on whole bases 10–25 (every b mod 5 class, odd bases, two
  shapes, 69 at base 10) and the staged prototype on two real b64 slices; the device equals the CPU reference on
  5 b64 slices on CUDA (tops, survivor sets n for n, every count); production's check in probe mode rebuilds
  exactly the join's survivors; two whole slices exact on lavapipe at 8 lanes through SPIR-V.
- **The number** [M, one session, both runs at the 239 W cap]: production main be9cc923, the ten b64 1e17
  fields: 840.0 s, **6.615 fs** per admissible n; middle-out 7ba982c7, ten whole fields at 0.05–0.95 of the base:
  320.6 s, **1.752 fs**. **×3.78.**
- **Per slice** [M, cumulative stops on one field]: tops 0.46 ms, parents 0.66, main kernel with child-list
  stores 5.44, expansion 0.92, check 0.57: 8.05 ms. Kernel + preparation (6.1 ms) equals the example's own
  measurement: the move into the library cost nothing.
- **What the earlier ratios got wrong (mine, G2.7–G2.11 and the reports built on them):** "tops and survivor
  checks 0.085–0.115 fs" was an assumption carried from main-type kernels and left out the step that turns the
  kernel's 10.9M records per slice into checkable n on the card. Measured: tops 0.10 + expansion 0.22 +
  unprefiltered check 0.13 = **0.45 fs**. The ×4.6 (3080) and ×4.7–5.5 (9070 XT) were kernel-plus-assumption
  numbers; the first end-to-end number is ×3.78 on the 3080, and ≈ ×4.3 is the engineer's projection for the
  9070 XT [E], not a measurement.
- **Also found:** the port's kernel was not exact on every slice: slice 318575442 has a job with 587 probes
  against the 576-probe table (1 slice in 1,024 sampled); the port counted an error and dropped the excess (no
  silent loss: the error counter fired). Fixed by a second job instance. The largest top seen has 17 digits =
  the limit; an 18-digit top stops the field with an error.
- **Other corrections to the design documents:** host-side tops cannot keep up on rented boxes (CPU quota):
  everything per slice must be on the device; the port's record format cannot be expanded on the device without
  a search (the library records job + chunk position and writes child lists in phase 1); a field that fixes only
  central digits is a multiple of H·b^6 (1.011e18 at b65), not of whole slices.
- **The interface** (`BUILD-NOTES.md` §2): a field is a range of a per-base coordinate; it permits any shape with
  f0 ≤ 6 and k ≥ 10, any key, kernel, mask width or prefilter, and work shared within a field; it forbids joins
  that need digits 6–8 to vary within one unit, anything that needs a field to be an interval of n, fields under
  2^57, and changing base 64's coordinate once fields exist. Fixing digits 6–8 or only 7–8 is the open choice.
- **Not yet:** lavapipe at 16 lanes (its 512-bit JIT crashes in the device-top and preparation kernels), the
  RX 9070 XT, masks above 64 bits on the device, a client route, a prefilter before the check.
- **Next** (`BUILD-NOTES.md` §7, ten pieces): B expansion, A prefilter, C top hierarchy (together ≈ −1.4 of
  8.05 ms per slice), E wide masks, F local coordinator and client route, D kernel items and the AMD window.

## G2.11 Pipelined over 16 distinct super-units with per-unit upload: ×5.14; the 7 % against the same-unit number is the upload in the compute queue (2026-11-18 14:37–14:58 UTC, engineer then director, demoux under the user's lease; `G2/WINDOW-RESULTS.md` "Distinct super-units", `G2/port/raw/window_1118d/` (logs, `per_unit_checks.txt`, the 16 units' meta files, scripts), `G2/port/raw/window_1118e/` (my run); head 1313018a (commits 51a386f8 `--multi LIST`, 1313018a `--no-upload`), bundle current, ivory's worktree fast-forwarded)

- **Units:** the two staged base-64 super-units plus 14 new π′, one per leading-digit band, staged on demoux by a
  new `g2proto dumptops` (2.5 s per unit; byte-identical tops for the two staged units). 238,347–239,698 tops,
  1,040,227–1,044,431 parents, 11,742,386–11,806,353 survivors per unit. Reference counts for the 14 new units
  are the binary's own CPU reference (`cpu_job`), not prototype survivor sets.
- **Protocol:** per unit the host uploads its input (1.94 MB, new buffers: CubeCL 0.10 cannot write into an
  existing one), queues its preparation and the full kernel with records; one synchronisation per 16 units;
  360 cycles (5,760 super-units) after a 5 s warm-up; per-unit counters checked at the end.
- **Exact** [M]: 9 runs × 16 units (and my run): preparation equal to the host's and counts equal to the CPU
  reference for every unit; cumulative counts equal (1 + 360) × the reference; error counters 0.
- **Timing, variant D** [M] (main base 4.707 fs + 0.085 fs; main field 6 in the same stretch 100.44 s):

  | run | ms per super-unit | fs per admissible n | ratio | clock, power |
  |---|---|---|---|---|
  | 16 distinct, upload per unit (3 runs; mine) | 3.705–3.738; 3.692 | 0.8303 median; 0.8263 | **×5.14**; ×5.17 | 2,899–2,916 MHz, 303 W, 49–50 samples ≥ 270 W |
  | one unit × 16, upload per unit | 3.699 / 3.704 | 0.8285 | ×5.15 | 2,901 MHz, 303 W |
  | 16 distinct, inputs resident (no upload) | 3.453 / 3.463 | 0.7739 | ×5.48 | 2,847–2,858 MHz, 304 W |
  | one unit × 16, no upload | 3.463 | 0.7752 | ×5.47 | 2,849 MHz, 304 W |
  | same-unit pipe as G2.10 | 3.447 / 3.449 | 0.7717 | ×5.49 | 2,843–2,845 MHz, 304 W |
  | 16 distinct, upload, variant A | 3.863 | 0.8647 | ×4.96 | 2,924 MHz, 303 W |

- **The whole 7 % is the upload, none of it cache warmth:** distinct units cost the same as one unit repeated;
  the 2 MB copy goes through the same queue ahead of the unit's kernels and costs about 0.27 ms on the card
  (about 7 GB/s; it does not overlap compute). The host spends 0.48–0.73 ms per unit on it and keeps up.
- **My reading:** a client that uploads each unit's tops from the host through the compute queue sees ×5.14. One
  that keeps the tops on the card sees ×5.48, and today's main already builds its tops on the card (the FD top
  kernel), which is how the 0.085 fs term is priced. So ×5.1 is the floor for the obvious client and ×5.5 the
  design's number; neither is a client measurement.
- **Lease:** 13:02–14:59 UTC, 2 h of the 4 granted. Workspace and watchdog removed, nothing left running, the
  production client untouched and still stopped; one ntfy sent at 14:59.

## G2.10 The port on the RX 9070 XT after the preparation fix: ×4.7 by the pre-registered protocol, ×5.5 pipelined (2026-11-18 13:36–14:37 UTC, engineer then director, demoux under the user's lease; `G2/DEMOUX-BRIEF.md`, `G2/WINDOW-RESULTS.md`, `G2/port/raw/window_1118b/` (engineer's stretch in `m/`), `G2/port/raw/window_1118c/` (my cross-check); branch `g2-cubecl-local` 4170a781 → ef54ed59, two commits made on demoux, bundle `G2/port/g2-cubecl-demoux.bundle`, ivory's worktree fast-forwarded; timed binary md5 8801a739; main = the window's binary)

- **What the 1.84 ms preparation was** [M, device timestamps per launch]: device work, not launch latency and not
  a host round trip. 62 % was the per-bucket rank sort (n² compares in one cube of 64 per bucket, 178M compares;
  34 of 16,128 buckets hold ≥ 512 parents): 1,146 of a 1,658 µs chain. Root pass 342, scatter 75, scan 46, top
  digits 18 µs.
- **What a launch costs on CubeCL / wgpu / RADV** [M]: synchronised 0.112–0.125 ms of wall clock; queued 7–9 µs
  of host time and about 1 µs on the device. CubeCL's device-timestamp span over many submissions is unusable on
  this stack (read 0.016 ms for 3.4 ms of wall clock): pipelines are timed by wall clock.
- **The fix** (default now): `--rsort 2` (a cube of 256 per bucket: rank sort from shared memory for ≤ 256
  parents, bitonic above; sort 1,146 → 301 µs), `--scan 1` (1,008 threads), `--prep3 1` (counters zeroed on the
  card, no host upload per preparation). **Preparation 0.416–0.427 ms at the operating point** (queued), inside
  the model's 0.15–0.45 ms; 0.93 ms in the synced protocol (cold card, one sync per rep).
- **Ratios** [M] (main base mean 4.707 fs from G2.7's ten fields; + 0.085 fs for tops and survivor checks):

  | protocol | variant | G2 fs per admissible n | ratio | clock, power |
  |---|---|---|---|---|
  | pre-registered (prep + full, synced per launch, 400 reps) | D | 0.9105 median of 4 (min 0.9082); mine 0.9065, 0.9090 | **×4.73** (mine ×4.74) | 2,773–2,854 MHz, 278–303 W, 7–8 busy samples (still bursts) |
  | | A | 0.9548 | ×4.53 | 2,481–2,855 MHz |
  | same with 5 s warm-up, 2,000 reps | D | 0.8866 | ×4.84 | 2,845 MHz, 303 W, 58 samples |
  | **pipelined** (3,000 super-units' prep + full kernel with records queued, one sync, buffers reused, counts checked) | D | 0.7692 median of 4 (min 0.7675); mine 0.7682, 0.7712, and 0.7709 on the second super-unit | **×5.51** | 2,846–2,852 MHz, 303–304 W, 58–60 samples ≥ 270 W |
  | | A | 0.8054 | ×5.28 | 2,866–2,872 MHz, 303 W |

- **Main's bracket** [M]: field 2 92.29 / 92.45 s (window 90.83), field 6 100.31 / 102.17 s and mine 101.44
  (window 100.41), counts identical, 3.11–3.15 GHz at 304 W: +1.2 % slower in the afternoon; with the base scaled
  to match, D is ×4.78 and ×5.57.
- **Exact** [M]: A and D on both super-units at 64 lanes after the changes (engineer); D on both again in my
  run; lavapipe on demoux at 8 lanes; every pipelined run's counts equal K times the CPU reference. Widths 16
  and 32 not re-run after the preparation change (the main kernel is unchanged).
- **The operating point under G2 is 2.85 GHz at the 304 W cap** (main reaches 3.13 GHz at the same power): the
  plan's "≥ 97 % of 3,150 MHz" cannot be met by this kernel; met on power instead. **The kernel's time does
  follow the clock**: one run stuck at 1,560 MHz and 82 W after a phase of short synced launches and took 7.04 ms
  for the full kernel instead of 3.1. G2.7's "times barely move with the clock" was too few samples per burst.
- **Components at the operating point, D, queued** [M]: prep 0.416, probes off 0.930, full without records
  2.723, full 3.033 ms per super-unit. Records cost 0.31 ms (175 MB of writes per super-unit; an 8-byte record
  would save about 0.15 ms, not built).
- **Caveats of the pipelined number:** the same super-unit 3,000 times (inputs may be cache-warm), no host upload
  of per-unit tops (≈ 1.9 MB, ≈ 0.1 ms, overlappable), records stay on the card. A distinct-unit run is in
  progress (G2.11).
- **Process notes:** the engineer's two commits carry a different co-author trailer than briefed and one lost its
  body to a quoting error (not amended; local branch only). A `--pipe 2000` run aborted on a u32 counter overflow,
  was fixed and the stretch re-run (`m_aborted/` kept).
- **Conclusion: on the card that does 86 % of the search the redesign clears its ×4.0 stop line by both
  protocols: ×4.7 as pre-registered, ×5.5 as a client would run it.**

## G2.9 The tuned port on an RTX 3080: exact at 32 lanes; ×1.11 of hand CUDA; ×4.61 against same-session main (2026-11-18 13:06–13:57 UTC, engineer; `G2/BOX3-BRIEF.md`, `G2/BENCH.md` "Tuned port on CUDA (2026-11-18, Vast 61250912, 240 W)", `G2/port/raw/cuda_box3/`; box 61250912, RTX 3080 capped at 240 W by its host, 1.04 h, ≈ $0.13; a first box, 61250182, was capped at 150 W and destroyed after 5 minutes)

- **Exact at W = 32 on hardware** [M]: head 4170a781, CUDA runtime, GPU prep on, `--tdig 0` and `--tdig 1` on both
  super-units whole, `--prep2 0` once: 5 runs, ALL CHECKS PASSED (sets, counts, records, order, class segments,
  top digits, 0 kernel errors).
- **One session, six rotated rounds, 200-launch medians** [M] (ms; end to end in fs per admissible n):

  | | prep | probes off | full | end to end, median of 6 | against main (6.619 fs; + 0.115 for tops and checks) |
  |---|---|---|---|---|---|
  | hand CUDA v10 | 0.445 | 0.671 | 4.886 | 1.1938 | ×5.06 |
  | pre-tuning port (9ff100e6) | 0.711 | 1.881 | 6.532 | 1.6210 | ×3.81 |
  | tuned A (`--tdig 0`) | 0.647 | 1.721 | 5.322 | 1.3359 | ×4.56 |
  | tuned D (`--tdig 1`) | 0.647 | 1.695 | 5.261 | 1.3217 | **×4.61** |

- **Main, same box and session** [M]: production client at 7e0113fc against the local stub, the ten b64 fields
  twice: 6.629 and 6.609 fs. Production hosts blocked and proven before each run.
- **The tuning is worth ×1.21–1.23 on CUDA; the port is now ×1.11–1.12 of v10** (was ×1.34–1.36). Stable across
  processes (no bimodality). The 240 W cap costs 7–8 % against yesterday's 300 W box on v10 and P alike.
- **G2.6's offline predictions:** end to end 1.25–1.45 fs held (1.32–1.34); ×1.1–1.3 of v10 held; `--tdig 1` no
  longer slower held (the atomic-load mechanism); full kernel 5.0–5.6 ms held; **the preparation missed**
  (0.647 ms against 0.45–0.6 predicted).
- **Remaining gap to v10:** full kernel +0.38 ms, preparation +0.20 ms.
- **Build trap** [M]: a second worktree built into the same target directory returned the first worktree's
  binary byte for byte (cargo "finished" in 0.15 s); caught by md5 before any timing. Each commit needs its own
  target directory (demoux's build of the pre-tuning binary used one, and its md5 differs).
- **Conclusion:** the portable kernel is ×4.6 against main on NVIDIA at base 64, measured, where the
  hand-written one is ×5.1.

## G2.8 G2 above base 64: the counts carry to bases 65–70; the price rests on guesses on both sides (2026-11-18 12:58–13:37 UTC, investigator, ivory CPU only; `G2/BASES-BRIEF.md`, `G2/bases/RESULTS.md`, `NOTES.md`, `proto/` (the prototype with u128 masks and 384-bit integers), `price.py`, `today_wide.py`, `indep.py`, `raw/`)

- **Question (the user's, 2026-11-18):** is G2 only useful at base 64, or at the bases after it too?
- **The widened prototype is exact** [M]: reproduces every recorded b62 / b64 count including the benchmark
  super-unit (parents 1,042,046, children 33,705,647, chunks 528,635, flat 250,486,772, kept 123,163,397,
  survivors 11,768,560); 21 whole small bases b10–b29 (every b mod 5 class, odd bases 13, 17, 25, 29) equal
  brute force through the super-unit pipeline; above 64, 8 real units (two per base) equal an independent
  Python enumeration, with masks reaching bit 64 (b65) and bit 69 (b70).
- **Counts on 6 random real super-units per base** (4 at b64), sampling error ≤ 0.2 % [M]. Shape (4, 10) stays
  right at 65, 68, 69; base 70 moves to (4, 11).
- **Priced with v10's measured unit costs at b64 and guessed width factors** (64-pair word ×1.0–1.35 above 64)
  [D/G], per admissible n on one RTX 3080, low–central–high:

  | base | admissible n vs b64 [M] | G2 fs | today's join widened, fs [D from October's CPU `exp/join-wide`] | ratio worst–central–best | card-years G2 | card-years widened today |
  |---|---|---|---|---|---|---|
  | 64 | ×1.00 | 1.23–1.24–1.34 | 6.35 [M] | ×4.7–5.1–5.2 | 0.19 | 0.97 |
  | 65 | ×0.905 | 2.5–3.1–4.2 | 19.7–22.9–37.9 | ×4.7–7.4–15 | 0.34–0.43–0.58 | 2.7–3.1–5.2 |
  | 68 | ×17.2 | 1.3–1.6–2.1 | 12.2–14.2–23.5 | ×5.9–8.8–18 | 3.5–4.2–5.4 | 32–37–62 |
  | 69 | ×42.0 | 1.1–1.3–1.7 | 9.0–10.5–17.3 | ×5.2–7.8–16 | 7.0–8.5–11 | 57–67–110 |
  | 70 | ×620.7 | 0.79–1.00–1.30 (shape (4, 11)) | 6.7–8.8–16.1 | ×5.1–8.7–20 | 74–94–123 | 630–830–1,520 |

- **Why the ratio rises above 64** [D]: today's join pays per n, and a base with few roots has few admissible n
  per n (b65 has one root of 64 classes); G2 spreads its bottoms and preparation over a leading range b times
  wider at 14 digits. Base 65's single root makes tops ×7.6 dearer per admissible n (0.6 fs, 19 % of its G2
  cost). The common-mask skip weakens above 64 (kept 0.53–0.62 against 0.49; structural).
- **Not counted:** at b68 / b69 a (class, unit) block has 3.5k–6.3k probes against v10's 576-probe shared table,
  so probe tiling is required (four-Russians tables would pay there).
- **Work unit above 64** [D]: same super-unit; the coordinate is padded (≤ 0.0002 % of the range, no more bits
  than n); fields must be integer multiples of H·b^5 (239,394,642,621,875 at b65), not powers of 2 or 10.
- **What production runs above 64 today is the stride path**, ×209–435 slower than a widened join on the CPU
  (October): against it G2 is ×1,000 or more.
- **Conclusion:** the design is not base-64-specific; the exact counts say its cost per admissible n stays
  within ×0.8–2.5 of base 64's through base 70, and no band against today's design widened falls below ×4.7.
  Nothing above 64 has run on a GPU. One run settles G2's side: v10 widened on one real b65 super-unit on a
  3080 (≤ 3.1 fs confirms the central figure; above 4.2 fs puts b65 under ×5).
- **Rule notes:** ivory's disk fell to 0.8–1.2 GB free at 13:13 UTC (another session's 5.4 GB debug build in
  `.worktrees/gpu-probe-msg`); the investigator deleted its own dumps and once rebuilt its 1 MB prototype below
  the 5 GB rule. The b65 super-unit was not staged for lack of disk (command in `bases/RESULTS.md` §6). I freed
  3.5 GB of my own afterwards (a rebuildable target directory; BX's raw samples archived to braize, checksum
  verified, list in `BX/a3-adversary/DATA-ARCHIVED.txt`).

## G2.7 The tuned port on the RX 9070 XT, first run: exact at 64 lanes; ×3.92 by the protocol, off the operating point, preparation 1.84 ms (2026-11-18 13:05–13:33 UTC, director, demoux under the user's 4-hour lease; `G2/WINDOW-PLAN.md`, `G2/port/raw/window_1118/` (go.out, 96 logs and samples); builds on demoux: g2 = 4170a781, g2_pre = 9ff100e6, main = nice_common's test binary at 7e0113fc with `gpu,cubecl-spirv`; Mesa 26.1.6 RADV)

- **Exact** [M]: variants A (both super-units), B and D (first super-unit) print ALL CHECKS PASSED (survivor
  sets, counts, GPU preparation's records and order, plane and slab errors 0): the first hardware run of the
  64-lane path. Counts equal in all 34 timing runs.
- **Main** [M]: ten base-64 1e17 fields 597.8 s (77.58, 90.83, 0.02, 97.88, 0.03, 100.41, 107.68, 0.02, 15.05,
  108.25), 4.707 fs per admissible n, at 3,107–3,142 MHz and 304 W.
- **G2 by the pre-registered formula** [M] (end to end = GPU preparation + full kernel, + 0.085 fs for tops and
  survivor checks):

  | variant | prep ms | full ms | end to end fs (median, min) | ratio |
  |---|---|---|---|---|
  | A (tuned, `--tdig 0`) | 1.83–1.92 | 3.32 | 1.156, 1.154 | ×3.79 |
  | D (tuned, `--tdig 1`) | 1.84–1.91 | 3.13–3.15 | 1.114, 1.111 | **×3.92** |
  | C (one entry per step) | 1.83–1.92 | 3.32 | 1.153 | ×3.80 |
  | B (ballot transpose) | 1.84–1.92 | 4.97 | 1.524 | ×2.93 |
  | P (pre-tuning build) | 2.37 | 4.56 | 1.550 | ×2.88 |

- **The tuning was worth ×1.36 on the card** (P against D), about what the ACO counts said for the kernel
  (4.56 → 3.13 ms); D beats A as predicted.
- **Every G2 timing run is off the operating point** [M]: 6–10 samples at ≥ 80 % busy, clock medians
  1,958–2,878 MHz against 3,150, power 148–303 W: the runs are 2–4 s bursts. **The times barely move with the
  sampled clock** (prep 1.83–1.92 ms and full 3.32 ms at 1,958 and at 2,864 MHz alike).
- **The miss against the model is the preparation**: 1.84 ms for five launches where the model said 0.15–0.45
  and a 3080 measured 0.70 before today's changes; the kernel (2.76–3.32 ms) is near the model's central
  2.9 ms. With the preparation at 0.4 ms, D would read about ×5.3 [D].
- **Reading:** below ×4.0 by the letter of the proposal's rule, on runs the plan itself says to read by their
  clock. Not a verdict yet: an engineer uses the rest of the lease on the launch cost, the preparation and a
  pipelined protocol (`G2/DEMOUX-BRIEF.md`).

## G2.6 The port tuned offline for RDNA4 and against the CUDA gap: kernel issue cost −30 % by ACO, 12 waves; nothing timed (2026-11-18 08:15–10:52 UTC, engineer, ivory only; `G2/TUNE-BRIEF.md`, `G2/TUNE-RESULTS.md`, `G2/PORT-NOTES.md`, `G2/WINDOW-PLAN.md`, `G2/port/raw/tune/` (ACO and SASS counts, exactness logs, scripts, `dircheck/` = my runs); branch `g2-cubecl-local` 9ff100e6 → 4170a781, eleven commits, never pushed; bundle current)

- **Measured, ACO for GFX1201 (Mesa 26.0.8, drm-shim), per wave-iteration** [M]: 3b step 217 → 169 VALU (−22 %),
  3a 222 → 52, phase 1 74 → 58 vcyc, transpose ≈ 131 → 40 vcyc per task, whole kernel 1,746 → 1,228 vcyc;
  shared memory 25,600 → 21,504 B and VGPRs 192 → 120, so **12 waves per SIMD instead of 8**; GPU prep one root
  pass at 229 vcyc per root instead of two at 311 + 338.
- **The changes** (one commit each): slice rows at stride 65 (address 3 VALU per digit, was 4); u16 pending slots
  with the probe list in the same words; branch-free 3b with byte offsets in the list; 3a from per-digit common
  masks; uniform plane index and 24-bit multiplies; parent records, probe words and survivor records as 16-byte
  vectors; prep in one pass; the shuffle transpose on 32-bit halves; the prep's distinctness test as a popcount.
- **Exact on lavapipe 26.0.8** [M]: every commit, both staged super-units whole, SPIR-V, W = 8 with GPU prep and
  W = 16 with host prep, fill 512 and 1024 (16-chunk rounds ran on lavapipe for the first time), survivor sets
  equal to the prototype's, counts equal to the CPU reference, 0 kernel errors. **My own runs of the final head**
  with `--tdig 1` (the variant the window now times in every round, last proven at commit 7 of 11): W = 8 GPU
  prep and W = 16 host prep on both super-units, all sets EQUAL, 11,768,560 and 11,769,950 survivors, 0 errors.
- **Not run anywhere: the tuned build's W = 32 and W = 64 paths.** The pre-tuning build ran W = 32 exactly on a
  3080; the tuned transpose is checked at W = 32 / 64 only in a CPU simulation of its definition.
- **Predicted, not timed** [P]: the issue-bound model for the card gives a kernel bound of 3.19 → 2.15 ms and a
  ratio of **×6.4 central (×4.8–8.1 over the efficiency and prep bands, ×4.4–8.7 with main's ±8 %)**; the same
  model gave ×4.5 (×3.4–5.6) before. The model sees instruction issue only and has never been checked against
  the card. On the RTX 3080: ≈ 1.25–1.45 fs against v10's 1.12 (×1.1–1.3, was ×1.34), ×4.4–5.1 against main.
- **Why the port was ×1.34 slower than hand CUDA** [M, SASS by NVRTC + ptxas for sm_86, offline]:
  1. yesterday's "bottom side 1.75 against 0.63 ms" was not like for like: nvcc removed v10's transpose and probe
     setup from its probes-off kernel as dead code (5,184 B of shared memory against 32,200 B). The honest
     comparison is the full kernel, 6.0 against 4.54 ms;
  2. **CubeCL compiles every shared atomic load to `atomicAdd(p, 0)`** (cubecl-cpp `compile_atomic_load`); 3a did
     32 of them per probe on one address, and nvcc aggregates them per warp or issues them per lane depending on
     unrelated code: aggregated at `--tdig 0`, per lane at `--tdig 1`. That is the mechanism of G2.5's unexplained
     +2.8 ms (mechanism found in the SASS of both builds; not re-timed). The tuned 3a has no atomics;
  3. three or four scalar accesses where v10 has one 128-bit access (parents, probe words, records): now vectors.
- **Dropped with reasons** (`TUNE-RESULTS.md`): four list entries per step (neutral), a uniform skip of the second
  entry, 8-chunk rounds, `v_perm` addresses, 32-bit child masks.
- **Window plan now:** build 4170a781; variant D (`--tdig 1`) in every round with its own exactness run; optional
  variant P (the pre-tuning binary) for one round to measure the tuning itself.
- **Conclusion:** the build that would be timed on the card issues about 30 % fewer instruction-cycles per unit
  and fits 12 waves; whether that becomes time is unknown until the card or a rented 3080 runs it. A 3080 run
  (W = 32 exactness and a re-time, about $0.20) is the first thing to do when credit allows.

## CX.0 Construction instead of search: where a second nice number is expected, and why it cannot be built (2026-11-18, director, no hardware; `CX/NOTES.md`, `CX/ecount.py`, `CX/ecount.txt`)

- **Computed** [uniform heuristic, range count × b!/b^b over bases with a range and a root class]: bases 11–60
  (all searched, none found) carried 0.033 expected nice numbers; b62 2.2e-4, b64 1.2e-4, b65 3.3e-4. The per-base
  expectation is lowest near base 55 and then grows without bound: the running total passes 1 between bases 125
  and 128; base 140 alone expects 4.7, base 200 about 4.5 million among 1e92 candidates. Density stays e^(−b).
- **Argued, not run** (`CX/NOTES.md`): (1) generic n has no locality (any digit change rewrites 3L + 2 of the 5L
  output digits), so local search is BX's lottery; (2) carry-free polynomial n needs s²(s + 1) = b(b − 1)/2 (only
  (3, 9) for s ≤ 2,000,000, checked) and cannot give the square 2L distinct digits; (3) rational-type n (near-repdigits, Q | b − 1)
  can give n² distinct digits by design (one arithmetic progression mod b − 1) but then n³'s digits are quadratic
  in the position and would have to equal the progression's complementary run; (4) bases to 60 are exhaustively
  searched and show no structural family.
- **Conclusion: closed by argument.** No agent was started. A verified negative it is not: nothing was measured
  beyond the table.

## NM.1 Near misses as a by-product of the nice-only search: killed on yield (2026-11-18 05:50–07:50 UTC, investigator, ivory only; `NM/RESULTS.md`, `NM/PROPOSAL.md` ("do not build"), `NM/NOTES.md`, `NM/code/`, `NM/raw/`; prototype in worktree `.worktrees/nm-near-miss`, never pushed, diff saved as `NM/raw/nm-near-miss.patch`; base main 7e0113f)

- **Question:** if the full check counted repeated digits up to a tolerance m instead of stopping at the first, how
  many numbers with ≥ b − 2 distinct digits would the rest of base 62 plus base 64 give, and at what cost?
  Kill: > 3 % of a field at m = 2, or < 30 expected numbers.
- **Why the premise was wrong (mine)** [proved; I re-derived it]: every candidate the search examines is in a root
  class, n² + n³ ≡ b(b − 1)/2 (mod b − 1), and the digit sum of n² ‖ n³ is ≡ n² + n³. With b − 1 distinct digits one
  digit x is doubled and one y missing, digit sum b(b − 1)/2 + x − y, so x ≡ y (mod b − 1): only {x, y} = {0, b − 1}.
  Among candidates the b − 1 near misses are exactly as many as the nice numbers (b! strings each): base 62's "0.4
  numbers with 61 digits" is 4.5e-4 where the search looks. At b − 2 the filter keeps ≈ R/(b − 1) (2/61 at b62,
  8/63 at b64). Nothing in the check or the join's later stages can undo this; probing all b − 1 classes costs
  ×30 (b62) / ×8 (b64) the join.
- **Exact definition and prototype** [M]: by-product(m) = {n reaching the check with ≥ b − m distinct digits}, a
  property of the field and the join's shape only. Brute force of the definition = the prototype's output on all
  20 cases (whole bases 20–30 at scaled shapes, b40 whole 1e10 fields, partitions at b44–b64, m = 1, 2, 3, 64). The
  one subtlety was the top certificate's closure (without it brute force over-counts, 1,787 vs 1,451 at b40).
- **Yield** [M + model]: repeat histogram of 2.2e9 checked survivors (30 sampled b62 / b64 1e17 runs) against the
  uniform-middle model: ratio 1.03–1.09 for 7–13 repeats, lowest seen 6. Model × residue factor × 1.08:

  | | fields | ≥ b − 1 | b − 2 | b − 3 |
  |---|---|---|---|---|
  | rest of b62 (86 %) | 82,070 | ≈ 1e-4 | 0.6–2.1 | 80–270 |
  | all of b64 | 377,800 | ≈ 4e-4 | 3.8 (2.6–4.9) | 530 (370–680) |
  | **sum** | | ≈ 5e-4 | **4.4–7.0** against the bar of 30 | 610–950 |
  | b60, finished | 162,084 | ≈ 3e-4 | 2.7 | 320 |

  Even a check that caught every root-class b − 2 number would get ≤ ≈ 21.
- **Director's check of the b62 rate** [M, `../2026-11-fresh-eyes/recent_niceonly_1116b.json`]: the study's "72.6 %
  of b62 fields check nothing, mean 1.22e10 checked per field" is a frontier artefact: 8,385 of the 12,038 fields
  in that snapshot are the instantly empty opening (leading digits of n² and n³ both 1). Beyond it 14.1 % of fields
  are empty and the mean is **3.83e10 checked per field** (4.45e10 per non-empty field; the study's own sampled runs
  over the rest of the range gave 4.15e10 ± 0.9e10). So the rest of b62 sits at the top of the study's range
  (≈ 2.0 at b − 2) and the sum is ≈ 5.8 (4.6–6.9). The verdict does not move.
- **Cost** [M, CPU, one thread, 5 rotated rounds, counters identical]: m = 2 against unmodified main ×1.046 (b60
  1e16), ×1.065 (b62 1e17), ×1.057 (b64 1e17), of which ×1.013–1.038 is the tolerance itself and the rest the
  prototype's layout. GPU [priced from counts, not timed, no kernel written]: the gate between n² and n³'s upper
  limbs passes 1.4e-3 of lanes today and 8.5e-2 at m = 2, so nearly every plane builds the whole cube: +6.5–7.7 %
  of a b62 field, +10–12 % at b64 for the straight edit; ≈ +0.6 % / +1.0 % (±50 %) with a compacted second pass.
- **Variants that widen coverage inside root classes** (tolerating a repeat in the prefilter, the AND or the
  certificates) multiply the check's or the join's load by ×2.5–11 and are capped at ×2 more yield. Dead.
- **The rest of the system** [read, lines in `NM/NOTES.md`]: nothing would mistake near misses for nice numbers and
  nothing would show them: clients hard-code `num_uniques: base` for nice-only hits, the API stores nice-only
  numbers as given, and the jobs publish a base's numbers only above 20 % detailed coverage.
- **Conclusion: KILL by the yield criterion (≈ 5–6 against 30); the CPU cost misses its bar as well.** Numbers with
  b − 3 digits would come in hundreds (610–950), which nobody asked for. Not proposed to the user as a feature.

## G2.5 The CubeCL port after its fixes: 1.499 fs, ×1.34 slower than hand CUDA; ×3.9 against main (2026-11-17 13:09–14:20 UTC, engineer; `G2/BENCH.md` "CubeCL port after fixes", `G2/PORT-NOTES.md`, `G2/WINDOW-PLAN.md`, `G2/port/raw/cuda_box2/` (incl. generated CUDA sources); box 61073296, RTX 3080 at a 300 W cap, 1.25 h, ~$0.17; port head 9ff100e, bundle current)

- **Exact at 32 lanes on real hardware with the new common masks** [M]: both super-units, survivor sets, counts, the
  GPU preparation's records, order, class segments and top digits; 0 kernel errors.
- **Final four rounds, same session, fs per admissible n** [M]: fixed port 1.4995 / 1.4991 / 1.5006 / 1.4989 (median
  1.4993); hand CUDA v10 1.1139 / 1.1214 / 1.1173 / 1.1146. **CubeCL / v10 = ×1.34** (×1.37 before the fixes).
  Components of the port: preparation 0.70 ms (from 1.03), bottom side 1.75 ms (from ≈ 2.0), full kernel 5.998 ms
  (unchanged: the bottom-side gain does not carry into the full kernel).
- **Against main** (not re-run on this box; today's two same-session values on other 3080s, 6.35 and 6.396 fs),
  with tops and survivor checks added: **×3.93–3.96** [D from M].
- **Two CubeCL / CUDA code-generation effects found** [M]: (1) the fix that precomputes the top digits once per
  super-unit made the full kernel 2.8 ms slower with identical output (8.796 against 5.998 ms on the same
  binary by a switch; cause not understood; off by default); (2) run-to-run bimodality (steps of ≈ 1.4 ms)
  came from where CubeCL places shared arrays in each build; padding every shared array to 128 bytes removes
  it.
- **Prediction for the RX 9070 XT** [D, ACO-based]: ≈ ×4.7 (×3.4–5.9); the proposal's stop line ×4.0 is inside the
  band. The window driver gained a one-round variant with the precomputed digits.
- **State of G2:** hand-written CUDA ×5.1 (two cards); the portable port ×3.9 on NVIDIA; the production card
  unmeasured; everything for a 45-minute window is staged (`G2/WINDOW-PLAN.md`, ≈ 22 minutes of runs).

## G2.4 The CubeCL port on a real card: exact at 32 lanes; ×1.37 slower than hand CUDA; main replicated (2026-11-17 10:30–12:00 UTC, engineer; `G2/BENCH.md` "CubeCL port on CUDA", `G2/PORT-NOTES.md`, `G2/port/raw/cuda_box/`; box 61056498, RTX 3080 at a 280 W cap, 1.54 h, ~$0.19; port at local branch `g2-cubecl-local` 8579db4 → bundle head 0207550)

- **Exactness at 32-lane planes on real hardware** [M]: both super-units, every unit's survivor set, the counts,
  the GPU preparation's parent order, 0 kernel errors; also with the ballot transpose and one entry per step.
- **Same box, same session, three rounds, fs per admissible n** [M]: hand CUDA v10 1.143 / 1.151 / 1.149 (this
  morning on another 3080: 1.123); CubeCL port 1.572 / 1.573 / 1.574 (**×1.37** v10; the port as first built, with
  plane scans: 2.06–2.34); main 7e0113f 6.396 (ten b64 fields, 3 empties, stub, hosts blocked).
- **Ratios against main, with tops and survivor checks (+0.115 fs) added: v10 ×5.07 (a replication of the
  morning's ×5.13 on a second card); the CubeCL port as it stands ×3.79.**
- The 64-pair word is at parity (32.5–34.4 ps against 32.9). The gap is the bottom side (1.76–1.99 ms against 0.63:
  shuffle transpose 0.80, common masks by shared `fetch_or` 0.40, probe setup 0.18, phase 1 and barriers 0.75) and
  the preparation (1.03 ms against 0.44). CubeCL lowers `plane_exclusive_sum` / `plane_sum` to shuffle loops on
  CUDA: replacing them by a ballot and population counts took the port from 2.33 to 1.57 fs. Named next fixes
  (unmeasured): common masks from the transpose's registers; one 16-byte parent record per load; a radix-sort
  preparation: worth ≈ 0.4 fs if they reach v10's numbers (→ ≈ ×5).
- CubeCL kernel timings are bimodal across processes on this box (≈ +25 % in the slow mode; stable within a
  process): the window plan now asks for four rounds, median and minimum.
- Window driver dry-run end to end against the CUDA binary.

## G2.3 The benchmark kernel ported to CubeCL: exact on lavapipe, priced for RDNA4, window plan (2026-11-17 07:43–10:25 UTC, engineer, ivory only; `G2/PORT-NOTES.md`, `G2/WINDOW-PLAN.md`, `G2/port/` (bundle `g2-cubecl-local.bundle`, head 3a3a467 on main 7e0113f, never pushed; `raw/` incl. the dry run), worktree `.worktrees/g2-cubecl` (`common/examples/g2_cubecl.rs`, ≈ 1,500 lines); also `G2/PROPOSAL.md`, `G2/proposal/NOTES.md`)

- **Port** [M on lavapipe 26.0.8 in the container `localhost/lvp26`, WGSL and direct SPIR-V compilers]: both staged
  super-units whole: every unit's survivor set equals the prototype's, counts equal the CPU reference, the GPU
  preparation's parent order equals the CPU's; plane widths 8 and 16, both transposes (shuffle and ballot);
  SPIR-V and WGSL modules have identical atomic operations in all 20 kernel variants. Not proven: the 32- and
  64-lane paths (lavapipe gives full planes only up to 16).
- **CubeCL defect found:** cubecl-spirv emits invalid SPIR-V for `loop` / `break` (wgpu reports only "Buffer
  invalid"); worked around.
- **RDNA4 pricing** [M: ACO on RADV with the amdgpu no-op shim, gfx1201; D: the prediction]: 25.6 KB of LDS per
  work group → 8 waves per SIMD (production's join: 16); the 64-pair word step 208 VALU per 128 lane slots; the
  shuffle transpose 5× cheaper than ballots; main on the card ≈ 5.1 fs per admissible n at b64 (from N22's 0.55
  field ratio and today's 3080 timing). **Predicted ratio on the RX 9070 XT: ×4.4 central (×3.3–5.6).**
- **Window plan:** ≈ 22 of 45 minutes: exactness at 64 lanes, three rotated rounds of three G2 variants, main's ten
  b64 fields; stop below ×4.0 same-session (the proposal's line). Driver dry-run end to end on lavapipe.
- **Proposal** (`G2/PROPOSAL.md`): base 64's range is [2^75, 2^76); moving n's bits 24–53 to bits 45–74 renumbers it
  one-to-one so that aligned ranges are whole super-units: 262,144 fields of 2^57 in today's `fields` table
  (≈ 23 s each on a 3080); server change = a claim gate and a submit guard (150–250 lines), or none with a private
  coordinator; backends needed: CubeCL on Vulkan and CUDA, plus the CPU version as audit reference; 15–22
  agent-days, 2–3 days of maintainer review; whole base 1,652 card-hours on a 3080 against 8,462.

## G2.2 The redesigned join on a GPU: one real b64 super-unit against same-session main (2026-11-17 05:50–07:28 UTC, engineer; `G2/BENCH.md`, `G2/bench/box_out/` (per-variant dev logs, protocol runs, client logs of main, proofs of the host block), `G2/bench/variants/` (kernels v1–v11), `G2/bench/g2bench.cu` = v10; box 61025183, RTX 3080 10 GB at a 260 W cap, 1.73 h, ~$0.21)

- **G2, super-unit π′ = 712012851 (all 64 units; 4.4679e12 admissible n), kernel v10, 3 rounds** [M]: preparation 431–433
  ps per parent (0.101 fs per admissible n); bottom side alone 18.5–19.8 ps per stored child; 17.6–17.8 ps per flat
  chunk incidence; **31.7–32.0 ps per kept 64-pair word all-in** (27.5 without the survivor append); **end to end
  1.1226–1.1240 fs per admissible n**; a second super-unit (391856203) 1.1224 fs. Plus tops 0.049 fs (B64.1's FD
  test on every top) and survivors 0.066 fs (20 ps per AND survivor + main's check) [D from measured unit costs]:
  **1.24 fs**. Power while busy 148–203 W at ≈ 1.8 GHz (main: 258 W). Kernel: 72 registers, 32.2 KB LDS per
  256-thread group, 3 blocks per SM.
- **Main 7e0113f, same box and session, cubecl-cuda, real client against the stub (production hosts blocked and
  proven), ten b64 1e17 fields at 0.05–0.95 with the 3 empties counted, 3 rounds** [M]: 6.254, 6.386, 6.402 fs per
  admissible n (mean 6.35).
- **Ratio: ×5.13 (×5.05–5.17); ×4.75 with the review's 8 % allowance for host and launch overhead.**
- **Exactness** [M]: every kernel variant reproduces all 64 units' survivor sets of both super-units (11,768,560
  and 11,769,950 n) and the CPU reference's counts exactly.
- **Against the stop numbers fixed before the run:** word 32.0 ps > 25 ps (fails); stored bottom 18.5–19.8 ps ≤ 25
  (passes); ratio between ×5 and ×6 with no named culprit that has a measured fix → **stop: the run on the RX
  9070 XT is not earned on my own initiative.**
- **Where the cost is:** the inner loop is bound by LDS issue (17 independent 8-byte slice loads per kept word; ≈ 2×
  the LDS floor); the common-mask skip's 49 % mostly does not pay on SIMT lanes (60.5 % of lane slots do work;
  full mode only 10 % faster than skip off); the staged draft cost 4.93 fs and ten variants took it to 1.12.
- **Model check:** measured 1.24 fs against the designer's 0.54 and the reviewer's 0.965 central (high 1.72):
  the word is above the reviewer's high end (21.8 central, 29.3 high; measured 32.0), the bottom side and prep
  are 2× the reviewer's central.
- Unmeasured: the RX 9070 XT (LDS-bound kernel; 32 KB LDS against production's 18.9 KiB sweet spot; RDNA4's LDS
  throughput could favour or hurt it), Metal, a CubeCL port.

## BX.2 The pairing gap on real masks: closed (2026-11-17 05:50–08:20 UTC, the adversary resumed; `BX/a3-adversary/NOTES.md` "Day 2", `BX/a3-adversary/day2/`; real super-units b64 712012851 and 400000017, b62 696365039 and 123456791, shape (4, 10))

- **The gap, per admissible n at b64** [M; b62 has the same ratios]: pairs 3.58e-3; passing pairs 2.64e-6; G2 flat
  64-pair words 5.61e-5; G2 kept words 2.76e-5 (kept fraction 0.492, reproducing the staged unit and the
  prototype's survivors exactly); words holding at least one passing pair 2.45e-6 (×11 below kept); optimally
  packed words 4.2e-7 (×65 below kept).
- **Why none of it is reachable:** 91 % of kept words hold no passing pair, and certifying such a word needs digits
  of the top that cover all 64 bottoms: 5–8 of the top's own digits in 86 % of cases (median 6), specific to the
  top. Covers that can be precomputed per chunk: the common mask skips 51 %, 2-covers add 7–9 %, 3-covers < 1.5 %.
- **Schemes** (costs: the G2 review's bands, word = 7 + 0.9 ps per digit ORed central, skip test 1 ps, child reorder
  5–60 ps): best practical = per-(class, unit) presence buckets on the 4–5 most frequent digits: ×1.14 at b64
  (×1.04–1.18), a loss at b62 (children outnumber kept words ×2.3); parent sort key only: ×1.03–1.06;
  clustering, full sorts, greedy chunk formation: within ×1.13 of G2's word count; two-sided blocking ×1.03;
  hierarchical masks cut only skip tests (9 % of the cost); early exit from a word saves nothing (11 of ≈ 16
  lookups still needed); a trie over tops needs ×1.43 fewer lookups per lane but more per 32-lane warp (CPU build
  0.5× G2's loop). **Ceiling with every auxiliary cost at zero: ×1.36 at b64.**
- Asymmetry: tops skewed only on digits 1–3 (45–54 % of tops at b64), bottoms only on residue digits; pairwise
  co-occurrence null; G2's 8-bit key already uses them. Not measurable here: binary matrix multiply on tensor
  cores (capped near ×1.25 by the per-pair zero test even if the multiply were free).
- **Verdict: kill criterion met (nothing ≥ ×1.5). The pairing line is closed; what is left is the cost of the
  64-pair word itself, i.e. the GPU benchmark.**

## T2.10 Realized gain of main 7e0113f (#259, #260) on demoux at base 62 (2026-11-17 05:45 UTC, director, public API by bounded id ranges; `../2026-11-fresh-eyes/recent_niceonly_1117.json`)

- demoux switched from 0711b16 to **7e0113f** (adds #259 the population-count prefilter test and #260 the top
  append fix) at 2026-11-16 23:05 UTC. Real base-62 fields, hours kept only if their median is within 1.25× the
  build's (all 12 + 7 hours qualified).
- 0711b16: n = 794, join median 48.4 s, 61.6 ps per survivor. 7e0113f: n = 532, median 47.4 s, 59.9 ps per survivor.
- **Realized: ×1.029 per survivor (×1.019 in median join seconds on slightly denser fields); 77.5 → 79 real fields
  per full hour.** Predicted: #259 ×1.037 at b62 (window, 3 rounds) less #260's +0.2–0.3 %.
- Since 11-15 morning on demoux: 51 → 79 new fields an hour (×1.55: the claim-queue fix ×1.27, #251 + #256 ×1.21,
  #259 ×1.03). Fleet still v3.4.7 (RTX 4060 median ≈ 299 s); no release tag. Frontier 207076982 of 207159539
  (82,557 fields left).

## T2.9 Realized gain of main 0711b16 on demoux at base 62, from telemetry (2026-11-16 20:55 UTC, director, public API by bounded id ranges; `../2026-11-fresh-eyes/recent_niceonly_1116b.json`)

- demoux switched from a7a59c1 to **0711b16** (main with #251, #256, #262, #263; before #259 and #260) at
  2026-11-16 12:52 UTC. Real base-62 fields (join `run_secs` > 1), hours kept only if their median is within
  1.25× the build's (all 25 + 9 hours qualified: no shared-card hours).
- a7a59c1, last 24 h before the switch: n = 1,557, join median 58.1 s (mean 55.2), 72.8 ps per survivor.
  0711b16: n = 634, median 48.0 s (mean 45.6), 61.8 ps per survivor.
- **Realized: ×1.21 in join seconds (median and mean), ×1.18 per survivor (the fields since the switch have ≈ 3 %
  fewer survivors); real fields per full hour 65 → 78 (×1.20).** The windows had predicted ×1.18–1.19 (#251
  ×1.12–1.13 × #256 ×1.056).
- Fleet: still v3.4.7 (8bd154b), median ≈ 305 s. No release tag yet (latest v3.4.7). Main 7e0113f CI all green.

## G2.1 A second-generation join from a clean slate: design, adversarial review, benchmark staged (2026-11-16 16:28–18:45 UTC, designer, independent reviewer; `G2/RESULTS.md`, `G2/NOTES.md`, `G2/model.py`, `G2/model2.py`, `G2/proto/` (exact CPU prototype), `G2/raw/`; `G2/REVIEW.md`, `G2/review/` (independent predicate, `model_review.py`, `order.py`); `G2/BENCH.md`, `G2/bench/` (inputs for one b64 super-unit, `g2bench.cu`, box scripts); no GPU run yet)

- **Design:** work unit = transversal super-unit π′ = digits 4–8 of n (every leading and low value); shape (f0 4,
  k 10); the depth-9 bottom parents built once per super-unit and shared by the b units of digit 9, the deepest
  digit generated in registers from two affine digits (never stored); top-driven pairing over 64-chunks of
  bottoms sorted by a key that puts the tops' frequent digits first, one AND with a chunk's common mask skipping
  42–51 % of chunks, bit-sliced or four-Russians 64-wide tests, one nonzero test per word.
- **Counts** [M, exact CPU prototype on real b62 / b64 units; reviewer re-measured 4 more units per base within
  8 %]: per admissible n at b62 / b64: pairs 3.9e-3 / 3.5e-3, flat chunk incidences 6.1e-5 / 5.5e-5, kept 3.5e-5 /
  2.7e-5, survivors 3.3e-6 / 2.6e-6 (÷75 / ÷58 against today), tops tested 2.06e-6 / 4.69e-7 if every f0 = 4 top is
  tested. At b64 the pair count equals today's pruned count: the gain there is cost per pair.
- **Soundness** [M]: 14 whole bases b10–b28 against brute force (author); the reviewer's own predicate, written
  from the definition, matches the prototype's survivor *sets* on whole bases 10, 18, 25, on one real b62 unit
  (18,944 survivors) and one real b64 unit (183,776) enumerated from scratch, and on the unit with the base's
  last clipped top.
- **Model** [D]: author ×10.1 at b62 (×4.7–17.6), ×8.3 at b64 (×5.1–13.2). **Reviewer's correction: ≈ ×5 at b64
  (×4.7 against a 4.5 fs baseline, ×5.5 against 5.3 fs; band ×2.6–9.6); b62 (4,10) ×4.5–4.9, (4,9) ×5.2–5.7.**
  Reasons: the 64-pair word costed at 12.7–14.9 ps against 17.8 ps measured for the nearest analog (N1.G1;
  ≈ 25 ps calibrated); the b64 four-Russians table amortized over 464 probes instead of ≈ 226 kept (author's
  own model then ×7.2); the b62 bottom side at ≈ 8 instructions per child and a sort ~70× cheaper than any GPU
  sort; tops and bottoms need opposite super-unit orders (+0.21–0.36 fs at b62, +0.03 at b64). Sensitivity at
  b64: word 10 ps → ×8.5; 15 → ×6.9; 20 → ×5.8; 25 → ×5.0.
- **Baseline** [M/D]: today's main ≈ 12.1–13.2 fs per admissible n at b62, 4.5–5.3 fs at b64 (base means, RTX 3080).
  A whole base ≈ 1,150 card-hours at b62 and 6,000–7,200 at b64 today.
- **Server:** needs units keyed by the shared middle digits ("all n whose digits 4–8 lie in [p0, p1)"):
  homogeneous, resumable, auditable by survivor counts, algorithm-agnostic; but no field is complete until the
  base is, every backend needs an implementation before a base can switch, and a mid-base switch is exact only
  with a frozen snapshot of completed fields. With today's 1e17 fields ≈ ×1.05 transfers.
- **Benchmark** (the reviewer's specification): one real b64 super-unit end to end on an RTX 3080 at 300 W against
  the same-session main: stop above 1.06 fs per admissible n (< ×5) or a kept word > 25 ps or a stored bottom
  > 25 ps; on to the RX 9070 XT at ≤ 0.88 fs (≥ ×6); ×10 only at ≤ 0.53 fs. **Staged, not run:** the resumed
  designer's ssh to the box was refused by the harness; inputs (π′ = 712012851, 64 units, 238,813 tops, survivor
  sets of 11,768,560 n), `g2bench.cu` with a CPU reference that reproduces every unit's survivor set (children
  7.54e-6, flat 5.61e-5, kept 2.76e-5 (0.492), survivors 2.63e-6 per admissible n) and the box scripts are on ivory.

## BX.1 Below exhaustive: three independent attacks and the director's own accounting (2026-11-16 16:28–18:45 UTC; `BX/COMMON.md`; `BX/a1-progressions/NOTES.md` (+ `code/`, `out_*`), `BX/a2-digitsets/NOTES.md` (+ `code/`), `BX/a3-adversary/NOTES.md` (+ `code/`, `data/`))

- **Question:** can any method do work that grows more slowly than the number of candidates, or find a condition
  on partial information that involves the middle output digits?
- **A1, polynomial progressions and lattices: no** [M at b20–62]. Every middle output digit behaves as a random
  function of each single digit of n (b62: 36–48 values on changing one digit; random 39); no view of up to
  L − 2 digits of n and no n mod q (q ≤ 1,500) predicts a middle digit by more than 0.04 (noise 0.02); output
  digits do not predict it either. A counting identity: any prescribe-outputs-and-solve method (any lattice, both
  progressions together, solving free) pays one call per allowed choice while each fixed digit cuts one digit of
  candidates: it loses to the tree at every node (b40 prototype 41.7 k operations per top against 29.6 k).
  **New exception to "two outputs per fixed digit": ramified slices p^j | n for b = p·q** (n/p^j mod q^c certifies
  2c outputs; ×12 fewer tree nodes per candidate in the 49 | n slice at b28); useless for finding (each digit of
  slicing gives up a factor b of the expected count for ≈ e^1.2).
- **A2, the exact cover: no** [M at b17–40 and at the real b62 shape]. Complement conditions computable per side
  reject 0 of 4,400 AND survivors (0 of 150 at b62); digit-class identities reduce to the mod b − 1 root;
  mod b + 1 splits and value bounds reject < 8 % and need n. The best possible adaptive digit tree (exact DP) is
  ×4–6 worse than the flat join; CP-SAT and CaDiCaL sit at ×1–16 of that tree with no trend and ~1e5 slower per
  node, and reveal no pruning rule. Inclusion–exclusion: truncation at level m errs by exactly Σ C(f_n − 1, m)
  over non-nice n; the full sum is 2^b terms. Representations: O(L²), no merge level. Side finding: the 2026-08
  CP-SAT model admits digit-count splits that cannot occur (results unaffected).
- **A3, measurement and adversary: no hidden structure; a lower-bound model with its optimum** [M]. Every
  candidate of bases 10–33 (≈ 7e9 n) and windows at b40–62: no residue (1,643 moduli), digit statistic, position
  feature or boosted model predicts niceness or the middle (held-out R² = shuffled control); the middle given
  the ends is uniform to 1e-4 per digit, pairwise independent (square–cube pairs included), passes an all-orders
  test, and the near-nice tail matches the product formula (0.977 ± 0.016). "View certificates" model (views =
  fixed digits of n or n mod m; a view reveals outputs constant across it; discard only on a repeat): exact
  optimum for b20–33 by a fractional cover over all prefix × suffix views: the flat join is ×1.5 → ×5.9 above
  the floor at unit weights (≈ ×1.085 per base), ×1.03 → ×1.11 at production weights by b32; **an ideal join that
  pays only for pairs passing disjointness lands on the floor.**
- **The one slack left: the pairing step, which is orthogonal vectors on digit masks.** Ideal inside a transversal
  unit: ×8–27 on the pair term (A2 I8); dual trees cost 6–10× a flat AND, block prunes ×1.0–1.2, digit keys
  ×1.3–1.5; G2's sorted-chunk skip keeps 0.45–0.58 of chunk incidences.
- **Verdict:** no method below exhaustive, with measurements behind each angle. What remains is constant-factor
  structure: G2 (≈ ×5 at b64 if the GPU costs hold) and whatever of the pairing gap a GPU can take.

## MU260.1 #260 merged up over #251's `ran` words; v3.4.7 against main at default power (2026-11-16 05:50–08:05 UTC, engineer, then director after a harness outage stopped the agent; `MU260/RESULTS.md`, `MU260/RELEASE-NUMBERS.md`, `MU260/work/` (merge-file inputs, `merge_vs_int.diff`, `p255.diff`, `p259.diff`, `interdiff.txt`), `MU260/box/logs`, `MU260/t2/`; fork `pr/top-slot-any-plane` 31ba079 = merge of ec6a43a and main 0711b16; box 60886021, RTX 3080 at 300 W, 2.27 h, ~$0.30)

- **Resolution:** `cubecl_join.rs` = main's file plus the change that took `exp/integration-1114` from 99b283a to
  8bcee21 (`git merge-file`, 0 conflicts). `STAGES` 4; #251's check words at `STAGES + 1`, `+ 2`; `TOP_ACCOUNT` =
  `STAGES + 3` (two words); `RAN_WORDS` = `STAGES + 5`; #251's test-only smallest-take word moved from
  `STAGES + 3` (a silent overlap: it merged without a conflict) to `TOP_ACCOUNT + 2` = `RAN_WORDS`; assert
  `TOP_ACCOUNT + 2 == RAN_WORDS` (I read these lines in the pushed file).
- **Mechanical checks** [M]: merge against 8bcee21: 14 hunks, all in what #255 / #259 change; applying #255's then
  #259's own diff to the merged file gives 8bcee21's file byte for byte. Main against the merge: `cubecl_join.rs`
  and one changelog line only.
- **Verification** [M]: `just lint` clean; host tests 207 (ivory, debug) and 260 (box, CI's command); CUDA: #251's
  and #260's partly-filled-warp tests, the CPU-reference suite with both PRs' fault tests on the one `ran` array
  (each fault reports its own words), the certificates test, the heavy FD comparison, dense compares at b60 1e16,
  b62 1e17 (170,247,827 / 10,384,896), b64 1e17 (697,596,881 / 43,247,716); lavapipe from Mesa 26.0.8 (26.04
  chroot) as CI: WGSL 40 passed, SPIR-V 31 passed, incl. the lane-0-out tests (552 runs, 6,492,699 tops); SPIR-V
  against WGSL atomic operations: 902 kernel variants, none missing.
- **Two totals differ from 11-14 for the same commands** (b60 dense 336,157,460 / 22,524,024 against 334,071,589 /
  22,383,910; heavy FD total 422,559,183 against 423,104,943): the 11-14 build 8bcee21 run on today's box gives
  today's numbers [M, `GI_*.log`], so it is the box, not the code; the likely input is the card's reported memory,
  which sets the first slice's extent [inferred, not shown]. Whole-field totals do not depend on slicing.
- **v3.4.7 (8bd154b) against main 0711b16, b62 1e17, RTX 3080 at 300 W (289–297 W, 1.83–1.86 GHz), 3 real fields × 2
  interleaved rounds** [M]: join 161.6 s against 49.8 s: **×3.25** (3.20–3.31); wall 163.3 against 51.6: ×3.17.
  Main's counts equal 54d0aac's exactly (6 of 6); v3.4.7 within the audit's bound (6 of 6). NiceMark nice-only GPU,
  2 rounds, API at a closed port: score 4,622 → 10,559 (×2.28); b58 msd-weak ×2.53, b58 msd-strong ×1.48, b60
  ×2.76, b62 ×2.65.
- A release from 0711b16 since v3.4.7: the GPU join ≈ ×3.2 per field; #263 and #251's host checks (a misbehaving
  device fails its field instead of submitting); no new client flags, no changed defaults; Rust 1.100.0; the GPU
  image built on ubuntu-24.04 runners (#261); #238 / #264 are server-side.

## Q1.2 Realized effect of #264 (2026-11-16, director, public API by bounded id ranges; `../2026-11-fresh-eyes/recent_niceonly_1116.json` = nice-only submissions with id in (294552514, 295551140])

- #264 merged 2026-11-15 15:06 UTC; deployed at once by the evidence below.
- Real base-62 submissions (join `run_secs` > 1) [M]: **before** (01:00–15:06 UTC, 14.1 h): 1,091, of which 253 are
  a second search of a field (23.2 %; 23.1 % of join seconds): demoux 724 new + 218 repeats, fleet 114 + 35.
  **After** (15:06 → 05:43 UTC, 14.6 h): 1,012, **0 repeats**: demoux 954 new, fleet 58 new.
- New fields per hour: demoux 51.3 → 65.2 (**×1.27**); all clients 59.4 → 69.2 (×1.16; the fleet submitted
  nothing from ≈ 15:00 to 23:00 UTC). demoux's real submissions per hour unchanged (66.8 → 65.2): the same work,
  none of it wasted.
- demoux build a7a59c1 throughout (median join 57–60 s); fleet v3.4.7 on RTX 4060 / 3060 / 3070 / V100 (medians
  320–425 s).

## Q1.1 The nice-only claim queue handed fields out twice at base 62; PR #264 (2026-11-15 09:31–10:15 UTC, engineer and independent reviewer; `Q1/RESULTS.md`, `Q1/PR-BODY.md`, `Q1/REVIEW.md`, `Q1/raw/` (`analyse.py`, `routes.py`, claims data, `test_runs_after_review.txt`), `Q1/b62_niceonly_submissions_to_0929utc.json`; fork `pr/api-niceonly-queue-stale-claims` 516444e = 6a62913 + acc615d (the review's removal of the detailed age limit) + the changelog number; scratch Postgres on ivory, no box)

- **Production, base 62, 00:58–09:29 UTC** [M, public API]: 655 real nice-only submissions on 530 fields; 125 fields
  searched twice (19 % of submissions, 18 % of join time); pairs 95 demoux twice / 24 one client then another / 6
  fleet twice; nice-only hand-outs 83–93 an hour; refills at 02:18, 03:59, 06:15, 08:33 UTC each re-claimed the 50
  fields still queued (route A) plus 6–9 handed out and unsubmitted (route B). Of 213 fields with two nice-only
  claims: 186 route A, 27 route B, none other. Detailed queues: ≈ 9,100 claims an hour, queue ages 1–20 minutes: safe
  today.
- **Mechanism** [R]: `REFILL_AMOUNT` 200 at `REFILL_THRESHOLD` 50, FIFO without an age check; a hand-out writes a
  `claims` row but the field's claim runs from the bulk claim; `CLAIM_DURATION_HOURS` 1.
- **Fix:** a refill replaces an already queued field in place (`merge`, all queues); each nice-only claim is renewed
  at hand-out (`renew_niceonly_claim`: `UPDATE fields SET last_claim_time = NOW() WHERE id = $1 AND
  last_claim_time = $2 AND check_level = 0 RETURNING *`), a field with no matching row is skipped. The detailed
  age limit of the first version was removed on review (not needed; a clock-skew risk).
- **Tests** [M]: reproduction by back-dated claims on a scratch Postgres: main-like code hands 100 fields out twice;
  merge only 50; renewal only 0; both 0. Reviewer's stress test (two queues as two API processes, 8 claimers, a
  direct claimer, claims aged 61 minutes every 15 ms): 3,600 hand-outs, 3,600 distinct fields on the branch;
  4,008 duplicates on the main-like mutant. Timestamp equality exact against Postgres 17 (also under odd time
  zones). Cost: one single-row update per nice-only claim, 0.013 ms with the repository's indexes, 0.046 ms
  with the claim indexes dropped as in production. `cargo test -p nice_api` with and without the database,
  `claim_queries`, `just lint`: pass.
- Not verified: production's index set and clock; behaviour under the real API's load (the deploy notes say what
  to watch).

## T28.1 Early audit of base 62: every instant verdict, 156 re-run comparisons, main against v3.4.7; the duplicate searches (2026-11-15 05:57–09:30 UTC, agent; `T28/RESULTS.md`, `T28/raw/` (`instant_check.py`, `instant_summary.txt`, `compare.py`, `compare.txt`, `compare_detail.jsonl`, `proof_hosts_block.txt`, queues, `box/`); duplicates: director, `Q1/b62_niceonly_submissions_to_0929utc.json`; box 60746721, RTX 3080 capped at 150 W (≈ 1.14 GHz), 3.61 h, ~$0.42)

- **Instant fields** [M]: all 8,665 base-62 fields submitted with zero survivors and zero checked (census to 09:01
  UTC) are empty by an independent big-integer check: 8,385 by leading digits 1 and 1 (x = n / 62^12 < 2^(1/3)), 263
  by another collision among the top digits the range fixes, 14 by Hall's condition at the first position where
  the range's ends differ, 3 after subdividing. The client's certificate (read from the code): per slice, a
  breadth-first pass over the top 8 of n's 13 digits (t = 10, k = 6, p = 2), `Base::cert` with cap 6. Of the 329
  fields the clients ran, none falls to a stronger field-level argument; deeper subdivision proves one empty
  (207072495; 193 survivors, 32 checked).
- **Re-runs** [M] (main 54d0aac against the stub; production hosts blocked and proven): 112 fields, **156
  comparisons, 0 mismatches**: 91 exact equalities of survivors, checked and the number list (85 demoux a7a59c1
  submissions, 6 repeats of main); 65 v3.4.7 comparisons inside the 11-12 overrun-model bound (53 fleet
  submissions, all RTX 4060; 12 v3.4.7 runs on the box; max |d| / tolerance 0.49, max overrun 3.2e-6 of a field's
  survivors). No nice number.
- **Main against v3.4.7 at b62 1e17** [M]: 5 real fields × 2 interleaved rounds on the 3080 at 150 W: v3.4.7 takes
  **×3.13** main's join seconds (geomean; 2.99–3.21), ×3.08 wall; main 75–100 s, v3.4.7 239–301 s. Derived for the
  fleet's RTX 4060s (assuming the ratio carries over): 337 s → ≈ 108 s a field.
- **Duplicate searches** [M, my own count from the API, 656 real submissions to 09:29 UTC]: 530 distinct fields;
  **126 fields searched twice = 19.2 % of real submissions, 17.9 % of join seconds**; pairs: 96 demoux–demoux, 24
  demoux–fleet, 6 fleet–fleet; gap between the two submissions median 2,282 s (p10 2,007, p90 2,536); per hour 0,
  2, 0, 25, 24, 8, 42, 0, 25; the repeats agree with the first. Mechanism read in `api/src/field_queue.rs`:
  `REFILL_AMOUNT` 200 at `REFILL_THRESHOLD` 50, FIFO, no age check, against `CLAIM_DURATION_HOURS` = 1; predicted in
  BACKLOG item 1 on 2026-10-09.
- **Estimate** [D]: 76,762 of the 86,245 fields past the processed frontier (207073292) need a real run; at 61.7
  new real fields an hour ≈ 1,245 h → **2027-01-06**; without the duplicates ≈ 2026-12-26; with the fleet on main
  as well ≈ 2026-12-23. Base 62 began at 00:57:50 UTC; 35 % of fields submitted past the boundary were instant.
  Base 60 complete (162,076 fields at check_level ≥ 1).

## N22.1 The next gain for the RX 9070 XT, found offline: the walk as a per-lane loop (2026-11-15 05:57–08:36 UTC, agent; `N22/RESULTS.md`, `N22/WINDOW-PLAN.md`, `N22/raw/` (`aco_tables.txt`, `aco_repeat.txt`, `ab_table.txt`, `shares.txt`, `topfd_blocks_b6{2,4}.txt`, `scripts/`, `box/`); fork `exp/n22-rdna4` c750605 (switches `NICE_EXP_N22` on `exp/integration-1114` 8bcee21) and `exp/n22-walk-lane-spirv` 86b7ab0 (W alone, gated to `wgpu<spirv>`, one commit); box 60746198, RTX 3080 at ≈ 285 W, 2.84 h, ~$0.32)

- **Shares on the card after the five open PRs** [D from N17.1 / N13 phase timers and each PR's on-card gain]:
  b62 1e17 ≈ 58 s: FD top 26 %, prefilter 24 %, AND 12 %, join base 8 %, walk 7 %, check 7 %, bucket 5.5 %,
  other 5 %, upload + host 5 %. b64 1e17 ≈ 93–96 s: prefilter 26 %, AND 14.5 %, FD top 13 %, check 11 %, walk
  11 %, join base 7 %, the rest 17 %.
- **ACO (Mesa 26.0.8, gfx1201 through RADV's amdgpu no-op shim; `RADV_FORCE_FAMILY` is gone in Mesa 26)** [M]:
  walk round 44 ALU instructions (33 VALU / 9 SALU / 2 LDS) on the integration build; join kernel 96 VGPRs, LDS
  15,360 B, 16 waves per SIMD; check kernel 48 VGPRs, 32 waves.
- **W, the walk over a chunk's pass bits as a per-lane loop instead of the plane vote:** 44 → 40 per round at b62
  and b64 [M, three dumps; I read `aco_tables.txt`]. Predicted on the card with N21.2's price (0.95–1.09 s per
  instruction per b64 1e17 field): **×1.040–1.048 at b64, ×1.021–1.026 at b62** [D]. W + B (b64's low digits as one
  bit field, two lines in #255's code): 38 at b64, ×1.060–1.075 [D]. W makes `exp/n21-ffs-pop` unnecessary.
  **CUDA: ×0.676 at b62, ×0.615 at b64** (3 rounds, counts identical) [M]: SPIR-V only.
- **K, the check kernel's limb products as 24-bit multiplies:** quarter-rate multiplies 240 → 64 (b62), 114 → 0
  (b64); predicted ×1.00–1.03 / ×1.00–1.04 depending on whether the check is issue-bound on the card (unknown);
  CUDA ×1.004 / ×0.979. **A, a fixed-trip AND digit loop:** −24 % of that loop's instructions, predicted
  ×1.02–1.03; CUDA ×0.897 / ×0.837 (48 → 80 registers there; 96 VGPRs unchanged on AMD).
- **Nothing reaches ×1.04 at b62:** the FD top kernel (26 %) is ≈ 880 instructions per stepped slot in a dozen
  pieces, none above half; the two cheapest fixes price at ≈ ×1.01 each. The next b62 lever must change what a
  slot computes.
- Exactness [M]: every switch equals the CPU join on CUDA at b62 and b64; lavapipe 26.0.8 (26.04 chroot) 11 / 11
  with both compilers; 256 host tests incl. an exhaustive check of K's division at bases 10–64; no atomic store
  added. `go22.sh` (window driver) dry-run end to end on the box; cargo 1.100 changed where test binaries land,
  which breaks `go13.sh`'s build step.
- **Verdict:** kill criterion not met (W ≥ ×1.04 predicted at b64). Nothing is measured on the card: a 30-minute
  window decides (b64 1e17: three rotated rounds of base / W / W+B / K; b62 1e17: one round of base / W / K / A).

## B62.1 Base 62's first hours, from telemetry (2026-11-15, director, public API by bounded id ranges; `../2026-11-fresh-eyes/recent_niceonly_1115.json` = nice-only submissions with id in (294552514, 294806748])

- 12,705 nice-only submissions since the 11-14 snapshot: demoux 10,390 (a7a59c1), fleet 2,315 (v3.4.7 8bd154b).
  Base 60's last fields (ids ≤ 207064109): demoux 2,601, fleet 1,042. Base 62 (ids ≥ 207064110; 1e17 fields;
  `range_start` of the first = 62^12 = 3226266762397899821056; last id 207159539): demoux 7,789, fleet 1,273.
- **Instant fields** (join `run_secs` ≤ 1 or absent): demoux 7,479, fleet 1,223. Explanation [D]: x = n / 62^12,
  leading digits ⌊x²⌋ and ⌊x³⌋ are both 1 for x < 2^(1/3) → 62^12 · 2^(1/3) = 4.06484e21 = field index 8,385; first
  real fields: fleet id 207072495 (index 8,385), demoux 207072501 [M]. Both 2 for x in [√2, 3^(1/3)): indices
  ≈ 13,364–14,268 [D]. Past the boundary, of 570 fields claimed so far 360 were real (310 + 50) [M]: 37 % instant.
- **Real fields** [M]: demoux n = 310, join `run_secs` median 56.2 (p10 47.2, p90 63.8, max 73.3), setup ≈ 6 s,
  slots 6, slices 14, 3,844 partitions, survivors median 7.57e11, checked 4.49e10; 61–69 real fields an hour.
  Fleet (RTX 4060, v3.4.7) n = 50: median 338.0 s (p10 285, p90 379); 10–11 an hour.
- **Estimate** [D]: frontier id 207073065 at 2026-11-15 03:59 UTC, 86,474 fields left; at 75 real fields an hour:
  30 days if 37 % stay instant, 41 days at 15 %.

## T26B.2 #263's CI failure: cubecl-opt drops same-value atomic stores in a block (2026-11-14 20:26–23:35 UTC, engineer resumed and the reviewer resumed; `T26B/CI-FAIL.md`, `T26B/REVIEW2.md`, `T26B/CUBECL-ISSUE-DRAFT.md`, `T26B/ci-fail/` (CI's log), `T26B/raw/ci/` (`dump/` modules, `box/` logs, `add_mini.py`, `stores.py`), `T26B/review2-box/` (per-tree comparison tables, modules, probe kernel); fork `pr/stride-queue-any-plane` ffcfcfc = 85fe64a + changelog number + merge of main 54d0aac + comment fix + 165192b (the fix) + a comment; boxes 60693354 and 60694347 (host m16641 refuses ssh keys; 0.19 h + 0.34 h), 60696216 (RTX 3080 host, 48 threads, Ubuntu 26.04 chroot with Mesa 26.0.8, 2.36 h, ~$0.29))

- **Symptom** [M]: CI's lavapipe job, SPIR-V step (llvmpipe LLVM 21.1.8, Mesa 26.0.8, ubuntu-26.04 runner), test
  `cubecl_queues_check_every_survivor_on_partly_filled_planes`: 7 of 32 runs stopped by the account with impossible
  values (b40 has 283 survivors: "3401", "182536111", "128849019 fewer"; "low words differ by 109 / 347"); twice in
  two CI runs. WGSL step 32 of 32, Metal passes, older Mesa (25.2.8) passed for author and reviewer.
- **Cause** [R][M]: `clear_queue_account` had unit 0 run four `store(0)` on a `SharedMemory<Atomic<u32>>` at indices
  0–3. cubecl-opt 0.10 `MergeSameExpressions` (`passes/expression_merge.rs` `check_op`, lines 111–145) replaces a
  later instruction of a basic block with a copy of an earlier one when their `operation`s are equal and operands
  immutable; `Atomic::store` keeps its target in the instruction's *output* (`cubecl-core` `atomic.rs` line 45), so
  two atomic stores of one value compare equal whatever they point at (I read both source places). The module kept
  one `OpAtomicStore` (counted in `raw/ci/dump/mini_MS.log`: 1 for four stores of 7, 4 for 7/8/9/10; WGSL 4 and 4).
  Account words 2–3 started with stale workgroup memory. Only cubecl-spirv runs the pass (cubecl-cpp: `shared_only`;
  WGSL: no cubecl-opt).
- **Class** (reviewer's probe kernel on Mesa 26.0.8, both compilers) [M]: lost in SPIR-V: several atomic stores of one
  value in one block (one array, two shared arrays, a runtime value, two global atomics, shared plus global, an
  unrolled loop). Kept: stores in separate blocks, plain stores, `fetch_add`, swap. A runtime index alone does not
  protect (argued from source, not run).
- **No survivor lost** [M]: a build that prints the account error and returns the hits anyway: 32 of 32 runs exact
  against the host mirror while the account fired (`is_ci4_1.log`). At bec91fd CI's suite failed 3 of 4 times on the
  box, once at cube 256; the test alone passed 5 of 5 (its own earlier launches leave the words at 0).
- **Exposure** [M]: atomic operations in the SPIR-V module against the WGSL module per kernel variant: main 54d0aac
  419 variants, the fix 425, `pr/top-slot-any-plane` ec6a43a 674, `pr/check-d` 1f41d64 623,
  `pr/join-prefilter-popcount-spirv` 408: **none missing**. (`pr/join-survivor-stage-512` and
  `pr/join-prefilter-shift-pow2` from source: no atomic operation added or moved.) The script flags all 16 pre-fix
  `niceonly_kernel` variants. On an RX 9070 XT the pre-fix PR could have failed stride-walk fields spuriously
  whenever workgroup memory was non-zero; no candidates lost. No RADV device was available (the module is the same
  on every device).
- **Fix** 165192b: units 0–3 clear one word each, a single store in a loop (cannot be merged; covers cubes of 1–3
  units; ordered by the first cube barrier). Verified on Mesa 26.0.8: the test 20 × 32 exact per compiler (author),
  5 × per compiler and CI's SPIR-V suite 3 × 28 of 28 (reviewer's own builds), fault tests, `just lint`; CUDA tests
  on the box's 3080. CI green on 165192b (25 pass).
- **Standing risk:** any future kernel that stores one value into two atomics in one block is silently miscompiled
  on the SPIR-V runtime (the 9070 XT); no CUDA or WGSL test shows it. Options put to the user: a rule in the kernel
  docs, a CI comparison of SPIR-V and WGSL atomic counts per kernel, the upstream report (draft ready).

## T26B.1 The stride walk's survivor queues without full-plane or lane-0 assumptions; PR #263 (2026-11-14 15:45–19:31 UTC, engineer and independent reviewer; `T26B/RESULTS.md`, `T26B/PR-BODY.md`, `T26B/REVIEW.md`, `T26B/raw/` (box logs, repro patches, host model, `ident_summary.txt`), `T26B/review-model/qmodel.py`, `T26B/review-box/`; fork `pr/stride-queue-any-plane` bf6cc8e = 85fe64a (one commit on main 41b4b40, 650 lines in `cubecl_backend.rs`) + the changelog number and a test comment; box 60665092, RTX 3080 at the host's 130 W cap, 3.78 h, ~$0.43)

- **Reproduced on main** (test-only cube size, one cube, b50 window with 30,449 survivors) [M]: RTX 3080, plane-scoped
  queue loses 1,064 / 5,072 / 2,958 survivors at cubes of 100 / 48 / 36 units; cube-scoped 1,217 / 10,152 / 3,382;
  lavapipe (both compilers) cube-scoped 1,217 / 0 / 3,382 (8-lane subgroups fill a 48-unit cube). No production launch
  does this (256-unit cubes are whole planes on CUDA, Metal, RADV). "No lane 0" and non-linear layouts cannot be
  shown on CUDA (CubeCL's lane id is `AbsolutePos % 32`): host model, main wrong in 36–100 % of launches per
  population, the fix in 0 of 12,000 (author) and 0 of 500 per population with interleaved memory operations
  (reviewer's own model; its two mutants fail almost every launch).
- **Fix:** ranks, counts and takes from the running lanes (ballot ≤ 32 lanes, one exclusive scan and one sum of a
  packed word wider); plane-scoped: each plane's lowest running lane reserves two slots per running lane once;
  cube-scoped: one atomic per plane per iteration on two alternating shared words (the serial walk over plane totals
  is gone); account = survivors queued − checked and the same for their low words, written only if non-zero, checked
  by the host in `read_niceonly_hits`.
- **Exactness** [M]: the new tests exact on CUDA (64 runs) and lavapipe (32 + 32); the reviewer's rebuilds are
  byte-identical to the author's; main + the test fails as stated (24 of 32 CUDA, 8 of 16 lavapipe per compiler);
  15 cube sizes on lavapipe 120 / 120 exact, three cubes per launch 120 / 120. **Review F1: the forced scan form on
  partly filled CUDA warps is undefined (CubeCL's CUDA scans read every lane): wrong in 24 of 60 plane-scoped runs at
  255 / 63 / 31 / 17 / 9 units, every one caught by the account; CUDA always takes the ballot form, exact at all 13
  one-cube sizes.** Review F3: on llvmpipe the account does not catch the plane-scoped queue's loss (its report
  relies on the cube barrier llvmpipe mishandles); production keeps that queue off on software rasterizers.
- **Speed, CUDA, stride walk forced, 130 W cap** [M]: 40 b54 fields of 1e13: plane-scoped 83.86 → 73.58 s (×1.14,
  median of 3; reviewer's own builds 81.4, 83.4 → 72.4, 72.4), cube-scoped 93.08 → 73.91 s (×1.26; reviewer 94.2 →
  73.6); scan form forced +0.6 % / −1.8 %; NiceMark stride-forced ×1.23 (one b58 msd-strong round of six at ×0.94,
  median ×1.02). **Under the cap main ran at 1,120–1,160 MHz and the fix at 1,380–1,415 MHz: part of the gain is
  clock; not measured at a default power limit, on a 64-lane device or on Metal.** The stride walk is the join's
  fallback in production, so this is not a search speed-up.
- Stands alone on main; with #251 / #260 only the changelog line conflicts.

## CPU2.2 The CPU skip walk as PR #262: review fixes, the real client at 42 and 8 threads, second review (2026-11-14 15:45–19:30 UTC, engineer and independent reviewer; `CPU2/PR-RESULTS.md`, `CPU2/PR-BODY.md`, `CPU2/PR-REVIEW.md`, `CPU2/raw-pr/` (`ab-summary.txt`, `nicemark-summary.txt`, box logs, scripts), `CPU2/review-pr/`; fork `pr/cpu-join-top-skip` 09f612b = 3ba5766 (one commit on main 41b4b40; same tree as `exp/cpu-top-skip-fixes` e2fe1f5) + the changelog number and two doc comments; box 60665025, 2× Xeon E5-2696 v4 container with a 42.24-CPU quota, 3.02 h, ~$0.35)

- **Real `nice_client`, main against the branch, interleaved, medians of 3 rounds** [M] (a local stand-in for the
  claim API; a measurement-only hook, identical in both, selects slices or partitions and prints the join's time):

  | work | threads | main s | branch s | speed-up | rounds |
  |---|---|---|---|---|---|
  | b62 1e17, slice 0 of 7, 3,844 partitions | 42 | 204.4 | 185.0 | **×1.105** | 1.112, 1.101, 1.103 |
  | b60 1e16, whole field | 42 | 207.2 | 191.7 | **×1.081** | 1.081, 1.079, 1.082 |
  | b62 1e17, partitions 0–1023 | 8 | 241.3 | 213.5 | ×1.130 | 1.164, 1.124, 1.148 |
  | b60 1e16, partitions 0–1023 | 8 | 262.1 | 237.5 | ×1.104 | 1.102, 1.114, 1.099 |
  | b64 1e17, slice 0 of 6 (1 round) | 42 | 816.6 | 806.3 | ×1.013 | |

  Counts identical in every run. The client keeps 75 % (b62) and 61 % (b60) of the one-thread harness's gain at 42
  threads; why was not measured.
- **Memory** [M]: peak RSS at 42 threads 360 → 706 MiB (b62), 382–389 → 745 (b60), 374 → 743 (b64): 8.5 MiB a thread;
  at 8 threads +33 MiB. After the join 196 MiB (main 242; without the free 577).
- **NiceMark CPU, 4 rounds, 42 threads** [M]: score ×1.003; scenarios ×0.993–×1.016 (bit-reversed partition order: no
  skip, no loss).
- **Second review** (`PR-REVIEW.md`): no code change needed. The broadcast free cannot run under the scratch's borrow
  (a thread takes a broadcast only when idle or blocked in a rayon call; `nice_common` does not depend on rayon;
  probe: 900 fields ending concurrently never panicked, one `rayon::join` under the borrow panicked at once); two
  fields' CPU joins never overlap in the client and a clear can only land between partitions (safe: lost skips).
  The morning's harness re-run on the final tree: run bound against big integers on 8.97 M certified evaluations, 0
  above the exact run; main against the branch byte-identical under disorderly schedules. Two more mutants of the
  carry rule fail the new test and pass five older ones. Body fixes B1 (mutant sentence), B2 (261 MiB) applied.
- **Against the bar:** ×1.105 at b62 on one slice of one field on one machine; b60 ×1.081; b64 nothing. Borderline
  for a change of this size; the body says so plainly. Opened on the user's instruction to open held PRs.
- **Process:** the engineer's NiceMark runs sent 80 `GET /ping` to the production API from the box (the benchmark's
  latency probe), against the brief. Nothing claimed or submitted. Briefs now say to point NiceMark at a closed port.

## CI1.1 The GPU image job on Ubuntu 26.04 runners; PR #261 (2026-11-14 11:25–16:30 UTC, director and a Sonnet reviewer; `CI1/PR-BODY.md`, `CI1/REVIEW.md`; fork `pr/ci-gpu-image-runner` 024cf43)

- `ubuntu-latest` gave Ubuntu 24.04 on 2026-11-13 and 26.04 (glibc 2.43) on 2026-11-14; "Build (amd64, GPU) + Push
  arch image" builds on the runner and copies into `nvidia/cuda:12.8.1-runtime-ubuntu24.04`: smoke test fails with
  `GLIBC_2.43 not found` (runs 43585489772, 43585477078 on #260). The CPU amd64 job (into Debian trixie, glibc
  2.41) passed on 26.04 only by which symbols its binary references. No other job copies a runner-built binary
  into an older image (release glibc binaries are built in `cross` containers, musl ones are static).
- Fix: both amd64 image jobs on `ubuntu-24.04`. #261's own run: both on ubuntu-24.04 images, smoke tests pass, 25
  checks green.

## T26.2 Review of the top-append fix; PR #260 (2026-11-14 10:08–10:28 UTC; `T26/REVIEW.md`, `T26/review-model/`; fork `pr/top-slot-any-plane` 9c27023 = f9a2501 + the changelog wording and number)

Independent review of f9a2501 (288 k tokens): **no defect in the code.** The reviewer's own model:
every population of an 8-lane plane exhaustively (3.95 M calls) and 80,000 random launches at
widths 8–64, including planes without lane 0, with holes, split across calls, and indices that
wrap the u32 sums: 0 wrong appends, 0 false alarms. On full planes main and the fix give the
same set of tops per group (3.36 M cases); only the order inside a group changes and nothing
reads it. Plane operations per backend re-read in CubeCL 0.10, naga 29 and cubecl-opt (the open
question about SPIR-V's uniformity marking is settled for this code). The account is computed
from the indices really written and the atomic's real return, on every production path; a
mismatch is a hard error. Cost re-derived from the raw logs (+0.23 % / +0.33 %); the
other-kernels-identical claim re-checked with the reviewer's own comparator.

Findings: the account is a count plus an index sum, so sum-preserving wrong appends pass (model:
0.6 % of the wrong launches of a 64-lane plane misreported as 32; a third word, the sum of
squares, would cut 342 undetected cases to 4): recommended, not required, listed under "Not in
this PR"; three body sentences and the changelog line overclaimed (fixed); **merge hazard with
#251:** both extend the `ran` array; if this lands first and the merge only bumps `RAN_WORDS`,
the two accounts share words and every batch fails loudly. Whichever lands second must name
every `ran` word in one place with a compile-time disjointness assert (`exp/integration-1114`
8bcee21 has the correct resolution for "#251 first"). PR #260 opened 10:28 UTC.

## T26.1 The FD top kernel's append without a lane-0 assumption; the four open PRs merged together (2026-11-14 05:46–10:07 UTC, agent; `T26/RESULTS.md`, `T26/PR-BODY.md`, `T26/raw/` (`repro/`, `model/`, `box/logs`, `box/out`, `box/ident`, `0001-top-slot-any-plane.patch`); fork `pr/top-slot-any-plane` f9a2501 (one commit on main 41b4b40) and `exp/integration-1114` (99b283a = main + #251 + #255 + #256 + #259; 8bcee21 = that + the fix); box 60601437, RTX 3080 at 260 W, 4.38 h, ~$0.49)

**Reproduction:** only `top_fd_kernel` uses `top_slot`. With a test-only switch that takes each
plane's lane 0 out of the call, main's `top_slot` on lavapipe (both compilers) goes wrong in 84
of 276 runs and loses 8.9 M of 13.0 M kept tops (b57 1e14: 110,484 kept, 36,057 counted): no
lane takes the plane's atomic, `grp_cnt` never counts the tops and they are written over other
records. On CUDA a partly filled warp is always lanes 0..r−1, so main is correct there, and a
lane 0 that sits out leaves CUDA's full-mask intrinsics undefined (the run hung). **So the loss
was shown with a test-only divergence on lavapipe, not on any production launch.** A host model
(random and exhaustive 8-lane populations) agrees.

**Fix (f9a2501):** the leader is the lowest kept lane among the lanes that run the call (ballot
form up to 32 lanes, scans over active lanes wider); one `fetch_add` per plane when its kept
tops share a group, one per kept lane when they straddle groups, as before; the number of plane
operations is unchanged. A per-batch account (tops written minus records reserved, and the same
for record indices mod 2^32) is summed per work group and checked by the host after every batch
and partition re-run (`ensure_appended`): a mismatch fails the field.

| field (RTX 3080, 260 W, interleaved, card at idle temperature before each run, counts identical) | main (median) | fix | change |
|---|---|---|---|
| b62 1e17 (3 and 4 spill-free rounds) | 67.27 s | 67.42 s | +0.23 % |
| b64 1e17 (5 rounds) | 138.03 s | 138.49 s | +0.33 % |

Exactness on the fix: the partly-filled-plane test with lane 0 out (552 runs per compiler on
lavapipe, 230 on CUDA), every CUDA and lavapipe test of `cubecl_join`, dense compares against
the CPU join at b60 1e16, b62 1e17, b64 1e17, 248 host tests, fmt and clippy under 1.100.0; the
generated CUDA and WGSL of every kernel except `top_fd_kernel` identical to main's. Not run: a
64-lane device, Metal, HIP.

**Integration of the four open PRs:** main + #251 + #255 + #256 + #259 (and the same plus the
fix) pass lint, host tests (254 / 255), every CUDA test, lavapipe with both compilers and the
dense compares with the same counts. Conflicts: the changelog (keep all lines in PR order);
`walk_pf_lean` (#255's shift-form digits, then #259's count-or-compare test unchanged); and
between #251 and the fix the `ran` array (#251's test-only smallest-take word is hard-coded at
`ran[STAGES_U32 + 3]` and must move behind the fix's two account words).

## CPU2.1 A skip walk for the CPU join's top certificates (2026-11-14 05:46–08:57 UTC, agent, ivory, one thread; `CPU2/RESULTS.md`, `CPU2/raw/` (`profile_*.txt`, `ab*-runs.txt`, `ab*-summary.txt`, test logs, `rayon-runs.txt`, `bitreversed-order.txt`); fork branches `exp/cpu-top-skip` (two commits) and `exp/cpu-top-skip-squashed` e0bf513 (one commit on main 41b4b40; 600 changed lines in `cpu_join.rs`, `cpu_top_fd.rs`, `client/src/main.rs`))

**Profile of the CPU join today** (main, three fields per base, three slices each, three
partitions per slice): the top phase is 45 % of a b62 1e17 partition (40–51 %), 39 % at b60 1e16
(31–54 %), 19 % at b64 1e17 (17–22 %); at b62: certificates 21 %, stepping 16 %, seeding 9 %.

**The rule:** when a certificate fails on a repeated digit at two certified positions, every
later block in which neither position's digit can have changed fails too; the number of
partitions that covers is bounded from below in f64 with margins, and each worker thread keeps
a "next partition to certify" per prefix, used only when its next partition closely follows the
previous one in the same join. Tests: 1.4e8 blocks inside computed runs re-certified (all fail);
passing tops identical to the unskipped walk on 268 small-base field shapes exhaustively and on
real fields at b57–b64; counts identical in every timed run.

| shape (one thread, `nice -n 19`, 6 interleaved rounds) | old (median) | new | gain |
|---|---|---|---|
| b60 1e16, 32 partitions | 49.36 s | 43.62 s | ×1.132 (1.118–1.139) |
| b62 1e17 slice 0, 32 partitions | 46.08 s | 40.41 s | ×1.140 (1.130–1.145) |
| b64 1e17 slice 0, 12 partitions | 59.77 s | 59.22 s | ×1.009 (1.002–1.015) |

At b64 the skip leaves 0.415 of the certificates but stepping and seeding dominate what is left.
The client needed one scratch per worker thread (rayon's `map_init` gives runs of 1–5 partitions
at 8 threads); NiceMark's bit-reversed partition order shows no gain and no loss (×1.02). Not
timed: more than two threads. **Verdict: clears the bar at b60 and b62, nothing at b64. A ready
branch, held: no PR slot, and CPU clients do none of the search today. Independent review
started (`CPU2/REVIEW-BRIEF.md`) because a wrong skip would lose candidates.**

## N21.3 The population-count prefilter test as PR #259: review and device verification (2026-11-13 16:22–17:41 UTC; `N21/PR/` (`PR-BODY.md`, `NOTES.md`, `REVIEW.md` with `review-pfcheck.rs`, `VERIFY.md`, `raw-verify/`); fork `pr/join-prefilter-popcount-spirv` 3b77370 = 760512c (the change, on main 41b4b40) + c53d99f (the compare form's statements in main's order) + the changelog number; box 60522271, RTX 3080 at 280 W, 0.81 h, ~$0.08)

Scope decision (director): the count form is compiled only on `wgpu<spirv>` (Vulkan through
CubeCL's SPIR-V compiler), the one configuration it was measured to help; CUDA, Metal and WGSL
keep the compares. Review: the reviewer's own exhaustive check (every digit 4-tuple below 64
against every relevant mask setting, 768,289,920 cases) finds 0 mismatches against the old form
as the kernel computes it. Verification on the box, branch c53d99f against main 41b4b40:

| what | result |
|---|---|
| CUDA source of every production kernel at b62 1e17 and b64 1e17, normalised | identical to main's |
| WGSL for naga (CI's lint dump, 14 shaders) | identical |
| SPIR-V kernels on lavapipe | only the join kernel differs (2,020 → 1,983 instructions, `OpBitCount` 2 → 6) |
| CUDA device tests of `cubecl_join` | 7 of 7 pass |
| CUDA dense compare against the CPU join, 8 partitions each | equal at b62 1e17 and b64 1e17 |
| lavapipe, SPIR-V compiler (count form) and naga (compares) | 8 of 8 pass each (5 run, 3 are opt-in) |
| one interleaved check on CUDA, b62 1e17 | branch 65.03 s, main 64.99 and 64.88 s, counts identical |

Lint and host tests pass under Rust 1.100.0 (main's new pin). PR #259 opened 17:41 UTC with the
RX 9070 XT numbers of N21.2 (×1.037 at b62 in three rounds, ×1.080 at b64 in one), stated as
measured on an experiment build on main + #255 + #256.

## N21.2 / CKF.3 Third demoux window: #251's device tests on the card, #251 against main, the walk-loop variants (2026-11-13 15:40–16:21 UTC, director, 41 of 60 minutes granted; `N21/WINDOW-RESULTS.md`, `N21/raw/demoux/` (55 files: `go.out`, `tests_C.log`, per-run `.log` and `.gpu`), driver `N21/raw/scripts/window13/go13.sh`; binaries C = fork `pr/check-d` 1f41d64, M = main a7a59c1, E = fork `exp/n21-walk-loop` 2d3e10d)

RX 9070 XT (RADV, wgpu with CubeCL's SPIR-V compiler), production client stopped by the user;
every timed run 99–100 % busy, 302–305 W, 3.00–3.17 GHz, counts identical per field.

**#251's fixed head on the card: all 10 wgpu device tests of `cubecl_join` pass**, including the
check counts (1,168,717 list entries over 22 shapes) and the partly-filled-plane test, which on
this card's 64-lane planes ran takes of 36 and 48 lanes in the scan form with every entry
checked once. **The path that had never run on 64-lane hardware has now run there.**

| #251 fixed head against main | main (s) | head (s) | gain |
|---|---|---|---|
| b62 1e17 (2 rounds) | 72.74, 73.33 | 64.94, 65.09 | ×1.120, ×1.127 |
| b60 1e16 (2 rounds) | 13.05, 12.99 | 11.56, 11.60 | ×1.129, ×1.120 |
| b64 1e17 (1 round) | 136.51 | 120.31 | ×1.135 |

| walk-loop variants (base = main + #255 + #256) | base (s) | population-count test | + cheaper pop |
|---|---|---|---|
| b62 1e17, 3 rotated rounds | 68.34, 68.58, 68.71 | ×1.040, ×1.034, ×1.037 → **×1.037** | ×1.045, ×1.049, ×1.050 → **×1.049** |
| b64 1e17 | 117.80, 117.66 | **×1.080** (1 round) | **×1.100, ×1.097** (2 rounds) |

The instruction-count estimate (×1.03–1.05) held at b62 and was beaten at b64, where the
prefilter is a larger share and #255 has already removed its multiplies. #255 and #256 together
are ×1.07 at b62 and ×1.16 at b64 on this card (main against the variants' base, same hour;
derived). **Verdicts: #251 verified on the card; the population-count test is a PR candidate
(×1.08 at the base that matters, ×1.037 at b62); the cheaper pop adds ×1.01–1.02 and stays a
ready follow-up.** Window closed at 16:21 UTC: workspace removed, watchdog stopped by PID,
nothing of mine left, one ntfy sent.

## CKF.2 The review's fixes on PR #251 (2026-11-13 12:55–13:25 UTC, agent; `CKF/REVIEW.md` (the independent review, with `CKF/review-model/`), `CKF/RESULTS.md` §7, `CKF/PR-BODY.md`, `CKF/raw/box2/`; fork `pr/check-d` 1f41d64 on 8d11e0b; box 60499346, RTX 3080, 0.54 h, ~$0.06; an earlier box, 60478814, was lost to the 09:47 outage)

Review of 8d11e0b: the hand-out is complete and non-overlapping by construction in both forms
(the reviewer's own random and exhaustive models: 0 wrong hand-outs; 9,244 deliberately broken
runs, none passes the host's count and index-sum check); the plane operations mean what the fix
needs on CUDA, WGSL, SPIR-V and Metal (read in CubeCL 0.10's sources); `ensure_checked` runs on
every production path and a mismatch is a hard error. Findings fixed in 1f41d64, tests only:
a host unit test of the comparison (`check_complete`: exact, one skipped, one doubled for
another, the sum's wrap mod 2^32, the largest list), a device test mode in which entry 1 is
checked as entry 0 (count right, sum one short: "…sum to 9590 (mod 2^32), not 9591"), and the
partly-filled test now records its smallest take (4 lanes at 100 threads, 16 at 48, 32 at 256 on
CUDA; **lavapipe also shows takes of 4 lanes**, so it does run partly filled subgroups; why the
old kernel still checked every entry there was not investigated). The production kernels of
1f41d64 and 8d11e0b are identical after normalising CubeCL's variable numbering (CUDA sources of
five kernels; all 14 WGSL shaders), so no speed runs were repeated. CUDA and lavapipe (both
compilers) device tests, 253 host tests, fmt and clippy pass. PR body replaced with
`CKF/PR-BODY.md` plus a paragraph on what a wgpu device should expect.

## N21.1 A leaner walk and prefilter loop: exact variants, CUDA A/B, ACO instruction counts (2026-11-13 05:50–09:47 UTC, agent, cut off by a harness outage while finishing the write-up; `N21/RESULTS.md`, `N21/WINDOW-PLAN.md`, `N21/raw/` (`ab_table.txt`, `aco_table.txt`, box logs, dumps, `scripts/window/`); fork branches `exp/n21-walk-loop` (switches, base = main a7a59c1 + #255 + #256), candidates `exp/n21-popcount-test-wgpu` 3a4899e and `exp/n21-ffs-pop` be24d18, each one commit on main; box 60456234, RTX 3080 at 180 W, 7 h TTL, ~$0.84)

The loop today (b62): on ACO for GFX1201 a walk round in which no lane passes is 59 instructions
(52 ALU: 35 vector, 14 scalar, 3 shared-memory), plus 23 when a lane passes; on NVIDIA 42 SASS.
Variants as comptime switches of one binary; the two that matter: **M**, the four-digit test as
one population count (`popcount(A & !seen) == 4`, a set identity: the four digits are distinct
and unseen iff that count is 4), and **P**, popping the next set bit without `trailing_zeros`'
zero case.

| | ACO, ALU instructions per no-pass round | RTX 3080 b62 1e17 (4 rounds) | b60 1e16 (3) | b64 1e17 (3) |
|---|---|---|---|---|
| today | 52 | 78.7 s | 14.75 s | 160.4 s |
| M | 44 (−8) | | | |
| P + M | 42 (−10) | ×0.989 | ×0.987 | ×0.981 |
| P + M + B (b64 bit field) | 40 at b64 (−12) | ×0.989 | ×0.987 | ×0.980 |
| P + M + D (append in a second walk) | 44, the 16-instruction pass path moved out | ×0.967 | ×0.980 | ×0.951 |

Exact: an argument for every input per variant, host tests (exhaustive four-tuples over bases
10–64 for M), dense compares against the CPU join on CUDA at b60 1e16, b62 1e17 and b64 1e17,
lavapipe 8/8 with both compilers, for every switch and for both candidate binaries. **On NVIDIA
nothing gains (M costs four more SASS instructions per round there), so the candidate applies M on
every runtime but CUDA and leaves CUDA's kernel unchanged.** For the RX 9070 XT only counts
exist: at N17's price of about half a percent of a field per instruction, P + M is ×1.03–1.05
[estimate]. **Kill criterion: not met on the count (−10 ≥ 8), so the lead stays open, but its
gain on the one card it is for is unmeasured.** A 30-minute window plan with tested scripts is
in `N21/WINDOW-PLAN.md`.

## CKF.1 PR #251's check kernel on partly filled planes: reproduced, fixed, verified (2026-11-13 06:32–09:15 UTC, agent; `CKF/RESULTS.md`, `CKF/PR-BODY-DELTA.md`, `CKF/raw/` (`repro/make_repro.py`, `0001-fix.patch`, box logs and outputs); fork `pr/check-d` 8d11e0b on bc9d87c; box 60460107, RTX 3080 at 180 W, 2.89 h, ~$0.31)

**Reproduced on a real device:** bc9d87c's check kernel launched in count mode on one CUDA
block of 100 threads (a 4-lane last warp) or 48 threads (a 16-lane warp) skips entries: 34,296 of
218,772 over seven shapes, with the work counter ending where full warps would put it. Not
reproducible on lavapipe (its last subgroup runs all 8 lanes). Production's 256-thread blocks are
full on CUDA; this is what a partly filled Vulkan subgroup would do. (CubeCL 0.10's CUDA and HIP
backends compute the lane as position mod `PLANE_DIM`, so blocks that are not a multiple of 32
get wrong lanes after the first block: an upstream CubeCL defect, test-only for us.)

**Fix (8d11e0b):** `take_entries` lets the lanes that run a take decide it: with planes of at
most 32 lanes one ballot gives the lanes, their count, each lane's rank and the leader (lowest
set bit), whose `fetch_add(count)` reaches the others by a shuffle from its lane; with wider
planes an exclusive scan and a sum over the active lanes. Nothing depends on `PLANE_DIM` or on
lane 0. The kernel also counts the entries it checked and sums their indices; the host
(`ensure_checked`) compares both with the list after every check launch and fails the field on
a mismatch (an error, not a retry; nothing is submitted).

| field (RTX 3080, 180 W, interleaved, cooled before each run, counts identical) | PR head bc9d87c | fix 8d11e0b | fix against PR head | fix against main a7a59c1 |
|---|---|---|---|---|
| b62 1e17 | 71.97 s | 72.03 s | +0.09 % | ×1.084 |
| b60 1e16 (two fields, seconds per field) | 9.197 | 9.216 | +0.21 % | ×1.094 |
| b64 1e17 | 149.73 | 149.39 | −0.23 % | ×1.060 |

Exactness on the fix: the partly-filled regression test (84 runs on CUDA; both forms at 100, 48
and 256 threads on lavapipe with WGSL and SPIR-V); the check's count, gated and probe modes
(1,168,717 list entries, 22 shapes) on CUDA in ballot and forced scan form and on lavapipe; dense
compares against the CPU join at b60 1e16, b62 1e17, b64 1e17; the full wgpu suite on lavapipe
with both compilers; a skip-one-entry test mode makes `run_field` fail with "checked 138 of the
139 survivors". **Not run on real hardware: the scan form on 64-lane planes (the RX 9070 XT's
path), Metal, HIP.** The check kernel's registers rose from 39 to 47 at b62/b64 with no effect
at field level. CI on 8d11e0b: 24 pass, 1 fail (the Windows job lost its network connection
while installing the toolchain; tests and the GPU build of the same job passed).

**Same assumption on main, not fixed here:** `top_slot` (the top kernels' append) broadcasts
lane 0's group and lets only lane 0 take the atomic (verified by reading). A Vulkan plane
without an active lane 0 would overwrite tops. 256-thread groups give full planes on every
device in production today.

## N6.1 Can the join test fewer top certificates? Exact counts on the CPU (2026-11-13 05:50–06:47 UTC, agent, ivory, two threads; `N6/RESULTS.md`, `N6/raw/` (`main_b{60,62,64}_s{1,2}.log`, `summary_b*.txt`, `analyze.py`, `run_main.sh`); fork branch `exp/n6-top-counts` 21908a7 (`common/src/overlap_join/n6.rs`, `common/examples/n6_top_counts.rs`))

Sample per base: two seeds × 48 field locations stratified over the base × 25 random b^6 blocks,
every layer prefix at all b² partitions: 1.56e8 (b60 1e16), 1.25e8 (b62 1e17), 1.31e8 (b64 1e17)
pair tests; seeds agree within 0.003 on every ratio; the study's certificate matches
`Base::cert` on 5.9e7 checks; no scheme rejected a passing pair in 4.1e8.

A test certifies 16–19 leading digits of n² and n³, of which the parent prefix already fixed
12–15; the pair adds about two per power and fails when one repeats (98 % of failures; 85–87 %
against a parent digit). Failures run along the partition axis (P(fail | previous fails) 0.94–0.96;
64–70 % of failing pairs sit in runs of ≥ 128 partitions) and are independent across sibling
prefixes.

| b60 / b62 / b64 | |
|---|---|
| pairs passing | 0.349 / 0.325 / 0.312 |
| fewest tests any exact test-and-skip order needs, ÷ today's | 0.373 / 0.357 / 0.351 |
| best GPU-shaped scheme (pass 1 certifies groups of 16–32 partitions per prefix, then today's kernel on what is left), cost ÷ today's, group test priced at 1.8 steps | 0.52–0.55 / 0.58–0.60 / 0.57–0.59 |
| the same with a passing pair's append priced at 0.2 of a test | — / 0.61–0.63 / 0.59–0.61 |
| a skip walk per thread (CPU-shaped) | 0.40 / 0.42 / 0.43 |
| a skip walk with 32 lanes in lockstep | 0.98 / 1.14 / 1.18 |

**At field level (derived, GPU prices assumed): ≈ ×1.09 at b62 and b60 (top share 22 % and
18.5 %), ≈ ×1.035 at b64 (top share 8.4 % since #254).** The kill line (≥ 40 % of the top work
removed at b62 and b64) is met only at the most favourable pricing, by 0–3 points. **Verdict:
parked, not prototyped**: the hoped-for ÷5 does not exist (the floor is ÷2.8), a two-kernel
restructuring buys ×1.09 for the two months of base 62 and ×1.035 for base 64.

## T2.4 Soundness audit of the GPU join: can a candidate be lost unnoticed? (2026-11-13 05:50–06:25 UTC, agent, no device; `T2/SOUNDNESS.md`, `T2/models/` (`stage_model.py`, `plane_models.py`, `prefilter_chain.py`, two audit test patches and their outputs); main a7a59c1 and fork heads `pr/check-d` bc9d87c, `pr/join-prefilter-shift-pow2` 42d2afd, `pr/join-survivor-stage-512` 0f6794a)

**No path found that loses a candidate in production today.** Rests on: a full read of kernels and
host against five headings (buffers and counters, concurrency, rejecting filters, device
failures, bookkeeping); a model of the survivor stage and flush (0 of 900 random schedules lose
or duplicate on main's protocol and on the 512-entry stage; the pre-#222 protocol fails 36 of
900, so the model sees that class); a big-integer mirror of the per-pair digit chain at the
production shape (0 mismatches on 42,712 n over the 20 bases 40–64 with a band; three single
mutations give 404–4,646); two audit tests (every 32-bit index product at the planner's largest
layouts < 2^30; 1,400 pruned top-layer prefixes have no certified child among 5.3e6); the
repository's certificate and CPU-join reference tests on real b58–64 tops and b42–64 fields.

Gaps, by severity:

| # | where | what | status |
|---|---|---|---|
| 1 | production, by design | a device that runs every work group but computes wrongly is not detected (`ensure_ran` sees only groups that did not finish); #222 and the Metal miscompile were of this kind. The join's two counters are exact functions of the field, so a known-answer check is cheap: NiceMark records them on every box and compares them with nothing | a proposal for the user (a feature, not built) |
| 2 | **`pr/check-d` (PR #251) only** | **the new check kernel hands out `PLANE_DIM` entries per plane leader and lane i takes entry `cur + i`: a plane with fewer active lanes skips entries silently** (model: 31 of 32 lanes leaves 3,125 of 100,000 unchecked). Full planes are guaranteed on CUDA and Metal, not on Vulkan (wgpu does not request them) | **confirmed by my own reading of the kernel; fix in progress (CKF)** |
| 3 | theoretical | the survivor-list overflow detector is a 32-bit counter that could wrap at ≥ 2^32 prefilter survivors in one batch (measured densities are 30–100× below) | hardening idea |
| 4 | loud, not silent | the top stage's grid can reach 65,536 groups in x at a 4 GiB wgpu budget if every prefix of a slice were certified | note |
| 5 | note | `top_slot`'s ballot form trusts the runtime's reported plane width; CI no longer exercises the scan form that 64-lane devices use | a test idea |

Not checkable without a device: that each kernel computes what its model computes on CUDA,
RDNA4 and the M4; the scan form of `top_slot`; whether any fleet device runs partial planes.

## T2.5 Realized gain of main a7a59c1 on demoux, from telemetry (2026-11-13, director, public API; `../2026-11-fresh-eyes/realized_1113.py`, `recent_niceonly_1113.json`, `demoux_launches_1112.json`)

`uv run --with numpy python realized_1113.py`. demoux, b60 1e16, two fields in flight: 8,232
non-empty fields on c0c357a (11-11 03:37 → 11-12 15:12 UTC) and 3,283 on a7a59c1 (from 11-12
17:20 UTC). Within a plan group (same launch count) join seconds against survivors is a line;
the builds' lines are compared at the group's pooled median survivors, bootstrap 95 %.

| launches per field | fields old / new (clean hours) | seconds old → new | gain |
|---|---|---|---|
| 1,350 | 3,831 / 808 | 12.87 → 12.52 | ×1.028 [1.025, 1.030] |
| 1,120 | 1,017 / 200 | 12.69 → 12.30 | ×1.031 [1.027, 1.035] |
| 1,170 | 781 / 168 | 12.90 → 12.48 | ×1.034 [1.030, 1.038] |
| 1,080 | 287 / 77 | 9.92 → 9.67 | ×1.026 [1.015, 1.037] |

**×1.029 weighted** (#250 on this card; #252–#254 do not act at b60 on a GPU). "Clean hours" = an
hour whose 1,350-launch fields have a 90th percentile of join seconds under 15 s: in seven hours
of 11-12 (local 15–18 and 20–22) the card was shared with another load and the join seconds
doubled (22–25 s), which makes the unfiltered comparison read ×0.843. **Rule for the future:
filter shared-card hours before reading a realized gain.**

## T2.3 Sampled exact re-verification of nice-only submissions by device and build, bases 58 and 60 (2026-11-12 15:41–21:46 UTC, agent; `T2/AUDIT.md`, `T2/raw/` (census, `sample.json`, queues, `compare.txt`, `cell_table.md`, `dup_rule.txt`, `pre222_only.txt`, `proof_hosts_block.txt`, `box/`, `box2/`); boxes 60374124 (went offline at 18:03, 2.68 h) and 60389955 (3.46 h), RTX 3080, ~$0.71 together)

Mechanism: the real client of each build, compiled from its commit, against a local stub of the
claim and submit endpoints; the production hosts mapped to 127.0.0.1 on each box and proven
unreachable before any client ran; the census from ivory by bounded id ranges. Validation: current
main reproduces demoux's counters exactly on 59/59 b58 and 149/149 b60 fields and the M4's on 20/20.

Census: b58 93,573 fields, all searched; b60 162,076 fields, 90.2 % searched; 11,473 submissions
disqualified (the M4 set). Counters (`survivors`, `checked`) are exact and repeatable only from
#236 on; older builds move stage overruns from one counter to the other run by run, so there
the audit compares the conserved combination survivors + checked ÷ (1 − pass rate) with a
tolerance that grows with the overrun (for 8bd154b / 9bde4a8 against main's exact counts; a loss
below ≈ 1e-5 of a heavily overrun field could hide there).

**Re-runs: 0 mismatches in 1,662 comparisons** (1,100 same old build, 328 exact, 234 against
main's counts). 95 % upper bound on a cell's per-field disagreement rate:

| | ≤ 2.1 % | ≤ 5.1 % | 9.5–14 % | weaker or not checked |
|---|---|---|---|---|
| b58, share of the range | 74.1 % | 22.0 % | 0.85 % (to 45 %) | 0.8 % (3 fields); M4 0.27 % not run; **Anvil 2.03 %: no telemetry, not checkable** |
| b60, share of the range | 46.0 % | 32.6 % | 14.3 % | 5.5 %; 9.8 % of the base not searched yet |

**Census finding (not a random sample): 3 of 11,087 same-build pairs of pre-#236 submissions
break the conserved quantity, all v3.4.6 (9a4f740) at b60, all with surplus checks:** field
206943130, GTX 1080, +5.4 M checks (3.3e-5 of the field's survivors); 206950836, TITAN Xp,
+2.35 M (2.8e-5); 206956667, RX 9070 XT, +9,990 (1.3e-6; that run also retried 16 partitions).
In each pair the other submission agrees with a same-build re-run on the 3080 (director's own
API lookups confirm the three pairs). Reading: the #222 flush race fired outside Apple at about
1.4e-4 per submission. Per #222 an event can also overwrite list entries, which counts cannot
show. **Fields with only a pre-#222 submission: 89,158 at b58 (95.3 % of the range) and 64,590
at b60 (39.9 %).** If an event loses as many entries as it duplicates, the expected lost share
of those bases' candidates is ≈ 1.4e-4 × 3e-5 ≈ 4e-9 [derived, assumption stated]. Nothing was
changed, re-queued or reported anywhere.

## PRP.1 The 512-entry survivor stage and the base-64 prefilter shifts as branches on main: exactness and CUDA regression (2026-11-12 17:13–20:45 UTC, agent; `PRP/RESULTS.md`, `PRP/PR-BODY-stage.md`, `PRP/PR-BODY-shift.md`, `PRP/raw/` (`ab_table.txt`, `nm_table.txt`, box logs, scripts); fork branches `pr/join-survivor-stage-512` 0d84d0a and `pr/join-prefilter-shift-pow2` 93a7ef6, each one commit on main a7a59c1; box 60383994, RTX 3080 at 320 W, 3.53 h, ~$0.42)

M = main, S = stage 512 / flush 256, F = shift form. Four rotated rounds, counts identical in
every run, each run started at ≤ 60 °C (the card throttles when runs are back to back: the first
A/B attempt was discarded for that), register variant recorded per process.

| field (main ÷ branch, median of 4) | S | F |
|---|---|---|
| b62 1e17 | ×1.000 | ×0.997 (same code as main: A/A) |
| b60 1e16 | ×0.998 | ×1.000 (A/A) |
| b64 1e17 (card in thermal slowdown on both sides) | ×0.997 | **×1.019** (1.012, 1.013, 1.024, 1.036) |
| b64 1e16 × 2 | ×1.000 | **×1.016** (1.016, 1.011, 1.017, 1.020) |
| NiceMark score, 4 rounds | ×0.999 (lowest scenario round 0.987) | ×1.002 (no b64 scenario: A/A) |

Exactness: dense compares against the CPU join pass (S: b60 1e16 48 partitions, b62 1e17 32; F:
b64 1e16 48, b64 1e17 32); CUDA device suite 7/7 for both (F's first run failed on a buffer
allocation while other jobs held the card's memory; alone 7/7); lavapipe 8/8 with naga and with
SPIR-V for S, F and M; host tests 247 / 248. **Stage overflow:** a throwaway build with a 16-entry
stage sends 124 M of 135 M checked pairs (b60) down the direct path and the counts still equal
the CPU join's; at 512 / 256 the direct path takes 93,908 pairs at b60, 0 at b62, 79 at b64.
**F at other bases:** the canonicalised CUDA source of all kernels at b58, b60, b62 is identical
to main's; the b64 join kernel differs in 12 lines (the multiplies became shifts). The CPU
join's prefilter was left alone (its base is a runtime value; a shift form there was 3.5 %
slower).

## N17.1 The RX 9070 XT at its operating point: profile by doubling, the tunings in three rounds, base 64 (2026-11-12 15:28–17:09 UTC, director, second demoux window, 101 of 120 minutes; `N16/raw/demoux/` (193 files), `N16/raw/demoux_analysis.txt`, scripts `N16/raw/scripts/go_dir1.sh`, `go_dir2.sh`, `go_dir3.sh`, `chain_geox.sh`, `modes.sh`; binaries: N16 = fork `exp/n16-join-base` 32e9e19, P = `exp/n20-mul-probe` f049415, M = main a7a59c1, D = `exp/n14-wgpu-dense-plan-v2` bb58878)

`python3 -I N16/raw/scripts/analyze.py N16/raw/demoux 3150 300`. Production's build path
(`--features gpu,cubecl-spirv`), production client stopped by the user, every run unprofiled,
99–100 % busy at 303–304 W and 3.03–3.19 GHz, counts exact in every exact mode. Base spread
within a chain 0.0–0.8 % (1.2 % in the first chain, whose first run was the fastest).

**Profile by doubling** (a part executed twice at full load; share = Δ seconds ÷ base):

| part | 9070 XT b62 1e17 (73.5 s) | RTX 3080 b62 | 9070 XT b64 1e17 (151.6 s) | RTX 3080 b64 |
|---|---|---|---|---|
| prefilter | **25.9 %** (0.68 ps per pair) | 15.9 % (0.35) | **30.4 %** | 20.8 % |
| check kernel (main's of 11-09) | **16.3 %** | 11.3 % | **17.5 %** | 11.0 % |
| AND | 11.1 % | 14.6 % | 10.5 % | 14.6 % |
| walk rounds | 6.1 % | 9.1 % | 8.0 % | 12.6 % |
| transposed copy | 0.9 % | 4.6 % | | |
| batch loads, entry-wave loads, barriers | −0.2 %, −0.5 %, +0.1 % | 1.4 %, 0.0 %, 0.1 % | | |

Removal, unprofiled, b60 1e16 (13.10 s; clocks 2.8–3.2 GHz in these 4–7 s runs): prefilter 27.6 %,
stage + check 19.3 %, AND 11.6 %, walk 5.6 %, entry waves and below 5.3 %; dispatch only 4.0 s.
The per-phase profile mode costs +17.9 % here (86 % busy). **Verdict: NVIDIA's profile with a
prefilter and a check that cost ≈ 2× per pair; the fixed per-batch parts are ≈ 1 %. N16's
premise is dead for good.**

**Tunings, three rotated rounds each** (tree E + switches; ÷ the round's own base):

| variant | b62 1e17 | b60 1e16 | b64 1e17 (1 round) | RTX 3080 (N16.1) |
|---|---|---|---|---|
| survivor stage 512 entries, flush at 256 (`sc512`) | ×1.055, 1.056, 1.060 → **×1.056** | ×1.057, 1.056, 1.056 → **×1.056** | ×1.062 (stage 256) | ×0.999 b60, ×0.994 b62 |
| denser plan (`vram`) | ×1.032, 1.035, 1.036 → ×1.035 | ×1.045, 1.047, 1.038 → ×1.045 | no-op on tree E (FD off there) | already on |
| stage 512 + `TOP_CAP` 128 + denser plan (`all3`) | ×1.111, 1.114, 1.123 → **×1.114** | ×1.134, 1.139, 1.139 → **×1.139** | ×1.080 (= stage + `TOP_CAP`) | — |

One-round screen at b60 (base 13.08 s): stage 512 / 256 / 128 ×1.063 / 1.048 / 1.054; `TOP_CAP`
128 ×1.054; stage 512 + `TOP_CAP` 128 ×1.085; stage 256 + denser plan ×1.103; work group 128 /
64 threads ×0.83 / ×0.64 (H2 dead); seconds = 11.83 + 0.87 ms × batches (1, 2, 4 partitions per
launch). b64 1e17 screen (base 150.33 s): stage 256 ×1.062, stage 512 + `TOP_CAP` 128 ×1.075.
**After the stage, `TOP_CAP` 128 adds only ×1.01–1.03 and needs a per-device value.**

**The denser plan behind its device rule, on today's main** (M a7a59c1 against D bb58878, one
round): the rule engages on RADV (625 against 1,350 batches at b60, 4,458 against 7,959 at b62,
3,944 against 7,076 at b64); **b60 ×1.053, b62 ×1.045, b64 ×1.004** (135.23 → 134.70 s).

**Base 64, the prefilter's two digits as shifts** (`pfsh`, exact identity at b = 2^6, binary P):
150.16 → 142.90 s, **×1.051**, counts identical (one round). Today's main at b64 1e17: 135.23 s
(tree E without #254: 150.2–151.6 s, so #254 is ×1.11–1.12 on this card).

**Multiply probe** (binary P, b62, one round; four extra operations per walked pair): additions
+5.7 %, two 32-bit low + two 32-bit high multiplies +6.9 %, the same with 24-bit-masked operands
+4.3 % (the driver's dump shows the two low multiplies became `v_mul_u32_u24`, the high ones stayed
32-bit). **Not resolved: the variants differ by less than a single round's layout noise; what the
probe does show is that eight or nine extra instructions in the walk loop cost 4–7 % of a
field on this card.**

## N16.1 A harness for the 9070 XT's profile; the RTX 3080 by doubling and by removal; what ACO generates (2026-11-12, agent; `N16/RESULTS.md`, `N16/WINDOW-PLAN.md`, `N16/raw/` (`sorted/` = the tables' logs, `scripts/`, `taskA.txt`, `taskC.txt`, `box/spv_dumps.tar.zst`); fork branches `exp/n16-join-base` 32e9e19 (from 44eee52) and `exp/n14-wgpu-dense-plan` 464be8b (on main 5b1d627); box 60317813, RTX 3080 at 280 W on a Ryzen 5 5600X, 3.59 h, $0.47; box 60315324 unusable, 0.44 h, $0.05)

`python3 -I N16/raw/scripts/analyze.py N16/raw/sorted` prints every row with clock, power, busy % and
counts (re-run by the director: tables reproduce; every row at 1,740–1,935 MHz and 277–280 W).

**The 9070 XT's profile from N13's logs, bounded** (`N16/raw/scripts/taskA.py`; J = differences of each
mode's own join timer, JS = the same scaled by the run's top phase; the truth lies between), b62 1e17:
base 7–13 % (0.20–0.38 ps per pair; 3080 0.26), AND 12–19 %, walk 5–6 %, **prefilter 15–28 %**,
survivor path 21–35 %, check 17 %, top 22 %. (N13.2's single figures are the JS end of each range.)

**RTX 3080 at 280 W, CUDA, unprofiled; "doubling" = the part executed twice at full load, counts
exact, cost = Δ seconds ÷ base** (b62 1e17 at 0.45, base 61.97 s, 2 rounds; b64 1e17 at 0.55, base
143.12 s, 2 rounds):

| part | b62 1e17 | b64 1e17 | by removal at b62 (unprofiled) | L51 (180 W, removal) |
|---|---|---|---|---|
| prefilter | 15.9 % | 20.8 % | walk + prefilter 28.4 % | 19.8 % |
| AND | 14.6 % | 14.6 % | 16.6 % | 14.9 % |
| check kernel | 11.3 % | 11.0 % | stage + check 12.2 % | 12.0 % |
| walk rounds | 9.1 % | 12.6 % | (above) | 9.2 % |
| transposed copy | 4.6 % | | | (base 10.9 %) |
| batch loads / entry-wave loads (cached second read: lower bounds) | 1.4 % / 0.0 % | | | |
| barriers (6 more per item and batch) | 0.1 % | | | |

The two instruments agree within 1–3 points, and with L51. **On the 3080 the clock stays or rises
in the light modes** (z 1,740, a 1,725, p 1,800 MHz against c's 1,740–1,770, all at 279 W): L51's
and B64's NVIDIA shares stand. Profiled mode costs +3.2 % there and keeps its clock.

**Launches on CUDA** (`NICE_EXP_HOSTACC`, `NICE_EXP_SLOTS`): seconds = 11.03 + 0.78 ms × batches at
b60 1e16 (7 runs), 59.6 + 0.84 ms × batches at b62 1e17 (4 runs). Every launch fence completes
inside `client.sync()` (0 of 2,615 pending); host time in `launch_batch` 0.92–1.00 ms per batch at
b62 (2.4–2.6 s, ≈ 4 % of the field, nearly all in CubeCL's flush), 0.2 ms at b60 and b64. Whether
that is GPU idle time is the agent's reading, not measured (busy reads 99 % at b62, 92 % at one
partition per launch): **estimate only, ≤ ×1.04 on NVIDIA.**

**Geometry and occupancy on CUDA (exact, b60 1e16 / b62 1e17):** `TOP_CAP` 128 +3.1–4.3 % / +3.5 %
slower; survivor stage 512 or 256 entries +0.1 % / +0.6 % (neutral); both +3.2 % / +2.4 %; work
group 128 +9–12 %, 64 +31–38 %; top-append ballot forms within ±1 %.

**What ACO (Mesa 25.2.7, null GFX1201 device, CubeCL's SPIR-V compiled with a small pipeline
program) generates for the join kernel:** wave64; 1,357 instructions; no spills, clamps or emulated
64-bit; 16 barriers (0 at a 64-thread work group); **18.9 KiB of LDS per work group, which caps
occupancy at 12 waves per SIMD (ACO's estimate)**; `TOP_CAP` 128 → 13.8 KiB, 18 waves; stage 512 →
14.8 KiB, 16; stage 256 → 12.8 KiB, 18; `TOP_CAP` 128 + stage 512 → 9.7 KiB, 24. The transposed
AND waits on four LDS loads per digit (latency-bound unless enough waves hide it). A walk round
with the prefilter is ≈ 113 instructions per entry slot (≈ 66 on NVIDIA). The FD top append's
scans already compile to a ballot. **Hypothesis this gives (not measured on the card): `TOP_CAP`
128's ×1.04–1.05 there is occupancy, so a smaller survivor stage, neutral on NVIDIA, should win
there too.**

**Task D** (`exp/n14-wgpu-dense-plan` 464be8b): the denser plan for a wgpu adapter reported as
`DiscreteGpu`, not a software rasterizer by name, budget ≤ 2 GiB. wgpu exposes no memory size, so
this is a class rule: it cannot tell a 4 GB discrete card from a 16 GB one. 11-case unit test,
fmt, clippy, 7 lavapipe device tests pass; on CUDA both binaries take the denser plan (A/A
×0.98–1.02).

**Validation of the harness:** dense compare against the CPU join for every exact mode on CUDA
(b60 1e16: 23 modes; b62 1e17: 15) and on lavapipe with the SPIR-V compiler (22 of 23; `wsync` is
not run by lavapipe and fails its dispatch check instead of miscounting). `go_window.sh` dry-run
twice on the box, the second from a fresh clone at the final head (builds 167 / 168 / 166 s at
`-j 8` on a 5600X); `END_AT` and the stop file tested.

## T2.2 Can production telemetry bound a per-launch cost on demoux? (2026-11-12, director, public API; `../2026-11-fresh-eyes/launch_regression.py`, `demoux_launches_1112.json` (6,567 demoux nice-only fields, 11-11 03:37 → 11-12 00:53 local, build c0c357a, b60 1e16, two fields in flight))

`uv run --with numpy python launch_regression.py`. 8.7 % of the fields are empty (0 launches,
1 ms). Non-empty: median join 12.15 s, 1,170 launches, 9.9 ms per launch; plans of 4, 5, 6, 7, 8
and 16 partitions per launch occur. `run_secs = a + α·survivors + γ·launches`: γ = 2.64 ± 0.04 ms
per launch (R² 0.975), which would be 28 % of a 1,350-launch field; but corr(survivors, launches)
= 0.85, the plan follows the field's density, and the per-group lines are not monotone in the
launch count (at 1.5e11 survivors: 10.9 s at 1,350 launches, 11.1–11.2 s at 1,120–1,170, 9.9 s at
1,080, 8.9 s at 450–720). **Verdict: an upper bound only (≤ 2.6 ms per launch); telemetry cannot
separate launch cost from FD seeds and field shape.** A forced partitions-per-launch sweep on the
card can (in the window harness).

## T4.1 The open PRs after #250's merge (2026-11-12, director; worktree `.worktrees/rebase-1112`, local branches `rb/*` (cherry-picks onto 5b1d627) and `mg/*` (merges))

#250 merged 01:57 UTC as 5b1d627, tree-identical to ee30303. Cherry-picks onto it: #251 and #254
clean, #252 changelog only, #253 clean on the new #252. `git diff` of each result against its
measured tree outside `CHANGELOG.md`: #251 and #254 identical; #252 and #253 differ by exactly
#250's diff (sha1 of the diff text equal to `git diff c0c357a 5b1d627`'s). The force-push of these
was refused, so each PR branch got a merge commit resolved to the cherry-pick's tree (`git diff
--quiet rb/X mg/X`): **#251 a70b012, #252 7269d61, #253 43b448b (merges the new #252), #254
f812a02**; plain pushes; all MERGEABLE; CI re-running at 05:56 UTC.

## N13.2 Correction to N13.1's profile: the ablation runs were at half clock (2026-11-12, director, yesterday's raw logs; `N13/raw/scripts/clock_check.py` → `N13/raw/clock_check.txt`)

`python3 N13/raw/scripts/clock_check.py N13/raw/demoux`. The `.gpu` samples (busy %, clock, power
every 5 s) of the profiled runs on the RX 9070 XT, medians per run, b62 1e17 at 0.45 (b60 1e16
pair in brackets where it differs):

| mode (profiled, `NICE_EXP_JOIN_ABL`) | clock | power | top phase | join phase | join ÷ field, as timed | join rescaled by the run's top phase |
|---|---|---|---|---|---|---|
| c, full | 3226 MHz | 294 W | 18.2 s | 43.3 s | 53.2 % | 53.2 % |
| p, no stage/check | 3141 | 244 | 18.5 | 42.8 | 52.5 % | 51.7 % |
| b, AND + walk | 1932 | 103 | 28.7 | 30.6 | 37.6 % | 23.9 % |
| a, AND only | 1599 | 95 | 30.9 | 25.8 | 31.7 % | 18.7 % |
| z, no AND | 1464 | 89 | 35.2 | 10.7 | 13.2 % | 6.8 % |

The card's clock follows its load: with the join's later parts off it ran at 45–60 % of its
clock and a third of its power, and the unchanged top phase took up to 1.93 × as long. N13.1
read that as a timer leak and took the join's parts from differences of whole-field totals
(a − z, b − a, p − b), i.e. from runs at different clocks. Of the 126 unprofiled runs (the PR
A/Bs and the retune) 125 sat at 99–100 % busy, 3.14–3.2 GHz, 304 W: **those numbers stand.** The
exception is the first naga run at b60 (69 % busy, 2.85 GHz, 212 W), so naga's ×1.00 at b60 is a
lower bound.

Corrected shares of the profiled field (rescaled by each run's top phase; rough, the bucket
phase does not scale by the same factor), b62 1e17 / b60 1e16, next to L51's RTX 3080:

| part | 9070 XT, corrected | bound that needs no rescaling | N13.1 said | RTX 3080 (L51) |
|---|---|---|---|---|
| join base | **6.8 % / 6.3 %** (0.20 / 0.19 ps per pair) | ≤ 13.2 % / 12.9 % (mode z's own join timer at half clock) | ≈ 36 % / 33 % | 10.9 % / 10.5 % (0.26 ps) |
| AND | 11.9 % / 11.5 % (0.35 ps per pair) | base + AND ≤ 31.7 % / 33.3 % | 13 % / 17 % | 14.9 % / 15.0 % |
| walk rounds | 5.2 % / 6.3 % | | 3 % / 0 % | 9.2 % / 9.0 % |
| **prefilter** | **27.8 % / 29.9 %** (≈ 21 ps per AND survivor) | walk + prefilter + stage ≥ 21.5 % / 22.3 % | 1 % / 5 % | 19.8 % / 23.5 % |
| stage | 1.5 % / 1.6 % | | | 1.1 % / 0.9 % |
| check (main's; mode c, full clock) | 17.0 % / 18.8 % (0.207 / 0.199 ns) | measured | same | 12.0 % / 14.4 % |
| top FD (mode c) | 22.4 % / 18.8 % | measured | same | 22.8 % / 18.4 % |

**Verdict: the 9070 XT's profile is NVIDIA's, with a dearer check and prefilter. "The join's
base is a third of the field at 4 × NVIDIA's cost per pair" and "the survivor path is nearly
free here" are both wrong** (N16's premise falls). What stands from N13.1: section A (the open
PRs), section C (the retune), the mode-c phase shares, the per-check and per-top-test costs.
Open: a profile of the join's parts on that card taken at its operating point (work added at
full load instead of removed), and whether L51's and B64's ablation shares on NVIDIA were taken
at full clock (today's agent checks on the box).

## N13.1 The open PRs, the profile and a retune on demoux's RX 9070 XT (2026-11-11 12:45–14:54 UTC, agent on the user's machine with the production client stopped; `N13/RESULTS.md`, `N13/raw/` (`demoux/`, `demoux-final/`, `scripts/`, `analysis.txt`))

Card at its 304 W cap; `cargo test --release -p nice_common --features gpu,cubecl-spirv` (reports
`wgpu<spirv>`, production's path). A/A noise 0.2 %; rounds within a tree 0.3–1.4 %; counts
identical in every run and exact against the CPU join on b60, b62 and b64 fields.

| field (3 interleaved rounds) | main → #250 | #250 → #251 | main → #251 | #250 → #254 |
|---|---|---|---|---|
| b62 1e17 at 0.45 | ×1.041 | ×1.127 | ×1.173 | |
| b62 1e17 at 0.55 (+ the empty 0.35) | ×1.040 | ×1.107 | ×1.150 | |
| b60 1e16 at 0.55 + 0.85 | ×1.031 | ×1.138 | ×1.178 | |
| b64 1e17 at 0.55 | | | | ×1.096 |
| b64 1e16 at 0.55 | | | | ×1.088 |

#250's denser plan is CUDA-only, so here only its cheaper stepped slot counts. Main's seconds per
field: b62 1e17 at 0.45 75.7 s (RTX 3080 at 300 W: 66.7 s); the card runs the join at ≈ 0.87–0.95 ×
that 3080.

**Superseded by N13.2 (2026-11-12): the join's parts below were taken from runs at half clock; the base and
survivor-path rows are wrong.** Shares as first reported (b62 1e17 / b60 1e16; the join's parts from whole-field totals per ablation mode):

| phase | 9070 XT | RTX 3080 (L51) |
|---|---|---|
| top certificates (FD) | 22 % / 19 % | 23 % / 18 % |
| join | 53 % / 56 % | 56 % / 59 % |
| · AND | 13 % / 17 % | 15 % / 15 % |
| · walk rounds + prefilter | 4 % / 5 % | 29 % / 33 % |
| · base (batch loads, transposed copy, entry waves) | ≈ 36 % / ≈ 33 % (derived) | 11 % / 11 % |
| check (main's kernel) | 17 % / 19 % | 12 % / 14 % |

Per operation: survivor path ≈ 0.11–0.15 ps per pair (3080: 0.67), join base ≈ 1.0 ps per pair
(0.26), check 0.20 ns (0.11), FD top test 0.14–0.15 ns (0.158).

Retune (b62 1e17 at 0.45 / b60 1e16 at 0.55):

| change | b62 | b60 | rounds |
|---|---|---|---|
| `TOP_CAP` 128 with `TRANSPOSE_MIN` 96 | ×1.039 | ×1.051 | 3 |
| CUDA's denser plan on this adapter (12 / 9 partitions per launch instead of 7 / 4; fits the 2 GiB budget) | ×1.039 | ×1.044 | 3 |
| both | ×1.078 | ×1.106 | 3 |
| `AND_GROUP` 8 · `TRANSPOSE_MIN` 128 | ×1.022 · ×1.018 | ×1.012 · ×1.022 | 3 |
| naga instead of SPIR-V | ×1.02 | ×1.00 | 2 |
| per-round plane barrier in the walk | ×1.00 | ×1.00 | 2 |
| wide u64 chunks | ×0.94 | ×0.93 | 2 |
| EPT 1 / 3 · `AND_GROUP` 2 · `TRANSPOSE_MIN` 256 · `TOP_CAP` 512 | ×0.96 / ×0.98 · ×0.96 · ×0.95 · ×0.87 | ×0.97 / ×0.98 · ×0.96 · ×0.98 · ×0.89 | 2 |

The driver reports 32–64-lane subgroups, so the one-ballot append is off here (not forced on).
**Conclusion: #251 is the big one on this card (×1.13–1.14; main → #251 ×1.17–1.18); #254 holds
at b64 (×1.09–1.10); two tunings are worth ×1.08–1.11 together; the join's base is a third of the
field here at four times NVIDIA's cost per pair and is the block to open next.**

## B64.1 First profile of base-64 fields; the walk's per-pair floor (2026-11-11, agent; `B64/RESULTS.md`, `B64/raw/` (`analysis.txt`, box logs, scripts); fork branch `exp/b64-profile` 44eee52; box 60171046, RTX 3080 at 300 W)

Base means over 10 fields at 0.05–0.95 of the range (seconds per admissible n; 3–4 rounds):

| | main c0c357a | stack a97e3d7 (#250 + #251) | stack over main |
|---|---|---|---|
| b64 1e17 | 6.46e-15 (82.0 s per field) | 6.16e-15 (78.2 s) | ×1.049 |
| b64 1e16 | 7.47e-15 (9.48 s) | 7.02e-15 (8.91 s) | ×1.064 |
| b62 1e17 (1 round) | 1.47e-14 (48.2 s) | 1.21e-14 (39.6 s) | ×1.22 |

Whole base on this card (derived): b64 2.96e7 s on the stack, b62 3.78e6 s: **b64 ≈ 7.8 × b62**.
3 of 10 b64 fields are empty at both sizes (2 of 10 at b62); an empty field costs ≈ 1.1 s with the
GPU idle. Shares of a b64 field on main: top certificates 17–18 % (the FD kernel is off at
power-of-two bases), join 67–68 % (base 12, AND 17, walk 13, prefilter + stage 25: the survivor
path is 38–40 %), check 11 % (≈ 6.5 % on the stack), setup + bucket + rest ≈ 4 %. b64 buckets hold
≈ 1,400–1,750 tops × 220–330 entries (b62: ≈ 470 × 330). No division survives at b64 (shifts and
masks); one `mul_hi` in the lean prefilter remains (1–2 %, estimate).

- **Field size:** the 1e16 tiles of a 1e17 field cost the same within ±1 % with identical counts;
  1e16 pays the idle second per empty field ten times as often: **insert b64 at 1e17, ≈ 3–4 %**.
- **Constants:** no retune moves b64 by ≥ 3 % (`TRANSPOSE_MIN` 128, `SURV_FLUSH` 768, `AND_GROUP` 8
  within ±2 %; EPT 1 or 3, `AND_GROUP` 2, `TOP_CAP` 128 lose 4–6 %; `TOP_CAP` 512 ×0.87 with spills).
- **The FD top kernel switched on at b64** (`TOP_FD_AT_POW2_BASES`, on the stack): **×1.141 /
  ×1.129 / ×1.125 on b64 1e17** (3 interleaved rounds), ×1.039 / ×1.067 / ×1.065 on 1e16; exact on
  the dense compare against the CPU join; top test 0.230 → 0.104 ns, top share 16.7 → 8.4 %,
  launches halve (the plan puts 11–13 partitions per launch instead of 5–7: #250's denser plan,
  CUDA only). The gate dates from FD round 1 ("measured slower").
- **Walk floor (N11):** it is the walk's round structure (a ~41-instruction round runs while any
  of 32 lanes has a bit left), ≈ 0.09 ps per pair; one walk over both entry slots ×1.00 at b62
  1e17, b60 1e16 and b64 1e16; without the per-round plane barrier ×0.88–0.90. **No small change
  reaches ×1.03: closed.**

Roadmap at b64 1e17: FD on ×1.13 (measured, one constant) · insert at 1e17 ×1.03–1.04 (server
config) · #251 ×1.05–1.06 (in review) · survivor path (38–43 % of the field) ≈ ×1.12 (estimate,
very large; L37's compaction lost) · binary stepping of the tops ≈ ×1.04–1.05 after FD
(instruction count, medium to large) · shift form of the walk's digit extraction ×1.01–1.02.

## T2.1 Who does the search, and what each deployed build did on demoux (2026-11-11, director, public telemetry; `../2026-11-fresh-eyes/demoux_history.py`, `demoux_history.json` (115,022 rows), `recent_niceonly.json`)

Nice-only fields submitted on 2026-11-09 and 11-10 (23,705 fields): **demoux (RX 9070 XT, wgpu on
Vulkan, main c0c357a) 81 %**, the fleet (NVIDIA, v3.4.7, ≈ 20 GPU-hours a day on 3060/4060-class
cards) 13 %, mayalaran (M4, main) 6 %. Median seconds per non-empty b60 1e16 field: demoux 11,
fleet RTX 4060 30, RTX 3060 74, M4 100–115.

Realized gain on demoux at each build switch (median seconds per non-empty b60 field, the last
1,500 fields before against the first 1,500 after, adjacent in the base; bootstrap 95 % interval):

| switch on demoux | what landed | realized | NVIDIA A/B at b60 (product of the PRs' own numbers) |
|---|---|---|---|
| 9a4f740 → c72e2c6 (10-28) | #203 and others | ×1.17 (400-field window) | — |
| c72e2c6 → 8c088a2 (10-29) | #215, #216 | ×1.14 (400-field window) | ×1.10–1.25, ×1.04–1.26 |
| 8c088a2 → 6f060a9 (11-03) | #235–#240 (with #222, #228) | **×2.11 [2.08, 2.14]** | ×1.80 |
| 6f060a9 → c0c357a (11-09) | #241, #246, #249 | **×1.17 [1.16, 1.18]** | ×1.37–1.39 |

v3.4.6 → main on demoux: 33.4 s → 11.6 s per field over the segments (×2.9; ×3.3 as the product of
the switches). **The last batch delivered less than half of its CUDA-measured gain on the card
that does 81 % of the work.** AMD cards cannot be rented on Vast and Vulkan does not start in Vast
containers (earlier notes), so the wgpu path can only be measured on demoux or after the fact
from telemetry.

Pace at the current mix (derived): b60 (80.7 %) ends in ≈ 3 days; b62 ≈ 2 months (≈ 53 days if the
fleet ran main); b64 ≈ 1.5 years.

## N1.C1 The CPU join at the transversal shape: exact prototype, counts, timing (2026-11-10, agent; `N1/cpu/RESULTS.md`, `N1/cpu/raw/` (run logs A–D, `analyze.py` summaries); fork branch `exp/n1-transversal-cpu` a32d78c from c0c357a; ivory, one EPYC-Rome vCPU, `nice -n 19`)

Change: experiment-only constructors (`JoinParams::supported_experiment`, `FieldSetup::new_experiment`,
`CpuJoin::new_experiment`), r³ mod b^(j+1) in `bot_dfs`, 256-bit r³ in `extend`, counters; +389/−11
in `overlap_join.rs`/`cpu_join.rs` plus a 567-line test module. `for_length` untouched. Exact: every
partition value of whole-base units at b10–b34 equals the reference `join_range` (survivor sets,
prefilter sets, hits), brute force to b30, 69 at b10; 30,000 random b40 units; 20 b54 and 6 b62
production-shape units (2.8e7 AND survivors, 1.0e6 prefilter survivors); the suite's 188 tests pass.

Counts per admissible n (measured; base mean of today's shape from 10 field locations):

| | b60 today / new | b62 today / new | b64 today / new |
|---|---|---|---|
| AND pairs | 1.05e-2 / 8.63e-3 | 6.7e-3 / 7.56e-3 | 3.5e-3 / 6.84e-3 |
| AND survivors | 3.8e-4 / 2.33e-5 | 2.5e-4 / 1.39e-5 | 1.5e-4 / 1.07e-5 |
| full checks | 2.4e-5 / 8.7e-7 | 1.5e-5 / 5.0e-7 | 9.6e-6 / 3.9e-7 |

My Monte Carlo: P_T and P_B within 3 %, pairs −5 % / −5 % / +20 %; its k 9 survivor column was
noise (8 and 2 events). Today's cost per admissible n varies ×2.7 between fields at b60; 2 of 10
sampled b62 fields and 4 of 10 at b64 are empty; the mid-base field is 22 % dearer than the mean at
b62. The bottom side is 8.0e15 residue *visits* per b62 base (95 ns exact, 44 ns affine on this
core), not 1.5e15; a unit of four partition digits with the fifth as the key shares one extension
across 62 values and removes it.

CPU seconds per admissible n, one thread (3 rounds, spread < 3 %):

| | b60 | b62 | b64 |
|---|---|---|---|
| today, mean of 10 fields | 2.25e-11 | 1.55e-11 | 6.81e-12 |
| (L − 4, 9, 5), affine extension | 7.62e-12 | 3.52e-12 | 3.62e-12 |
| (L − 4, 9, 4) + key digit (two-level) | 3.46e-12 | 2.65e-12 | ≈ 3.5e-12 (derived) |
| ratio, two-level vs today's mean | ×6.5 | ×5.9 | ≈ ×1.9 |

Mostly a cheaper AND, not fewer: 0.25–0.43 ns per AND against 1.0–1.15 ns (class lists of ~15,000
bottoms instead of ~300, 0.18 % of ANDs survive instead of 4.2 %). b64 is the weak base (twice
today's mean pairs: today's shape skips its empty fields and prunes by field).

**Director's re-projection of the GPU case** with these counts and a base-mean baseline (today
14.8 fs per admissible n at b62 on the 340 W card, 18.9 on the mid field; b64 ≈ 9.2 fs):

| chunk words | b62 | b62, walk floor removed (unmeasured) | b64 | b64, walk floor removed |
|---|---|---|---|---|
| u32 (portable) | ×2.45 | ×2.87 | ×1.76 | ×2.08 |
| u64, 4 chunks | ×2.90 | ×3.51 | ×2.10 | ×2.57 |
| u64, reverse orientation | ×3.18 | ×3.93 | ×2.32 | ×2.91 |

**Conclusion: on the CPU the new shape is measured at ×6 at b60/b62 and ≈ ×2 at b64; on GPUs it
projects at the ×3 bar at b62 (CUDA only) and under it at b64, where most of the remaining cost is.**

## N1.G1 Dense-phase cost per pair at other join shapes (2026-11-10, agent; `N1/gpu-tile/RESULTS.md`, `N1/gpu-tile/raw/` (`projection.txt`, `tables.txt`, `tsize.txt`, box logs, `n1_tile.rs`); fork branch `exp/n1-gpu-tile` c81875f; box 60024264, RTX 3080 at 340 W, 1.46 h, ~$0.18)

Calibration on real data (L51's profile tree 14f87cd, `join_kernel` byte-identical to c0c357a; b62
1e17 field at 7226266762397899821056, all 3,844 partitions, 3 interleaved rounds, no spill variant):
2.4655e13 AND pairs, 9.534e11 AND survivors (3.87 %), 5.80e10 full checks per field; dense phase
0.563 ps per pair (base 0.261 + AND 0.302); survivor path 17.4 ps per survivor (walk 5.6, prefilter
11.7); main unprofiled 61.93 s per field → 5.91e6 s per base on this card. (My estimates: pairs
−5 %, survivors +42 % on this field; my 0.8 ps / 36 ps were the 180 W box's.)

Synthetic tile harness (contiguous bottom lists; reproduces production's dense cost only to −19 %:
base −7 %, AND −30 %, the gap traced to buckets and remainders under 192 tops taking the per-top
AND at 0.85–0.97 ps per pair; projections scale base ×1.07 and AND ×1.43):

| tile (tops × entries) | orientation | chunk word | D_B 12 | D_B 18 | D_B 20 |
|---|---|---|---|---|---|
| 471 × 336 (today's mean) | today | u32 | 0.455 | 0.570 | 0.609 |
| 1,460 × 14,750 (f0 4, k 9) | today | u32 | 0.322 | 0.410 | 0.437 |
| 1,460 × 14,750 | today | u64, 4 chunks a pass | 0.272 | 0.323 | 0.339 |
| 1,460 × 14,750 | reverse | u32 | 0.400 | 0.410 | 0.407 |
| 1,460 × 14,750 | reverse | u64, 4 chunks a pass | 0.292 | 0.295 | 0.293 |
| 24 × 7,200 (k 10) | today / reverse | u32 | 1.11 / 3.39 | 1.11 / 3.39 | 1.11 / 3.40 |

(ps per pair, spreads ±1–3 %, counts identical across variants.) The AND part scales with the
entry's digits (17–18 fs per digit in u32, 10–14 in u64); the per-wave base does not and falls 2.4×
in the big tile, so 18 digits in the big tile cost no more than 12 in today's. u64 pays only with 4
chunks a pass. k 10's 24-top tiles cost ×2.7–11 the big tile's: dead.

Survivor path with the real walk and prefilter: 0.13–0.15 ps per pair + 14 ps × pass rate (fits
production to −1.4 % at 3.87 %). At the new 0.34 % it is 0.18 ps per pair = 54 ps per survivor:
survivors ÷ 10.8 buys the survivor path only ÷ 3.3. The floor is per-chunk machinery (ballots, the
flush decision and its barriers), not survivor work.

Whole-base b62 projection (central / uncalibrated harness; counts from NOTES §3; other overhead 2 %):

| shape | u32 | u64, 4 chunks | u64, reverse |
|---|---|---|---|
| f0 4, k 9 | ×2.56 / ×3.08 | ×3.01 / ×3.53 | ×3.20 / ×3.58 |
| f0 3, k 9, full FD top tests | ×2.81 / ×3.11 | ×3.19 / ×3.43 | ×3.05 / ×3.24 |
| f0 3, k 9, child certificates at 0.45 of a test (instruction estimate) | ×3.50 / ×3.97 | ×4.09 / ×4.51 | ×3.87 / ×4.19 |

New total at (f0 4, k 9, u32): dense 66 %, survivor path 22 %, everything else 12 %.
**Conclusion: at the user's ×3 bar, not over it. Portable u32 misses (×2.6–2.8); CUDA u64 clears
narrowly and inside the projection's own uncertainty; only f0 3 with cheap child certificates, an
unbuilt kernel, is clearly past it.**

## N5.1 Adversarial review of the no-shortcut argument (2026-11-10, agent, no hardware; `N5/REVIEW.md`, `N5/raw/` (`psj_mc.py`, `model.py`, `psj_floor.py`, `gap64.py` and outputs); ~25 CPU-seconds)

No hole that changes the exponent. Step 1 of the argument corrected: a pair with overlap o knows
2(L + o) digits. Prefix–suffix join model: flat floor ≈ 2e18 AND-units at b62, 1.6e19 at b64;
output-sensitive floor 3.4e17 / 1.6e18; information floor 4e10 / 5e11 (unreachable: list building).
The uniform-digit model holds within 10–20 % down to joint pass rates of 1e-6 (tops measured/model
0.87–0.94 at b62, bottoms 0.76–0.95). Lattice prescription ×3000–5000 worse than the join; partial
edge digits ≤ ×1.01 per base; cost per expected find at b150 ≥ 1e34 even with free lists and a
perfect join. One open engineering idea (digit-key indexed pairing, N10).

## L56.1 CPU seeded full check: PR branch (2026-11-09, agent; `L56/PR-RESULTS.md`, `L56/PR-BODY.md`, `L56/raw/`; `pr/cpu-join-seeded-check` 5c218b7 = one commit on L52's 1cce00d)

The check treats three digit sets as known: positions 0..k of n², n³ (the bottom's mask as
listed), positions k..k2 (the prefilter's four digits recomputed with the same `Fx::digits` /
`mid_values`), and the top's **pre-closure** common certificate digits (new `Cert::common`) only
where the seed flag is set (floor ≥ k2; every production survivor) — closure-forced digits are
never seeded (L47's warning). The middle digits come from design D's base-b² column form with its
own limb split (P split at b^10 with one 64-bit mul-high; `join_check` not imported since it lives
on the GPU stack; the PR's `Magic` uses the same construction and tests; merge proposed once both
land). **A/B vs 1cce00d (ivory Zen 2, 3 interleaved rounds; 1 / 4 threads):** b60 1e16 ×1.117
(1743 → 1560 ms) / ×1.139; b62 1e17 slice 0 ×1.136 (1693 → 1491 ms) / ×1.109; b58 1e15 ×1.168 /
×1.167; whole b60 1e14 ×1.090 / 1.069, b62 ×1.088 / 1.106, b64 ×1.119 / 1.110; counts identical in
every run. **NiceMark CPU 4 rounds ×1.155 (1091.0 → 1259.6; rounds 1.12–1.17).** perf (1 thread):
check share 14.8 → 4.9 % (b60), 16.1 → 4.7 % (b62); per check 119 → 36 ns / 133 → 34 ns; cycles
−8.6 / −12.7 %, IPC 2.85 → 3.12 / 2.79 → 3.17. On 4.28 M / 4.09 M recorded survivors: old 125.5 /
131.6 ns; column form with top digits 28.5 / 29.3 ns (×4.4–4.5); column form low digits only
38.2 / 41.0; L50's V3 form 50.3 / 50.8; digits converted before the verdict 9.6–9.8 → 1.8; 96 % of
checks decided within the first four middle digits. Tests: every checked survivor (test windows +
2 partitions of each PLAN field in CI; 4 partitions of each timed shape opt-in
`NICE_TEST_CPU_CHECK_REF`, 19.65 M survivors): seeds = true digits at exactly those positions and
disjoint, middle digits match position by position (count mode), distinct count =
`get_num_unique_digits`, repeat flag and verdict = `get_is_nice`; column digits vs malachite on
274,661 (n, shape) pairs at bases 3–64; 298,153 verdicts on near-nice / band-edge / adversarial n
incl. b10's 69; quotient exactness by closed-form bound + block checks in CI, exhaustive x < 2³¹
for 114 divisors opt-in (493 s); debug build with overflow checks passes; certificate parts vs
the reference and the stepped certificates; suite 196 + 22; `NICE_TEST_CPU_JOIN_REF=3`; whole b42;
fmt; clippy. (An out-of-line `Iterator::nth` from a clippy-driven `skip(1)` cost 0.7 % and was
fixed before the measured head.) → reviewer; held at the cap (4th held branch).

## L53.1 #249's top-layer sort off the device thread: third commit 80a103e (2026-11-09, agent; `L53/RESULTS.md`, `L53/raw/`; #249 head 80a103e; held branches rebased: `pr/top-fd-round2` 5d0c8cf, `pr/check-d` e28b79f)

On 87958fd `sorted_layer` ran at the top of `run_slice` inside `JoinDevice::new`, on the device
thread, after the previous slice's batches had all been read back → the GPU idled through 11
sorts per b62 1e17 field; the prep thread only computed the next slice's `sub_range`; slice 0's
sort was not in `plan_join` either. Fix: `sorted_layer` → `join_plan`; `plan_join` sorts slice 0
(the client already overlaps it with the previous field); the prep thread sorts later slices;
`JoinDevice::new` only uploads; residues step from the previous prefix by addition (99.8 % of
steps < b), u64 division only after larger gaps. Sort time (b62 1e17 field): 2.05 s standalone /
2.28 s in place → 1.02 s off the device thread (device thread keeps a 0.03–0.05 s copy of slice
0's layer, never waits); b60 1e16 0.37 / 0.41 → 0.18 s. **A/B (RTX 3080 at 150 W, E5-2630 v4):**
separate processes (3 rounds; 6 of 26 processes spilled and were re-run; clocks ±4 % between
processes): device time ×1.009 / ×1.023 / ×1.021 / ×1.023 (b62 1e17 / b60 / b62 1e16 / b64), wall
×1.006 / 1.016 / 1.007 / 1.019; **same process alternating old/new path (shared kernel image and
temperature): b62 1e17 ×1.022 (1.020–1.024), b60 ×1.016, b62 1e16 ×1.020, b64 (one slice) ×1.007.**
Below the ×1.03–1.04 estimate because this box's field is 103 s (150 W) and the sort 2.28 s; on
L51's box ≈ ×1.027 (estimate). Exact: new sort output and `goff` word-for-word = #249's on every
slice of four fields (30.6 M prefixes); every timed count; 1e14 COMPARE; dense; whole b42; parity;
certificate test; #249's sentinel FD-vs-top test (237,948,545 tops — this box cuts the b60 1e16
test field's slices differently from L46's 237,907,266; 87958fd gives the same here); host test
also on a reversed layer (21 fields, 582,884 buckets); lavapipe 8/8 ×2; lint 14/0; fmt/clippy ×3.
Rebases conflicted after all (round 2: `top_fd_runs` adjacent to the removed `sorted_layer` +
CHANGELOG; check-d: `check_counts` calls `JoinDevice::new`, which now takes the layer); both pass
unit tests, 1e14 COMPARE, parity (and check-d its count test). #249's body updated (three
commits) and a comment posted. Box 2.6 h.

## L54.1 / L55.1 Transposed-AND codegen and the register pin (2026-11-09, agent; `L54/RESULTS.md`, `L54/raw/` (box dumps, `analysis_*.txt`, `l55/`); branch `exp/join-and-codegen` 19702e1 = form 2 in PR form on d813aea, forms behind `NICE_EXP_AND_FORM` in d91447a)

SASS per digit in the AND loop (b62 = b60; identical across 5 shared layouts): d813aea **30**
(8 loads/ORs, 8 address, 11 bit iteration, 3 recomputed invariants); form 1 fold-only (index
masked with `& (TR_WORDS − 1)`, which gives NVRTC the no-wrap proof offline nvcc already assumes)
**24**; form 2 fold + walk the low mask word then the high **20**; form 3 form 2 with 4 shared arrays
per chunk group **19**; per (warp, 4-chunk group) 848 → 704 / 614 / 590 (−17 / −28 / −30 %). The
leaner bit loop (highest-bit / `trailing_zeros` / `clz` forms) costs the same as `BREV`+`FLO`+
`x&(x−1)` or more. **A/B vs d813aea (RTX 3080 at 130 W, 3 interleaved rounds):** form 1 ×1.009 /
×1.016 (b62 1e17 / b60 1e16); form 2 ×1.008 (0.963/1.012/1.008; ×1.012 without the cold-card
round) / ×1.018; form 3 ×1.016 / ×1.020; b62 1e16 ×1.010–1.018; b64 ×1.005–1.009. Cycle ratios
unusable (per-process clock means scatter ±6 % at 742–944 MHz on 5-s samples). Likely cause: at
130 W denser issue lowers the clock; a quarter to half of the predicted ~3.5 % of cycles shows in
wall time. **Record only: no form reaches ×1.03.** Register variants recorded: d813aea 46–48 with
the 40 + 24 B spill variant in 1 of 12 timed processes (re-run), 3 of 24 kernels in a 1e14 run;
forms 2/3 47–48, no spill in 48 kernels (even on the layout where d813aea spills; not
guaranteed). Exact: form 2's tree passes parity incl. b50/b54, the FD-vs-top test, certificate
test, dense fields, whole b42, 1e14 COMPARE (= L34's counts), lavapipe naga + SPIR-V 8/8, lint
14/0, fmt/clippy ×3 → **form 2 is a ready rider for a future join PR** (applies unchanged on
#249's head; one `use` line differs on #246). **L55 not feasible in CubeCL 0.10/0.11.3:** only
`__launch_bounds__(cube_dim)` is emitted, NVRTC options are hard-coded, `cuModuleLoadData` has no
JIT options, no PTX hook, `__maxnreg__` is rejected beside `__launch_bounds__`. Smallest upstream
patch: a `min_cubes_per_sm` kernel option plumbed like `cluster_dim` → `#[cube(launch_unchecked,
min_cubes_per_sm = 5)]` emits `__launch_bounds__(256, 5)`; 25 lines over 6 files
(`L54/raw/l55/cubecl-0.10-min-cubes-per-sm.patch`); sm_75 warns and ignores. **Root cause of the
1-in-7 lottery: CubeCL places shared arrays in `HashSet` order, randomised per process** → a
deterministic order would also remove that A/B noise. Box 2.5 h.

## L52.2 Two-pass scan: review fixes and the AVX-512 path executed on a Zen 5 host (2026-11-08; `L52/REVIEW.md`, `L52/PR-RESULTS.md` "Review follow-up", `L52/raw/avx512/`; head 1cce00d = one commit on #248)

Review (all seven planted bugs caught by the new test; portable + AVX2 correct by test, AVX-512
correct by reading only): fixes — AVX-512 taken only with `avx2` too (pass 1 uses a VEX
`vpbroadcastw`); the false "two pieces" coverage claim removed and a `piece` field (1024 outside
tests) lets `every_scan_finds_the_same_pairs` cross piece boundaries (suite also run once with
the constant at 9); `the_bit_tables_list_every_byte` over all 256 bytes; `debug_assert` on
`pass1`'s length contract; commit message/body corrections. Tests on ivory at 1cce00d: 190 + 22,
`NICE_TEST_CPU_JOIN_REF=3`, whole b42; fmt; clippy; sanity A/B ×1.21–1.29 (runtime piece length
costs nothing). **AVX-512 host: Vast 59703250, AMD Ryzen 9 9950X (Zen 5), ~15.4-core container
($0.43/h, 1.3 h):** avx512f + avx2 detected; the pass-1 test ran all three paths (84,860 bottoms
listed alike); the whole `cpu_join` suite (15), 190 + 22, `NICE_TEST_CPU_JOIN_REF=3`, whole b42
(same counts as ivory) all pass; three binaries (#248's old AVX-512 loop, the PR, the PR with
AVX-512 switched off) give identical counts everywhere (b60 1e14 1,326,103,590 / 84,383,498);
**speed over #248 on Zen 5: b60 1e16 ×1.232 (1 thread, 6 rounds) / ×1.225 (8 threads); b62 1e17
slice 0 ×1.238 / ×1.216** (beats the ×1.08–1.15 AVX-512 estimate; the new AVX-512 pass 1 is within
noise of the new AVX2 pass 1 there, ×0.95–1.04; box noise ±8 %). CI runners' AVX-512 support
still unknown. PR-ready, held at the cap.

## L52.1 CPU two-pass AND scan: PR branch (2026-11-08, agent; `L52/PR-RESULTS.md`, `L52/PR-BODY.md`, `L52/raw/`; `pr/cpu-join-two-pass-scan` cd661b0 = one commit on #248 7f5260b; worktree `.worktrees/l52-two-pass-scan`)

All three scan paths run two passes over pieces of ≤ 1024 bottoms: pass 1 makes a byte of pass
bits per 8 bottoms (`vptestnmq` / AVX2 compare + movemask / 8 scalar tests) and a shared `emit`
stores the set-bit positions as u16 indices from a 256-entry table, advancing by a 256-entry
count table (no branch on the bits; the last 0–7 bottoms stored always); pass 2 runs `survivor`
(`#[inline(always)]`) on the listed bottoms in original order; the full check stays out of line;
bounds-checked slice writes, no new `unsafe`, no knobs. New test
`the_first_pass_lists_the_same_bottoms_on_every_path` (114 class lengths ≤ 1024 at 0/1/40/100 %
passing + 1025–5120 through each path's dispatch). **A/B vs #248 (ivory Zen 2, 3 interleaved
rounds, loads ≤ 2; 1 / 4 threads):** b60 1e16 ×1.266 (2225 → 1758 ms) / ×1.260; b62 1e17 slice 0
×1.237 / ×1.237; b58 1e15 ×1.300 / ×1.316; whole b60 1e14 ×1.100 / ×1.104, b62 ×1.079 / ×1.083, b64
×1.162 / ×1.182; every production-shape round ×1.22–1.28. **NiceMark CPU 4 rounds ×1.261 (864.9 →
1091.0)**, rounds 1.22–1.28. perf (1 thread): branch misses 61.3 M → 25.3 M (b60) / 58.4 → 21.7 M
(b62); IPC 2.18 → 2.81; instructions +3–4 %; cycles −19–20 %. Exact: every run = #248's counts
(1e14 b60/b62/b64 incl.); tests 189 + 22; `NICE_TEST_CPU_JOIN_REF=3`; whole b42; the three-path
comparison incl. a b57 window with classes split into two pieces. **AVX-512 pass 1 compiled and
its assembly read (AVX-512F/AVX2 only) but never executed** (no AVX-512 host; CI runner CPU
unknown); the path is still selected on `avx512f` alone although pass 1 now uses an AVX2
instruction — detection should require avx2 too (reviewer). → reviewer; held at the cap.

## L51.1 Full stack d813aea profiled, ablated, retuned (2026-11-08, agent; `L51/RESULTS.md`, `L51/raw/` (logs, PTX-replay records, SASS, `analyze51.py`); branch `exp/l51-profile` 14f87cd)

RTX 3080 180 W on m139246 (L47's host too): d813aea = 79.10 s per b62 1e17 field, 15.85 s per b60
1e16 (L48.2's machine 73.4 s); exact counts throughout. **Phase split (b62 / b60):** FD top kernel
22.8 % (18.0 s) / 18.4 %; bucket 2.5 / 2.3; **join 55.9 % (44.2 s) / 59.0 %**; **check 12.0 % (9.5 s) /
14.4 %**; other 6.7 / 6.0 (**slice setup 4.8 / 4.5**). Profiled field 0.966× / 0.977× the unprofiled
in time (syncs let the card run 104 MHz faster at b62). **Join ablation (3 profiled rounds, % of
field):** base 10.9 / 10.5 (#249 took it from 15.9); **AND 14.9 / 15.0** (8.4 → 11.4 s; issue-bound by
instruction count); walk 9.2 / 9.0; prefilter 19.8 / 23.5; stage 1.1 / 0.9; the per-top AND
everywhere would cost ×1.14 / ×1.12. **Retune (2 interleaved rounds, each value its own kernel):**
EPT 1 ×0.949 / 0.948, EPT 3 ×0.939 / 0.951; TRANSPOSE_MIN 128 ×1.005 / 1.007, 256 ×0.985 / 0.984, 512
×0.873 / 0.908; AND_GROUP 2 ×0.946 / 0.953, 8 ×0.990 / 0.986 (4 cubes/SM); TOP_CAP 128 ×0.962 /
0.961, 512 ×0.935 / 0.945 (3 cubes/SM); FD cube 128 ×0.991 / 0.994, 512 ×0.994 / 0.998; stage once
per work item ×0.995 / 1.005; SURV_FLUSH 256 ×0.999 / 1.005, 768 ×0.996 / 1.008 → **no retune
reaches 3 %; defaults stay** (default scatter ~3 % within a block). **Two findings:** (1) **#249's
`sorted_layer` host counting sort runs inside the per-slice setup on the device thread with the
GPU idle: 2.55–2.84 s per b62 field (3.2–3.6 %), 0.44–0.46 s per b60 (2.8–2.9 %); ~7 u64 divisions
per prefix** → move into the overlapped field setup or do it in u32: ×1.03–1.04 / ×1.03 (host-only,
exact). (2) **~1 in 7 `join_kernel` compiles (5 of 32) picks a 40-register spilling variant worth
~3 % of the field (×0.968 / ×0.972 pinned)**; `.minnctapersm 5` or `.maxnreg 48` in the PTX gives 44
registers, no spill, ×0.992–1.003 of the normal 46–48-register code → ~0.4 % fleet-wide, 3 % for
affected processes; **A/B method: record each process's join-kernel variant (`ptxjit.py`) or pin
the compiled code** (every spill-variant process in this screen was re-run). **Re-pricing (no-go):**
L44 §3a fewer AND digits ×0.92–0.97; §3f digit-major LDS.128 ≤ 1 % (bank conflicts); L40 group walk
on the 41-instruction round 1.3–3.0 % / 2.2–4.0 % at best with its NiceMark loss and 4 cubes/SM;
COMPACT=2 ≤ 0.5 %. **AND codegen (go, no GPU needed):** the AND runs at ~2× its shared-memory floor,
52–60 % instruction overhead (7.8–9.0 % of the field in cycles); 8 of its 30 instructions per digit
are unfolded address arithmetic from CubeCL's index construction → folding ≈ 4.3 % of the field in
cycles (2.1–3.6 % time), with a leaner bit loop 3.0–5.1 %. **Ranked ≥ 3 %:** check kernel (L47,
done), `sorted_layer` off the device thread, AND codegen; below: the spill-variant fix (~0.4 %),
TRANSPOSE_MIN 128 (+0.5–0.7 %). Box 3.5 h.

## L47.1 Check kernel design D: built, exact, at the memory floor (2026-11-08, agent; `L47/RESULTS.md`, `L47/PR-BODY.md`, `L47/raw/`; `pr/check-d` 0f3332d = one commit on d813aea; knobs on `exp/check-d` 1187527c)

**Step 0 (old kernel, profiled, 2 rounds):** loads-only check (list entry + record words 0, 1, 6) =
3.36 s per b62 1e17 field / 0.76 s per b60 1e16 field = 0.745 TB/s = 98 % of the 3080's DRAM
bandwidth (< the 4.5 s build line); old kernel 8.79 / 2.13 s; cube sweep: 2048 cubes −3.7 / −3.8 %,
one exact wave (408) +2.8 / +1.6 % → the wave tail is ~4 %, not 6–16 %. **Kernel (driver JIT of
NVRTC PTX):** 39–40 registers in all 24 A/B processes (gate ≤ 48), no spills, no local, no shared;
330 instructions per warp-iteration on the b62 common path (gate ≤ ~360; +249 for the rest of n³
past the gate; b60 312, b64 306, b57 302); check 3.19 / 0.74 s = at the gather floor (×2.8 / ×2.9
vs the old kernel); gate width g = 8/10/12 flat ±2 % (memory-bound) → ships g = 10; one entry per
lane per take beat 4 and 8 by ~7 % (39 regs → 6 cubes/SM vs 5). **New device tests**
`cubecl_{,cuda_}check_counts_match_the_cpu`: per survivor the distinct-digit count, the gate
result and the digit mask vs the CPU (count mode) + every n rebuilt from its limbs (probe mode):
1,413,630 real list entries + 96,042 synthetic adversarial/random n over 26 field shapes, 3,599
past the gate; same totals on CUDA, lavapipe naga, lavapipe SPIR-V, and on the final head; host
tests for the new `join_check` module incl. an exhaustive check of all 114 divisors over every
x < 2³¹. **A/B vs d813aea (3 interleaved rounds):** b62 1e17 74.65 → 68.64 s **×1.088**
(1.077/1.086/1.107; cycles ×1.099; same median clock 1440 MHz at 179.6 W), **b60 1e16 15.20 →
13.52 s ×1.124** (1.137/1.105/1.124; ×1.140), b62 1e16 ×1.085, b64 ×1.070, 1e14 b57/60/62/64
×1.078/1.046/1.015/1.003; **NiceMark 6 rounds ×1.056** (1.050–1.066; b58 weak ×1.077, strong
×1.039, b60 ×1.060, b62 ×1.060). Exact: 1e14 COMPARE join = stride same counts; `check_all` incl.
b10's [69]; whole b42 417,789,835 / 16,879,877 join = stride = reference; dense fields; #249's
sentinel FD-vs-top test; certificate test; identical counts in every timed run and all 12
NiceMark runs; lint 14/0. The PR drops CI's `--require CheckKernel@57` (that requirement needs a
constant division in the kernel; the new kernel has no `/` or `%`). Final head 5be672c-equivalent
= timed tree + fmt/clippy/comments, re-verified. Next lever: the check is load-bound; carrying P in
the survivor list ≤ ~2 % of the field (not tried). Box 2 h. → reviewer; held at the PR cap (second
PR-ready branch on the GPU chain after FD round 2).

## L48.2 FD top kernel round 2 on #249: review fixes, wave64 gate, CUDA-scoped batches, combination A/B (2026-11-07, agent; `L48/REVIEW.md`, `L48/RESULTS.md` "Round 2", `L48/raw/r2/`; `pr/top-fd-round2` d813aea = one commit on #249's 87958fd; held at the PR cap)

Review (merge with small fixes; kernel changes exact by re-derivation + a host model): M1 the
ballot append keeps only 32 bits on CubeCL's C++ backends (wave64 CDNA via opt-in cubecl-hip
would miscount) → comptime `ballot = plane_size_max <= 32` from `client.properties().hardware`,
#249's `top_slot` uses the ballot's first word when on, the two plane scans otherwise (gate
forced off on CUDA: device test passes); M2 real memory rises to the budget at 1e16+ (b60 1e16
1.6 → 2.5 GiB; on wgpu the binding-limit budget would give 2.6 → 3.9 GiB even on small cards) →
`JoinLimits.vram_budget` set only by the CUDA runtime; `SURV_PER_PREFIX_VRAM = 1` only on CUDA and
only on fields the FD kernel certifies (`top_fd_runs`); wgpu, power-of-two bases and all slices
keep 2 (`SLICE_SURV_PER_PREFIX` gone); layout +31–64 % at 1e16+ on CUDA, stated; host tests pin
the gate, the plan (same slice cuts, more slots; b64 identical) and the two b20 windows that
re-form the carried c0 (P = 201 square, P = 231 cube — the only coverage of that path; timed
fields never cross a c0 change). L3 headroom halved (overflow above 2.0–2.1 survivors per prefix,
was 4.5–4.7; re-run path unchanged) documented. **Plan (10 GB, budget 2,469 MiB):** b62 1e17 11
slices identical, first-slice slots 5 → 11, 1,463 → 2,393 MiB, batches 6,439 → 3,288; b60 1e16 2
slices identical, slots 4 → 9, batches 1,350 → 625; no overflow re-runs. **A/B vs 87958fd (180 W,
3 interleaved rounds): b62 1e17 ×1.127 (1.123/1.108/1.127; 82.80 → 73.44 s; cycles ×1.140), b60
1e16 ×1.112 (1.136/1.108/1.112; 16.43 → 14.77 s), b62 1e16 ×1.129, b64 ×0.991–1.005 (#249's
kernels and plan exactly; scatter), 1e14 ×0.978–1.059 (same plans); NiceMark 6 rounds ×1.032
(b58 weak ×1.022, strong ×1.009 (lowest round ×0.972), b60 window ×1.052 still 2 slices with 5 →
10 a launch, b62 ×1.055).** Kernel alone: FD 0.2070 → 0.1371 ns per (prefix, slot) (−33.8 %) /
0.2061 → 0.1358 (−34.1 %); stepped slot −30.4 / −31.6 %. Registers 108 / 107 (#249: 112 / 108),
SASS 4,360 / 4,176, no spills, 2 blocks/SM; SPIR-V blocks 278–296. Exact on the combination:
#249's sentinel FD-vs-top test (423.1 M tops; pushed code 375.9 M; gate off too), parity,
certificate test, dense (b62 at 11 a launch, 0 re-runs), whole b42, 1e14 COMPARE, every timed
field; lavapipe naga + SPIR-V 8/8; lint 14/0; fmt/clippy ×3. Box 180 W, ~2 h.

## L48.1 FD top kernel round 2: ×1.082 at b62 1e17, PR-ready (2026-11-07, agent; `L48/RESULTS.md`, `L48/PR-BODY.md`, `L48/raw/` (box logs, scripts, patches, bundle); `pr/top-fd-round2` bedc658 = one commit on f3fb390; switchable `exp/top-fd-round2` f168b28, levels 1–7 and 103)

Box at **170 W** (default 320). Levels: 1 = L36.2's three trims, 2 = +ballot append (f3fb390's
append was `plane_sum` + `plane_exclusive_sum` + atomic + broadcast, not "one ballot + one atomic"
as L44 said; level 2: 7 SHFL → 2, +2 VOTE), 3 = +partial x mod b^c0 (**slower** than 2: SASS
4,936, SPIR-V blocks 355–391 > TopKernel at b64), 4 = +SURV_PER_PREFIX 1, 5 = +early-exit carries,
6 = 5 without 3, 7 = 4 without 3. **PR ships level 6** (trims + ballot + early-exit carries +
SURV_PER_PREFIX 1) **with a separate `SLICE_SURV_PER_PREFIX = 2`**: the first PR form also cut
slices and **failed the kill rule** (NiceMark b60 ×0.976 in all six rounds: its window went 2 → 1
slices, a wider slice prunes less at the field certificate, +2.6 % per partition); keeping slices
fixed it and the fields came out slightly faster. Registers/SASS (NVRTC→JIT = nvcc): base 110 /
3,888 (b62), PR 108 / 4,472; 0 spills, 2 blocks of 256 per SM at every level; SPIR-V blocks base
298–310 → PR 280–298. Kernel-alone ns per stepped slot (b62 / b60): L0 0.2045 / 0.2021; L1 0.1554 /
0.1537 (−24 %); L2 0.1454 / 0.1444 (−29 %); L6 0.1424 / 0.1493; base vs PR binary in production
batches: FD kernel 0.2424 → 0.1678 ns (−30.8 %) / 0.2447 → 0.1644 (−32.8 %). Screen vs L0 (b62 /
b60): L1 ×1.041 / 1.031; L2 ×1.047 / 1.043; L3 ×1.044 / 1.039; L4 ×1.063 / 1.059; L6 ≈ L4 + 0.6 %.
**A/B PR vs f3fb390 (3 interleaved rounds; NiceMark 6): b62 1e17 ×1.082 (1.076/1.083/1.086;
107.90 → 99.76 s; cycles ×1.111), b60 1e16 ×1.070 (1.068/1.075/1.070; 21.32 → 19.92 s; cycles
×1.054), b62 1e16 ×1.093 (×1.197), b64 ×0.997 neutral (FD off; plan 6 → 7 a launch), 1e14
×1.028/1.034/1.014; NiceMark ×1.029 (b58 weak ×1.018, strong ×1.036 (lowest round ×1.003), b60
×1.034, b62 ×1.033; NiceMark seeds every slot, so it sees only the ballot, the carry test and the
larger batches).** PR side 50–100 MHz slower at the cap on b62. Plans (10 GB, 2,560 MiB): b62 1e17
5 slots / 1,670 MiB / 6,439 batches → PR 9 / 2,457 / 4,009; b60 1e16 4 / 1,566 / 1,350 → 8 / 2,431 /
675; memory and binding bounds now bind first; measured 0.53 survivors per prefix and partition vs
1 assumed; no overflow re-runs. **Exact everywhere** (CUDA full list at levels 1–4 and both PR
forms; levels 5–7/103 the device test; every timed field; lavapipe naga + SPIR-V; lint 16/0;
fmt/clippy ×3). Conflicts with L46/#249 only in the append block (destination untouched → should
rebase cleanly). Box 3.3 h. **Held at the PR cap (5 open); reviewer launched.**

## L49.2 CPU fixed-point prefilter: review fixes and PR #248 (2026-11-07; `L49/REVIEW.md`, `L49/PR-RESULTS.md` "Review follow-up", `L49/raw/*-v2.txt`, `raw/m2/`; PR #248 head 7f5260b = one commit on #247 caef70e)

Review (tests run incl. FX exhaustive 6.63e11 triples, 306 s): merge with small fixes, no defect.
Fixes: `dm` dropped from `Top` (64 → 48 bytes; `const _: () = assert!(size_of::<Top>() == 48)`;
`prefilter_any` recomputes D from `top.p`) — the sort share back to #247's (1.39 % / 1.27 % vs 1.84 /
1.57 at 64 B); sanity A/B on the new head (4 threads, 4 rounds, two loaded rounds discarded):
b60 1e16 2642 → 2298 ms (×1.15), b62 1e17 slice 0 2474 → 2234 ms (×1.107), counts identical;
`survivor` share 21.9 / 22.8 % → 14.5 %. **M2: no test window with unseeded stepped tops can
exist** (every full block seeds: e² − a² ≥ b^(L+f0−1) → floor ≥ L + f0 ≥ k + 2; unseeded tops are
only clipped blocks < ~b/2 numbers at a field's end; search of every b20 4-digit window start
found none); the stepping test now asserts `full_floor ≥ k2` and the body states the coverage.
Dispatch `lean: mid == 2 && k > mid` with the matching assertion; docs/nits applied; title
"fixed-point". Tests 188 + 22, fmt, clippy, `NICE_TEST_CPU_JOIN_REF=3`, whole b42 all pass. **PR
#248 opened 09:00 UTC.** Open program PRs: #241, #246 (on #241), #247, #248 (on #247).

## L46.1 Static bucket order for the top layer: built, exact, ×1.158 at b62 1e17 (2026-11-07, agent; `L46/DESIGN.md`, `L46/RESULTS.md`, `L46/PR-BODY.md`, `L46/raw/`; branches `exp/join-static-buckets` b058bb7 (6 commits), PR-ready squash `pr/join-static-buckets` 318fdae (one commit on f3fb390), rider `exp/join-static-buckets-s15` 4b27507)

Design: a slot's top lands in bucket (key, (root − pc) mod (b−1)) with pc = (c0 + v) mod (b−1), c0 =
P0 mod (b−1) (b^p ≡ 1), so the slot only rotates the class; the host counting-sorts each slice's
top layer once by g = key·(b−1) + c0 and uploads `goff` (nb + 1 words); tlay words 2–3 carry g and
goff[g]; the top kernels append each kept top into its group's segment of `top_rec` with one
counter per (slot, group) (`top_slot` helper: one atomic per plane in `top_fd_kernel`, one per top
in `top_kernel`); a join work item w = slot·nb + bucket reads `nroots` segments g_r = (key,
(root_r − cls − v) mod (b−1)) with consecutive record loads (batches still fill 256 tops across
segment boundaries); **deleted: `top_scan_kernel`, `top_fill_kernel`, `tl`, `top_b`, `work`,
`cursor`, the per-slot count and the per-kept-top `nroots` atomics; STAGES 6 → 4; layouts 11–29 %
smaller; slots/slices/batches unchanged.** `nroots` is comptime in the join (runtime loops → 60
registers or spills); a serial thread-0 scan places the segments (plane-size independent); the
work item's offsets/count/key live in shared memory. **Exact on the final tree** (= base and L38's
lists): parity incl. b50/b54 + b57 frontier; adapted FD-vs-top device test (per-(slot, group)
counts and segment records; 26 fields / 279 batches / 237.9 M tops); certificate test; dense
254,938,965 / 14,396,829 and 120,013,475 / 7,355,827; whole b42 417,789,835 / 16,879,877; 1e14
COMPARE; every timed field every round (b62 1e17 1,020,844,021,499 / 62,584,252,554 …); lavapipe
naga + SPIR-V 8/8; lint 14 shaders 0 flagged; fmt/clippy ×3. Registers (driver JIT of each
process's NVRTC PTX): join 46–48 spill-free in 30/37 processes incl. all 12 timed production
fields (the other 7, 1e14 and register samples: 40 + 8–32 B spills in per-item/per-wave code, no
slowdown); top_fd 108–112; top_kernel 80 → 97–103 no spills (no measurable cost); 5 cubes/SM.
**A/B vs f3fb390 (180 W RTX 3080 m139246, 3 interleaved rounds, equal clocks): b62 1e17 100.38 →
86.68 s ×1.158 (rounds 1.141/1.158/1.158; cycles ×1.174); b62 1e16 ×1.147; b60 1e16 19.675 →
17.049 ×1.154 (cycles ×1.150); b64 1e16 ×1.222; 1e14 b57/60/62/64 ×1.096/1.056/1.055/1.028;
NiceMark 6 rounds ×1.119 (1.103–1.138): b58 weak ×1.145, strong ×1.043, b60 ×1.153, b62 ×1.145.**
Beats L45's ×1.107 ceiling: scan + fill = 9.7 of the 13.7 s saved, the rest the FD kernel's lost
atomics (FD kernel alone ×1.054–1.060) and the join's consecutive record loads. **Rider (stage
checked once per top batch) vs this branch: b62 1e17 ×1.029, b62 1e16 ×1.024, b60 ×1.022, b64
×1.030, NiceMark (2 rounds) ×1.019; exact, lavapipe + lint pass; not in the PR branch yet.**
Conflicts with L48's level-2 append trim (same block; whichever lands second redoes it). Box
2.75 h. → reviewer agent on 318fdae + the rider.

## L49.1 CPU lean prefilter: PR branch (2026-11-07, agent; `L49/PR-RESULTS.md`, `L49/PR-BODY.md`, `L49/raw/`; branch `pr/cpu-join-lean-prefilter` d32f579 = one commit on #247 caef70e; worktree `.worktrees/pr-cpu-join-lean`)

`cpu_join.rs` +329/−41 (~200 lines tests): private `Fx` type (own constants) for the digits; `fresh4`
membership by shifts + six compares joined with `&` (branch-free; masks keep digit d at bit d —
x86 shifts need no reversal); `Top.seed` → gated `Top.gmask` + `Top.dh` (Top 48 → 64 B). The
fixed-point path is the only path for mid = 2 and k > mid (all production shapes); k ≤ mid (b10,
one b20 window) keeps the division form; old `prefilter` body, `smid`, `SmallDiv::rem` removed.
**A/B vs #247 (ivory Zen 2, 3 interleaved rounds, loads ≤ 2.0; 1 / 4 threads):** b60 1e16
partitions ×1.091 / ×1.076; b62 1e17 slice-0 partitions ×1.067 / ×1.106; whole b60 1e14 ×1.051 /
×1.056; b62 1e14 ×1.047 / ×1.064; b64 1e14 ×1.119 / ×1.109. **NiceMark CPU (4 rounds): 798.5 →
868.5 = ×1.088** (rounds 1.069–1.104): b58 weak ×1.097 (1 thread ×1.093), b58 strong ×1.053, b60
×1.113, b62 ×1.074. perf: `survivor` (range test + prefilter) 22.9 % of #247's join → 14.7–15.1 %
(×1.7 cheaper). Exact: every run = #247's counts (b60/b62/b64 1e14 fields; sampled production
partitions); whole b42; `NICE_TEST_CPU_JOIN_REF=3`; FX exhaustive over 6.63e11 triples (299 s on 4
threads). Tests in the PR: `fx_digits_match_the_division` (CI-sized, 4.46e8 triples),
`fx_digits_are_exact_everywhere` (opt-in `NICE_TEST_FX_EXHAUSTIVE=1`), `lean_membership_matches_
the_masks`, `lean_prefilter_matches_the_division_form` (1e6 pairs per base), `production_shapes_
take_the_fixed_point_prefilter`; stepped-vs-divided tops test now compares `dh`/`gmask`; 188 + 22
pass; fmt; default clippy. Caveats: Zen 2 only; RC's ×1.00 is the old L42 number. → reviewer.

## L45.1 Measurement session on #246: top-phase split, lean-join ablation, stage cadence, spills (2026-11-06, agent; `L45/RESULTS.md`, `L45/raw/` (logs, per-process kernel classification, SASS, CUDA, PTX; `analyze45.py`); branch `exp/join-l45-measure` 8a07c05 on f3fb390)

RTX 3080 180 W (m139250); unprofiled field 100.23 s (b62 1e17) / 19.63 s per field (b60 1e16);
every full-kernel run = the exact counts. **A. Top phase (3 profiled runs, medians):** FD kernel
25.23 s = 25.2 % (b60 4.12 s = 21.0 %); clipped launches 0.0 %; `top_scan_kernel` 1.06 s = 1.06 %
(0.21 s); **`top_fill_kernel` 8.63 s = 8.61 % (1.56 s = 7.96 %); scan + fill 9.7 % / 9.0 %** =
0.254 / 0.257 ns per kept top (L31's 0.22–0.26). Profiled vs unprofiled +0.6 % / +2.0 %; one empty
profile mark = 12 µs per batch. Check kernel 9.1 % / 11.3 % (L44 derived 9.5 / 11.4). **B. Lean-join
ablation (3 interleaved profiled rounds, % of field):** base 15.9 / 15.4; **AND 8.3 / 8.3 (not
L44's 1.1 %: #241's top record removed the latency that hid it)**; walk 6.4 / 7.0; prefilter 16.1 /
19.2; stage + flush 1.3 / 1.9; join 48.2 s / 10.2 s. Per-top AND everywhere (TMIN 2^30) costs
×1.094 / ×1.075 (#239 still pays). **Stage cadence (unprofiled A/B, 3 rounds vs every chunk):**
every 8 chunks ×1.022 b62 / ×1.020 b60; once per top batch ×1.020 / ×1.023 (rounds 1.018–1.033;
cycles ×1.03–1.05); every 4 chunks ≈ two thirds of that; all exact, the stage never fills even once
per batch (0 spilled pairs in 6 runs) → barrier waits are ~2.5 s of L44's 23 s unattributed, not
most. **Spills: none in production** — 100 runtime NVRTC→driver JIT compiles gave 47–48 registers,
no spills; L41's 40 + 28 B came from nvcc's offline compile. Pinned-image timing (3 rounds): nvcc's
spill build 1.7–2.9 % slower in the join (1.4–1.5 % of field) than nvcc's spill-free
`__launch_bounds__(256,5)` build; the runtime compile 3.4–3.5 % slower in the join (1.7 % of field)
than that — the gap is NVRTC's PTX, not the JIT; nvcc's PTX only wins with the 5-cube launch bound.
**Verdicts: item 1 (scan + fill < 5 %) not fired → L46 builds (ceiling ×1.107 / ×1.099 if scan +
fill vanish); item 5 no build** (cadence ~2 %, compile path ~1.7 %, spills 0) — once-per-batch
stage check is an exact rider for the next join PR; the AND at 8 % of the field says re-price
L44 §3a/§3f's AND ideas. Box 2.7 h.

## L42.3 CPU FD top certificates: review fixes, b64, PR #247 (2026-11-06, agent + director; `L42/REVIEW.md`, `L42/PR-RESULTS.md`, `L42/raw/pr/`; PR #247 head caef70e = one commit on main 6f060a9)

Review (independent, with tests run): merge with small fixes, no defect; the f64 carry screen's
error ~4e-12 vs margin 2⁻²⁰, 20.7 M adversarial boundary calls agree; step/word counts bounded at
the slice's last prefix. Fixes applied: the missing carry test
(`a_carry_runs_through_words_of_b_minus_1`; fails under both surviving mutations M1 ripple / M4
`cin`, passes on the branch; `L42/raw/pr/mutation-s1.txt`); rustdoc link, test-only derives,
private `MAX_STEPS`/`poww` accessor, `step_by(..max(1))` guard; body: 3e15 NiceMark window, #240's
×1.48–1.61, "413,250 kept; 243,907 seeded", round loads stated, overshoot path (steps once past P
then re-seeds; values below phi + h still fit). **b64 A/B vs main (3 rounds, loads ≤ 2.0): b64 1e16
partitions ×1.039 (1 thread) / ×1.068 (4); b64 1e14 whole field ×1.076 (359.0 → 333.7 s) / ×1.088
(96.1 → 88.3 s); counts identical (5,702,041,796 / 346,647,759).** b64 gains less than b60/b62
(×1.25–1.29): ~2.8× the survivors per partition and 9–10 % of prefixes seeding vs 2.3 % (not
profiled); the CPU takes the stepped path at b64 (unlike #240's GPU kernel) because `Base::cert`
divides by a runtime base at every base. Tests 184 + 22; `cargo doc` 7 warnings = main's 7. The
agent's permission guard refused the amend → two commits; the director squashed them (tree
identical) and opened **PR #247** at 10:25 UTC. Open program PRs: #241, #246 (on #241), #247.

## L41.1 Lean `walk_pf` (FX + MT + GM + RC): PR branch, ×1.086 at b62 1e17 (2026-11-06, agent; `L41/RESULTS.md`, `L41/PR-BODY.md`, `L41/raw/`; branch `pr/join-lean-prefilter` d672887 = one commit on 7832f89 (#241); prototype `exp/join-lean-pf` a150b49 (knob `NICE_EXP_JOIN_PF`), variant `exp/join-lean-pf-cwcopy` d5db28b)

Host tests: FX exhaustive over every (A, P, D) < b² at every base 10–64 = 6.63e11 triples, all
exact (190 s on 9 threads; ignored + `NICE_TEST_FX_EXHAUSTIVE=1` since CI runs ignored tests); in
CI: constants and `dh` vs exact ceilings for every D < b², the Δ < 2³² bound, digits for every
(P, D) at max A and every (A, D) at max P; MT vs the old four-mask test for every digit 4-tuple at
every base (2.1e8) + 1e7 random; end-to-end lean vs division form on 1e6 random pairs per base
(4.4 s release). SASS of the round before the stage at b62, predicted → actual: L0 71/71, L1 56/59,
L2 48/51, L3 45/47, L4 39/41 (ALU 45 → 35 → 28 → 24 → 21; b60 69 → 41, b64 64 → 43). MT as
specified did not shrink (NVVM split `(hit & 1)` on right shifts into four 64-bit compares →
level 2 at 60); fixed by holding every digit mask bit-reversed and testing the sign bit of
`hi32(seen << g)`, one funnel shift per digit. The residual +2 per level is a ptxas fallback (from
L1 on it stops proving convergence at the walk's vote/plane barrier: +3 issued per round; cause
not found). Registers 40 → 45 at b60/b62 (45–47 b64), ≤ 48, 5 cubes/SM kept; **some compiles of
the same kernel land on 40 registers with 28–44 B spills** (CubeCL's dynamic shared array hides the
5-cube limit, ptxas aims for 6; which compile spills depends on CubeCL's shared-array order per
process; spilled values are per work item/batch, never in the walk; A/B rounds agree to 0.1–0.6 %).
Exact (levels 3 and 4, timed binary and head): parity incl. b50/b54 + b57 frontier, #240's device
test, certificate test, dense fields, whole b42, 1e14 COMPARE, every screen/A/B field = the exact
counts; lavapipe naga + SPIR-V 8/8; lint 16/0 (JoinKernel b57 constant divisions 36 → 26); fmt,
clippy ×3. RC's clipped path covered by the CPU-reference small windows (a mutant without the range
test fails at b20 [58945,160000) and adds 26 / 5 survivors at b57 / b62 1e14). **Screen (2 rounds,
time / cycles):** L1 ×1.028 / 1.038 b62 1e17, ×1.037 / 1.063 b60; L2 ×1.055 / 1.077, ×1.076 /
1.087; L3 ×1.067 / 1.078, ×1.093 / 1.120; L4 ×1.075 / 1.097, ×1.111 / 1.143; plane-rounds
unchanged (+0.003–0.008 %). **A/B vs 7832f89 (180 W, 3 interleaved rounds): b62 1e17 ×1.086
(109.0 → 100.4 s; cycles ×1.103), b62 1e16 ×1.086 (×1.075), b60 1e16 ×1.122 (×1.126), b64 ×1.070
(×1.104), 1e14 ×1.027/1.017/1.006/0.997 (noise); NiceMark 6 rounds ×1.061 (rounds 1.056–1.063):
b58 weak ×1.070, b58 strong ×1.041 (lowest round ×1.007), b60 ×1.058, b62 ×1.068.** The leaner
round draws more power per cycle: the PR side ran 29–48 MHz slower at the cap (opposite of the
scoping's guess). Not taken: clip words copied to plain shared once per batch (×1.003 / ×1.012,
noise). Box 59373929 destroyed (~4.7 h). → reviewer agent before the PR.

## L42.2 CPU FD top certificates: PR branch (2026-11-06, agent; `L42/PR-RESULTS.md`, `L42/PR-BODY.md`, `L42/raw/pr/`; branch `pr/cpu-join-fd-tops` fba5431 = one commit on main 6f060a9; worktree `.worktrees/pr-cpu-join-fd`)

New `common/src/cpu_top_fd.rs`: five packed digit-array additions per step with trimmed word
counts (14 word adds per step at b60/b62 vs the prototype's 21); seed on a key's first prefix,
after a gap > 4h, or when a walk does not land on P; the seed converts P, P², P³ without a
hardware divide and builds the three difference arrays by shifts/additions; carry test = f64
screen + exact fallback; digit count from a bit-length table; kept tops step `pc`/`dm` by one (no
u128 division except at seeds). `CpuJoin::tops`: unclipped blocks always stepped; clipped blocks
and non-fitting fields keep `Base::cert`. No knobs. **A/B vs main on ivory (Zen 2, AVX2; 3
interleaved rounds, loads ≤ 2):** b60 1e16 partitions ×1.274 (1 thread) / ×1.289 (4); b62 1e17
slice-0 partitions ×1.264 / ×1.246; b60 1e14 whole field ×1.224 / ×1.224; b62 1e14 ×1.155 /
×1.163; counts identical every run (b60 1e14 1,326,103,590 / 84,383,498; b62 1e14 1,470,093,637 /
87,495,922). **NiceMark CPU nice-only (4 rounds, 4 threads, 150 s): score ×1.186 (673.2 → 798.7)**;
b58 weak ×1.141 (1 thread ×1.142), b58 strong ×1.099, b60 weak ×1.336, b62 weak ×1.241. Exact:
new random-run test bases 10–64 (1,860,723 stepped blocks, 243,907 seeds, gaps/backward/clipped:
certificate, `pc`, `dm` = `Base::cert`); new production-field test b42–b64 (3,698,847 tops
identical in order); `check_partitions` now compares tops (windows + opt-in reference,
`NICE_TEST_CPU_JOIN_REF=3`/`16` pass); whole b42 417,789,835 / 16,879,877; `cargo test --release`
183 + 22; fmt; default clippy. → reviewer agent before the PR.

## L43.1 Per-wave base trims: ×1.017 at b62 1e17 → parked (2026-11-06, agent; `L43/RESULTS.md`, `L43/raw/`; branch `exp/join-wave-base` 0e1ba4e on 7832f89, bitmask `NICE_EXP_JOIN_WB`: 1 TT shuffle transpose, 16 TT2 cheaper transpose stage, 2 WH wave-load hoist, 4 AU fixed-trip AND loop, 8 PC `pc` from the bucket kernel)

Screen (one binary, 2 interleaved rounds; time ratio (cycles)): TT ×1.012 (1.026) b62 1e17 /
×1.012 b60; TT2 ×1.013 / ×1.013; WH ×1.015 / ×1.023; **AU ×0.995 / ×1.000** (the AND is bound by
shared loads; cutting ALU there loses ~30 MHz at the cap); **PC ×0.993 / ×0.994** (swaps 16 ALU
instructions for a dependent global load on the latency-bound wave-load chain); all four ×1.018 /
×1.022; **TT2 + WH ×1.023 / ×1.026**. A/B of TT2 + WH vs 7832f89 (180 W, 3 rounds, NiceMark 4):
**b62 1e17 ×1.017** (108.26 → 106.43 s; rounds 1.011/1.024/1.019; cycles ×1.016), b62 1e16 ×1.022,
**b60 ×1.019**, b64 ×1.059 (a b64 split: TT2 ×1.017, WH ×1.013, pair ×1.039 — not investigated),
1e14 ×1.000 / 0.978 / 1.010 (noise), NiceMark ×1.024 (lowest scenario b58 MSD-strong ×0.998).
Against L41's estimates: TT at the top of its 0–1.7 s range (−1.3 to −1.4 s); WH −1.6 s vs −0.4 s
from instruction count (the list→entry latency L39 suspected is real). **Parked: below the 3 %
kill line.** Exact with all four on (WB=31) and with WB=15: parity incl. b50/b54, #240's device
test (237.9 M tops), certificate test, dense b58/b62, whole b42, 1e14 COMPARE, every timed
field = L38's counts; lavapipe naga + SPIR-V 7/7 (TT falls back on 8-lane subgroups); lint 16/0;
fmt/clippy ×3. AU's invariant (every listed entry's mask has exactly 2k digits, key level or not)
holds by construction (§1). Registers: WB=0 40; 15/31 46; WH alone 47–48; AU 48; TT/TT2 40 +
12 B spills; **WB=19 40 + 8 B spills (the work-item index `w`)** — fails the no-spill gate as
written; AU fully unrolled took 64 registers (replaced). Direct SPIR-V JoinKernel 133–136 →
136–139 blocks. Box 2.9 h.

## L42.1 CPU join profile on ivory, and FD top certificates on the CPU (2026-11-06, agent; `L42/SCOPING.md`, `L42/raw/`; worktree `.worktrees/l42-cpu-join-prof`, scratch prototype `l42_fd.rs`, uncommitted)

Ivory = Zen 2 (EPYC Rome) VM, 4 vCPUs, AVX2 only (`scan_avx2`); ~25 idle CLI processes (load
0.5–1.2). Release build of `nice_client`, default features, no GPU deps: 2 min 09 s, 545 MB target.
Phase split (rdtsc counters on a scratch branch + `perf` + the pristine NiceMark run, score 665;
same within 0.3 points at 1 and 4 threads): **production shapes (b60 1e16, b62 1e16, b62 1e17
slices): top certificates 42–43 %, AND scan + survivors ~55 % (scan 28–29, prefilter 17–18, full
check 8–9), extend + lists ~1 %, sort ~1 %**; b60 1e14: 35 / 36 / 7+22 / 1; b62 1e14: 27 / 33 /
9+30 / 1. `Base::cert` + `divrem_w4` = 40.5 % of the join; 57 % of `Base::cert`'s samples sit on
two hardware `div`s in `digits_w` (per-digit `% b`, `/ b` with a runtime base). ~12 % of cycles are
branch mispredictions (survivor extraction, prefilter early exits). **FD top certificates:** `tops()`
visits a key's prefixes in ascending order within a partition → consecutive P differ by h = b³,
#240's five digit-array adds step in h; gaps ≤ 4 stepped, larger seed (2.3–4.7 % of slots).
Certificate alone ×1.6–1.8 vs `Base::cert`; **in place, whole partitions, interleaved 2 rounds: FD
×1.10–1.20 at production shapes (mean ×1.16) at 1 and 4 threads; FD + L41's lean prefilter
×1.23–1.29 (mean ×1.26).** Exact: FD cert = `Base::cert` on ~19 M slots (b60/62/64); whole b60 and
b62 1e14 fields with a per-slot self-check → identical survivor/checked counts; `cpu_join` tests,
the opt-in production-field reference test (b42–b64) and whole b42 (417,789,835 / 16,879,877) pass.
Point 4: the CPU join has #215's prune (`FieldSetup::fc`, `prune_bottoms`; cuts bottoms 43–65 %);
no transpose benefit (AND arithmetic 0.3 of ~2.3 cycles per AND; a bit-sliced version ≤ ~4 %);
the survivor prefilter is `walk_pf`'s arithmetic: FX+MT+GM port directly, ×1.05–1.08 alone, exact;
RC ×1.00 (drop). Caveat: Zen 3/4 (Anvil, demoux) divide faster → smaller share and gain there;
AVX-512 makes the scan cheaper → share back up. → PR agent launched (`L42/PR-BRIEF.md`).

## L40.1 Group walk over the AND group's 8 pass words: ×1.056 at b62 1e17 but b58 MSD-strong ×0.963 → parked (2026-11-05, agent; `L40/RESULTS.md`, `L40/raw/`; branch `pr/join-group-walk` f8a27cc = one commit on af21136 (#241) with a `#NNN` CHANGELOG line; variants `exp/join-group-walk-{p1,linear,f,h,h2,f2}`, counters `exp/join-rounds-base`, `exp/join-group-walk-rounds`)

Head kernel = H2 (first word picked before the walk). RTX 3080 at 150 W, 3 interleaved rounds vs
af21136: **b62 1e17 ×1.056** (1.058/1.054/1.058; clock-normalised ×1.120), b62 1e16 ×1.065
(×1.081), **b60 1e16 ×1.074** (×1.104), b64 ×1.050 (×1.059); **1e14 b57/60/62/64 ×0.955/0.970/
0.969/0.963**; NiceMark (6 rounds) ×1.030: MSD-weak b58 ×1.062, b60 ×1.045, b62 ×1.051, **MSD-strong
×0.963** → fails "no scenario < ×0.98". The PR side runs 40–60 MHz lower at the cap (more ALU work),
hence the higher clock-normalised ratios. Counters: rounds per group 23.97 → 15.48 (×0.65) at b62
1e17, 32.7 → 19–20 (×0.61) at b60; lane utilisation 24.9 → 38.5 % (23.5 → 38.5 %); less than the
predicted half because lanes are uneven (a plane runs 2.4× a lane's mean bits; Poisson would give
1.9×). Round body 139 SASS vs 110 (19 = the word pick, only when a lane needs a new word). The
residue test stays (clipped tops' ranges are invisible to the AND; it rejects a few pairs per field
at the edges). **Small batches (< 192 tops) save no rounds** (plane-rounds identical to the base at
b57/b62 1e14), so the extra body cost is pure loss there; variants: P (group walk everywhere) MSD-
strong ×0.959; F (base walk for small batches) 40 regs + 20 B spills, ×0.935; H (one chunk per pass)
×0.975 screen; H2 ×0.991 screen / ×0.963 A/B; F2 (L37's mode-2 loop for small batches) ×1.020
screen / ×0.964 over 6 A/B rounds, spills. MSD-strong swings ±4 % between sessions on one binary →
only A/B rounds count. Exact everywhere (parity incl. b50/b54, #240's device test, certificate test,
dense, b42, 1e14 COMPARE; lavapipe naga + SPIR-V 7 tests, no overflow; lint 16/0; fmt/clippy ×3;
P and F2 too). Registers 46–47, no spills (base 40); 5 cubes/SM (shared-bound). **Parked:** next
try = a higher gate for the group walk with MSD-strong measured over ≥ 6 rounds from the start, and
a SASS look at the work-item/wave code rather than the walk. Box 4.6 h.

## L39.1 One record per bottom entry: neutral, closed (2026-11-05, agent; `L39/RESULTS.md`, `L39/raw/`; branches on af21136: `pr/join-bottom-record` 08c9d90 (= F), `exp/join-bottom-record-r8` 746a1fc (E), `exp/join-bottom-record-r4` 72d1b85 (F), `exp/join-entry-sectors` c27c3ce (sector-count test))

E = 32-byte record per (slot, entry) with mask, q0, q1, r0 (+3 pad; `bp_r` leaves the join; +16 B
per slot-entry); F = 16-byte record (mask, q0, q1) beside `bp_r` (same bytes as before; r0 needs
18 bits and the 16 bytes have 10 free). **Sectors per entry measured on the production bucket
lists** (a warp's 32 lanes span ~1,000 class entries): base 2.50–2.54, E 1.00, F 1.71–1.73.
Screen E / F vs af21136 at b62 1e17 / b62 1e16 / b60 1e16: E ×0.982 / 0.999 / 0.995 (slightly
slower everywhere: doubled bytes), F ×0.997 / 1.015 / 1.004. **A/B of F vs af21136** (RTX 3080 at
its default 320 W, still `SW power cap` throttled; 3 interleaved rounds; both sides 1880–1892 MHz):
b62 1e17 ×0.997 (86.78 → 87.07 s), b62 1e16 ×1.004, b60 ×1.006, b64 ×1.003, 1e14 noise, NiceMark
×1.009 (no scenario < ×0.98). **Below the bar; closed.** Why: cutting the entry gather's sectors by
32 % (F) or 60 % (E) does not move field time, so in the full kernel the entry gather is not
sector-bound: the entry arrays are 9–14 MiB per launch and `bp_r` 0.4 MiB (the top arrays #241
fixed were ~250 MB each); L37's 10.5 s for "entry loads" came from a stripped kernel with an exposed
dependent load chain (list → entry) that the other cubes' AND/walk work hides in the full kernel.
**Lesson for the ablation method: a part's cost in a stripped kernel is an upper bound; latency-
bound parts shrink when the rest of the kernel is present.** Exact on the full list (parity incl.
b50/b54, #240's device test 24 fields / 259 batches / 309.9 M tops on this card's plans, certificate
test, dense, b42, 1e14 COMPARE, every field = the exact counts, NiceMark join survivors; lavapipe
naga + SPIR-V 7 tests; lint 16/0; fmt; clippy ×3). Registers unchanged (join 40; bucket 40/39/40
vs 40/39/38). Box 2.0 h.

## L38.1 One 32-byte record per top: PR #241 (2026-11-04, agent; `L38/RESULTS.md`, `L38/PR-BODY.md`, `L38/raw/`; branch `pr/join-top-record` af21136 = one commit on main 6f060a9, +64/−87 in cubecl_join.rs + join_plan.rs; prototypes `exp/join-top-record-scalar`, `exp/join-top-record-vec`)

`top_p`/`top_m`/`top_r`/`top_x` → one `top_rec` of 8 u32 per top (`TOP_REC_WORDS`); both top kernels
(incl. the clipped launch) write it; the join's batch load reads words 2–7 from one sector;
`check_kernel`, `read_checked`, `v_part` and #240's device test read it; `top_b` and the shared
layout unchanged; the footprint counts one buffer (largest per-slot buffer now, but cannot bind
before the survivor bound: plans identical both sides). Scalar loads tied with `Vector<u32,4>`
loads (kept scalar: 40 vs 44 registers). **A/B vs main, RTX 3080 at a 180 W cap, 3 interleaved
rounds, medians:** b62 1e17 120.37 → 109.46 s **×1.100** (rounds 1.100/1.100/1.075; clock-
normalised ×1.034); b62 1e16 ×1.076 (×1.057); b60 1e16 ×1.060 (×1.029); b64 1e16 ×1.091
(×1.060); 1e14 b60/b62/b64 ×0.977/0.990/1.021 (noise ±3–7 %); **NiceMark ×1.050** (1.051, 1.049;
b58 weak ×1.036, strong ×1.012, b60 ×1.070, b62 ×1.083). The PR side ran 35–75 MHz higher at the
cap (fewer sectors → less power → more clock), so in cycles the saving is 4.3 % at b62 1e17 (10.9 s
in time vs L37's 12–16 s estimate); on an uncapped card expect between the columns. Top kernels
alone unchanged (±0.8 %). **Exact** on `a9495ec` and `6539b9e`: parity incl. b50/b54, #240's device
test on the record (26 fields, 279 batches, 237.9 M tops), certificate test, dense fields, b42,
1e14 COMPARE = main, every A/B field = main's exact counts, NiceMark whole-field scenarios;
lavapipe naga + SPIR-V all `cubecl_join` wgpu tests; lint 16/0; fmt; clippy default, gpu, gpu +
cubecl-spirv. Registers = main (join 40, top 80, top_fd 108/110, check 38/34; b64 variance is
CubeCL's). **PR #241 opened 11:20 UTC.** Incidents: GitHub refused SSH pushes from ivory 09:47–
09:57 (HTTPS 500s too; the commit travelled as a bundle and was pushed with gh's token); the agent
once ran `git push --force` against upstream by mistake — refused (no push access), upstream main
untouched (6f060a9, no push event).

## L37.1 Join kernel breakdown on main 6f060a9 by ablation (2026-11-04, agent; `L37/RESULTS.md` §1, `L37/raw/`; branch `exp/join-l37-ablate` 64f986c, switches `NICE_EXP_JOIN_ABL`, `NICE_EXP_JOIN_TMIN`)

RTX 3080 at 150 W, each mode a separate profiled kernel, 3 interleaved rounds; each part = the
extra cost of adding it to the previous mode. b62 1e17 (129.7 s field, join 72.4 s), b60 1e16 in
brackets (15.2 of 25.7 s):
| part | s/field | % of join | % of field |
|---|---|---|---|
| base: top batch gather into shared, entry loads + prefilter terms, transposed copy, per-chunk checks | 29.7 (5.7) | 41.0 (37.9) | 22.9 (22.4) |
| AND (transposed digit ORs) | 3.7 (0.7) | 5.1 (4.4) | 2.8 (2.6) |
| walk (rounds, bit pops, residue test) | 11.3 (2.3) | 15.6 (15.5) | 8.7 (9.1) |
| prefilter `walk_pf` | 24.2 (5.7) | 33.4 (37.6) | 18.6 (22.2) |
| stage + flush | 3.6 (0.7) | 4.9 (4.7) | 2.7 (2.7) |
**The AND is 5 % of the join (0–2 % clock-corrected); survivor handling is 54 % of the join = 30 %
of the field.** Walk lane utilisation 24.8 % (b60 23.5 %): 1.28e11 plane-rounds per field, 3.36 per
(plane, slot, chunk) (4.45 at b60); 0.84 pass bits per lane-chunk (1.29 per lane with an entry);
`walk_pf` ≈ 52 SASS instructions ≈ 16 SM-cycles per round. **The residue test never rejects in
production** (pass bits = in-range survivors to within 4 of 1.02e12). #239 on main: per-top AND
back = +12.5 s of join → #239 is ×1.095 on the field (×1.072 b60). **Inside the base: gathering
each batch's tops into shared is 18.6 s = 26 % of the join = 14 % of the field; `tl` 0.35 s, `top_m`
2.5 s, `top_r` + `top_x` 15.7 s** (random 2-word reads from separate arrays: 3–4 sectors per top,
7.6e10 top loads per field). Entry loads + prefilter terms 10.5 s (14 %); transposed copy, barriers,
work items, atomics ~1 s; stage-check cadence (4 vs 8 chunks) no reliable difference.

## L37.2 H1 walk compaction and H2 shuffle register LUT: exact, slower, killed (2026-11-04, agent; `L37/RESULTS.md` §2–3; branches `exp/join-walk-compact` 77241bc (`NICE_EXP_JOIN_COMPACT`), `exp/join-shfl-lut` 449f793 (`NICE_EXP_JOIN_SHFL`))

H1 (`COMPACT=1`, warp prefix sums + shuffles, every lane tests a survivor): b62 1e17 ×0.940, b62
1e16 ×0.937, b60 ×0.962, b64 ×0.912, NiceMark ×0.923 (MSD-strong ×0.834); 48 registers + 32 B
spills, SASS 1480 vs 1088. Exact on the full list (CPU reference incl. b50/b54, dense, b42, 1e14
COMPARE, every A/B field; lavapipe naga + SPIR-V with 8-lane subgroups; lint 0; wgpu supports the
shuffles). Why: at this density compaction only cuts a plane-slot from ~4.1 rounds to ~1.9; the
round body is 172 SASS vs 110 with 12 shuffles; ~50 instructions of CubeCL prefix-sum loop per
slot-chunk even with no bits; ×1.01–1.08 in SM cycles but 70–135 MHz lower clock at 150 W → loses
in wall time. **`COMPACT=2`** (one walk per lane over both entry slots, no shuffles, 45 registers):
exact; b62 1e17 ×1.015, b62 1e16 ×1.014, b60 ×1.026, b64 ×1.012, NiceMark ×1.017 (b60 MSD-weak
×0.982), 1e14 ×0.99–1.02 → real, under the bar, parked. H2 (register LUT, one shuffle per digit):
b62 1e17 ×0.953, b60 ×0.969, b62 1e16 ×0.976; AND-only ablation ×0.909–0.919; 47 registers; same
or higher clock; exact. Why: shuffles use the same pipeline as the shared loads at the same rate,
the two plane-wide loops run more rounds than the per-lane loop, and the AND was 5 % of the join.
**Next brief (L38): one 32-byte record per top** (est. 12–16 s per b62 1e17 field, 9–12 %).

## T1 Demoux telemetry on the merged stack (2026-11-04, director; data.nicenumbers.net PostgREST, read-only; raw JSON in `TELEMETRY/`)

demoux (RX 9070 XT, RADV GFX1201, wgpu<spirv>; Ryzen 5 5600X, threads 4, 2 fields in flight) has run
build 6f060a9 (3.4.8-dev = main with #235–#240) since 2026-11-03 10:47 -05:00; 1,842 b60 1e16
fields with survivors by 00:47 -05:00 on 11-04, 0 disqualified, 0 numbers found. Per-field
processing time (median, telemetry `processing_secs`; rate = 1e16 / proc):
| build | n | proc s | elapsed s | numbers/s |
|---|---|---|---|---|
| 3.4.7-dev 8c088a2 (10-30) | 153 | 29.8 | 85.6 | 3.36e14 |
| 3.4.7-dev 18cba8b (10-30) | 107 | 31.3 | 88.7 | 3.19e14 |
| 3.4.8-dev 9bde4a8 (11-03, pre-stack main) | 97 | 32.2 | 92.7 | 3.10e14 |
| **3.4.8-dev 6f060a9 (the stack)** | 1842 | **14.2** | **39.6** | **7.05e14** |
**×2.27 per field on AMD** vs the pre-stack main (×2.1–2.3 vs the October builds), above the 3080's
×1.80 at b60 1e16 (L36.1). Zero-work submissions: 160 of 1,000 recent (and 61 of 700 earlier)
come in bursts of ~50 within two seconds (13:47, 22:15, 23:32, 00:33) with `launches 0`,
`survivors 0`, `slots 16`, processing ~0.1 s. **Explained, not a defect:** 149/160 have a repeated
digit in the field's own certificate (common leading digits of start^k and (end−1)^k, k = 2, 3;
0/840 normal fields do); the other 11 are eliminated range by range — the per-range certificate
leaves 0–2 of their 7,200 sub-ranges live (a normal field: 5,209), and the client's deeper MSD
interval analysis takes the rest (one of them launched 225 times and found nothing). The same
bursts appear on mayalaran (5/288), the fleet's 3.4.7 (3060 5/347, 4060 55/365) and demoux's 10-30
build (80/233): they are consecutive impossible fields, pre-existing behaviour. The fields'
`canon_submission_id` is None for new fields of both kinds (set later by the server).

## L36.1 The five open PRs on one tree vs main, and the profile after them (2026-11-03, agent; `L36/RESULTS.md`, `L36/raw/`; branch `exp/join-all5` 6ddab24 = exp/join-all3 + #240 c7ef3c8 + #239 775b6d9, CHANGELOG-only conflicts, cubecl_join.rs auto-merged = union of the two diffs)

RTX 3080 on machine m137673 **capped at 150 W** (not the 180 W of L29–L35: absolute seconds
not comparable, ratios are; clock wandered ~10 % per binary over the session). main 04693ac vs
all5, 3 interleaved rounds, medians of device s/field:
| field | main → all5 | ratio | product of per-PR ratios |
|---|---|---|---|
| **b62 1e17** | 280.24 → 148.92 | **×1.882** | ×1.843 |
| b62 1e16 | 23.01 → 11.77 | ×1.955 | ×1.790 |
| b60 1e16 | 52.65 → 29.22 | ×1.802 | ×1.760 |
| b64 1e16 | 64.93 → 41.85 | ×1.552 | ×1.560 |
| NiceMark | 3108.8 → 4991.8 | ×1.606 | ×1.625 |
Every round of every field faster (×1.55–1.97); spreads all5 0.1–0.6 % (b60 5.3 %), main
0.9–2.8 %. all5 ran at a lower clock than main (1074 vs 1162 MHz) → ×1.882 is conservative;
clock-normalised ×2.04; a late pair at similar clocks ×1.962 (140.1 vs 274.9 s). #240 gains more
at 150 W (top kernel ×1.70–1.74 vs ×1.585 at 180 W). **Exact:** CUDA parity incl. b50/b54, #240's
device test, #235's certificate test, both dense fields, whole b42; 1e14 COMPARE = main = the PR
bodies; whole-field counts = all3's exact counts every round; lavapipe naga + SPIR-V parity; lint
16 shaders 0 flagged. **Profile all5 b62 1e17** (main on the same box in brackets): top 29.7 %
(42.5; 116.5 → 40.6 s, ×2.87), bucket 1.9 % (0.9), **join 56.1 %** (50.4; 138.2 → 76.7 s, ×1.80),
check 8.2 % (4.1), other 4.1 % (2.0). b60 1e16: top 24.3 % (34.7), join 59.7 % (56.6), check 9.8 %.
The timers cannot split the join into AND and walk.

## L36.2 What a stepped top-kernel slot still pays for, and three exact trims (2026-11-03, agent; `L36/SCOPING.md`, `L36/raw/abl_*.txt`; branch `exp/top-fd-ablate` 47c1b36 on all5)

Stepped slot 0.219 ns per prefix at b62 1e17, 0.212 at b60 (150 W box). Ablation (9 rounds each),
share of the slot (b62 / b60): digit scan 32.5 / 29.9 % (per-digit c0 test and selects 19, run-of-
(b−1)s bookkeeping 14.5, the digit/bit work 6); append 17; carry test 14 (one cost with x mod
b^c0: 13); step 13 (registers 110 → 80 without it); ndig_fast power-table compare 6; carry test +
ndig together 22.5; floor with all six removed 30. In sequence without double counting: append 17,
scan 22, carry+ndig 22, step 8, floor 31. **Skipping the scan when the digits above c0 did not
change cannot work:** per lane they change on 35 % of steps at b62 (4 % at b60) and c0 never
changed in 1.1e9 stepped lanes, but a warp must scan if any lane needs it: 99.6 % of warp-slots at
b62 (85 % at b60). SWAR distinctness and fusing the two scans do not help (the cost is
bookkeeping). **No single change reaches 25 %.** Three exact trims prototyped behind switches:
carry c0 and b^c0 − d across steps (no power-table reads per step) −14.4 / −14.3 %; a
bookkeeping-free path for scanned words wholly above c0 −6.7 / −5.5 %; stepping slots skip forming
a, e and the clip test −2.5 / −1.8 %; **all three −22.3 / −22.9 % of the slot (0.218 → 0.170 ns)
= ×1.041 at b62 1e17 (139.7 → 134.3 s), ~×1.04 b60, exact counts**; pass #240's device test on
CUDA and lavapipe (naga + SPIR-V; blocks 298–310 → 325–343). **Parked: below the bar** (worth
~2 % from the c0 carry alone); the FD kernel is now ~20 % of a b62 1e17 field, the join 56 %.

## L35.2 PR #240: `pr/top-fd` on #237 (2026-11-02, agent; `L35/RESULTS.md` §12, `L35/PR-BODY.md`, `L35/raw/pr-box/`, `raw/analysis_pr.txt`; head c7ef3c8 = one commit on 51410e7, +1495/−169 in cubecl_join.rs)

One FD path (the measured mode, binary d2/d3 stepping); constants `TOP_FD_MIN_UNITS = 2^17`
(slot grouping for small top layers), `TOP_FD_AT_POW2_BASES = false`; `top_kernel` kept for
excluded bases and clipped blocks (`only_clipped`, compiled at device creation); ignored timing
test `cubecl_cuda_top_fd_timing` (env `NICE_TEST_TOPFD_TIMING`, like the other test harnesses).
**Final A/B vs #237 alone** (RTX 3080 180 W, interleaved, medians of 2 rounds; SM 1399–1434 MHz
#237 / 1417–1442 PR):
| field | #237 → PR s/field | ratio | per round |
|---|---|---|---|
| b62 1e17 | 182.3 → 168.8 | **×1.080** | 1.081, 1.078 |
| b62 1e16 | 15.31 → 13.72 | **×1.116** | 1.120, 1.112 |
| b60 1e16 | 36.01 → 33.82 | **×1.065** | 1.061, 1.068 |
| b58 1e16 | 57.42 → 55.03 | ×1.043 | 1.058, 1.029 |
| b64 1e16 (FD off) | 51.23 → 51.14 | ×1.002 | 1.036, 0.968 |
| NiceMark | 4415 → 4431 | ×1.004 | 1.014, 0.993 |
Clock-normalised b62 1e17 ×1.059. **Smaller than on the #235+#236+#237 tree (×1.143 / ×1.136 /
×1.084): 13.5 s saved per b62 1e17 field vs 18.3 s there; the agent did not profile why** (part
of the top kernel's time hides behind the slower join without #236?). Kernel alone on the PR
branch: b62 0.366 → 0.229 ns per prefix-slot (×1.585), b60 ×1.483, b58 ×1.605; a stepped
partition 0.190–0.198 ns. **Counts at 1e16/1e17 are not run-to-run identical on this base** (#235's
timing-dependent stage overrun, removed by #236; both sides vary by a few ppm; found 0 everywhere;
1e14 COMPARE identical to the digit; on the #236 tree every count identical). Exact: new device
test (26 fields, 279 batches, 23 clipped, 237.9 M tops; lavapipe naga + SPIR-V 21 fields),
certificate test = #235's counts, join parity CUDA + lavapipe ×2, dense b58/b62, whole b42, lint
16 shaders 0 flagged (TopKernel@57 still compiled), fmt/clippy. Registers 108–110, no spills,
2 blocks of 256 per SM; direct SPIR-V 298–310 blocks (< TopKernel's 368–386). **PR #240 opened
11:55 UTC**, stacked on #237 (on #235); the body explains the NiceMark neutrality (bit-reversed
partition samples seed every slot) and justifies on whole-field runs. Open program PRs = 5.

## L34.2 Gate screen and PR #239 (2026-11-02, agent; `L34/RESULTS.md` §11–12, `L34/PR-BODY.md`, `L34/raw/`; branch `pr/join-transpose-and` 775b6d9 on #236 fb05597)

Gate screen on #235–#237 (hybrid fcd6581, G=4, 2 interleaved rounds): MIN=128 / **192** / 256 →
b62 1e17 — / ×1.074 / ×1.065; b62 1e16 ×1.092 / ×1.063 / ×1.080; b60 1e16 — / ×1.078 / ×1.065;
b64 1e16 — / ×1.173 / ×1.149; 1e14 b60/b62/b64 ×0.989/0.953/0.970 / ×0.979/0.934/0.944 /
×0.963/0.939/0.970; NiceMark ×1.085 / ×1.107 / ×1.075; b58 MSD-strong ×0.992 / ×1.023 / ×0.999.
Any gate fixes the NiceMark small-bucket case; **no gate fixes 1e14 (×0.93–0.98), even 256 which
transposes nothing there: the cost is the kernel's footprint** (2 KiB shared → 5 cubes/SM instead
of 6, plus one barrier per batch). PR branch: one commit on fb05597, `TRANSPOSE_MIN = 192`,
`AND_GROUP = 4`, no knobs; cherry-picks clean, applies on exp/join-all3 too (CHANGELOG only).
**A/B on #236 alone:** b62 1e17 ×1.055 (183.9 → 174.3 s), b62 1e16 ×1.050, b60 ×1.062, b64 ×1.176,
1e14 b60/b62/b64 ×0.978/0.959/0.975, NiceMark ×1.075 (MSD-strong ×1.017); counts identical;
clocks within 1.3 % at 178–180 W. Registers 40 (= base), 0 spills, SASS 784 → 1,088, shared
14,344 → 16,392 B. Exact at the head: parity incl. b50/b54, dense fields, whole b42 (also all with
`TRANSPOSE_MIN = 0`), 1e14 COMPARE = #236, lavapipe naga + SPIR-V (133–136 blocks), lint 0
flagged, fmt/clippy clean. **PR #239 opened 10:40 UTC** (stacked on #236; the 1e14 caveat is in
the body). Not taken: survivors' top ids from `tl` frees 1 KiB shared but costs 45 registers
(still 5 cubes/SM; 1e14 results mixed).

## L35.1 Top kernel by finite differences across a batch's partitions: prototype A/B (2026-11-02, agent; `L35/DESIGN.md`, `L35/RESULTS.md`, `L35/raw/`; branch `exp/top-fd` fd58370 on `exp/join-all3` 0f1a8a7; switch `NICE_EXP_TOP_FD` = 0/1/2)

An unclipped block a = P·b^f0 has a^k = P^k·b^(k·f0): a², a³ are P², P³ shifted with zeros
below, and consecutive partitions are consecutive P, so the kernel keeps the detailed FD's five
packed digit arrays for n = P (23 words at b62 1e17) and steps them by additions; long division
only when a slot seeds (first slot of a batch, or after a gap); the two clipped partitions per
slice go to the old `top_kernel` (`only_clipped`). Production batches are `chunks(0..nparts)`:
consecutive; only P = plo / phi clip. Mode 2 (measured) also steps d2/d3 in binary.
RTX 3080 180 W, interleaved, medians, FD off → FD=2 (binary F 3574f0f):
| field | ratio | per round | s/field |
|---|---|---|---|
| b62 1e17 (5 rounds) | **×1.143** | 1.134–1.154 | 146.1 → 127.8 |
| b62 1e16 (3) | **×1.136** | 1.127–1.143 | 12.23 → 10.76 |
| b60 1e16 (3) | **×1.084** | 1.084–1.095 | 27.40 → 25.27 |
| b64 1e16 (3) | ×0.985 | 0.972–1.011 | → FD off at power-of-two bases (2111f09) |
Head H (post-A/B fixes): b62 1e17 ×1.129 (3 rounds), b62 1e16 ×1.135, b60 ×1.101. Kernel alone:
b62 1e17 0.363 → 0.229 ns per prefix-slot (×1.59), b60 0.333 → 0.226 (×1.47); a stepped slot
0.198 ns at b62 (×1.83 vs top_kernel), a seeded slot 0.350 (the seed is 31–36 % of the FD kernel);
the step's additions are unmeasurably small — what remains is the two certificate scans, the
remainder, the carry tests and the append (one atomic per plane). **NiceMark ×1.000** (rounds
1.015/0.999/1.014) after 6c8db87 compiles the clipped-block kernel at setup (before: ×0.93, all
from b58 MSD-weak ×0.72 = JIT compile inside the timed sample); NiceMark samples partitions in
bit-reversed order, so every slot seeds there and it cannot see the stepping gain. 2111f09 also
splits a batch's slots into groups when the top layer is under 2^17 prefixes: b62 1e14 ×1.16 →
×1.33, b57 1e14 ×1.38 → ×1.42. Registers (ptxas sm_86, no spills): top_kernel 80, FD mode 1 80,
mode 2 109–111 (2 blocks of 256 per SM instead of 3); cube size 64–256 no difference; direct
SPIR-V TopFdKernel 304–316 blocks vs TopKernel 368–386. **Exact:** new device test (both kernels
on the same batches: per-slot counts, bucket counts, sorted entries equal; 26 fields, 279 batches
incl. gaps, a backwards step, 23 clipped, 237.9 M tops on CUDA; lighter on lavapipe naga +
SPIR-V); certificate test = #235's counts; join parity FD=1/2 incl. SPIR-V; dense b58/b62,
whole b42, 1e14 COMPARE b57/60/62/64 identical; lint 0 flagged. Not run on Metal (seed = #237's
trimmed division; step/scan only add, shift, mask). Persistence across batches (not built):
≈ ×1.18 b62 1e17 / ×1.11 b60 at 192 B per prefix (~695 MB per b62 1e17 slice; plan budgeting).
Dead end on the way: binary-d stepping at 160 registers was slower; the real cap was a
same-address atomic the compiler only aggregates in `top_kernel`. Follow-up L35.2: PR branch
`pr/top-fd` on #237, final A/B incl. b58 1e16.

## L34.1 Digit-transposed AND in the join kernel: prototype A/B (2026-11-02, agent; `L34/RESULTS.md`, `L34/raw/`; branch `exp/join-transpose` 432b795 on `exp/join-all3` 0f1a8a7; switch `NICE_EXP_JOIN_TRANSPOSE=1`, `_G` chunks per digit pass, hybrid gate `_MIN`)

RTX 3080 (180 W cap), 3 interleaved rounds, medians, every round faster; A = `exp/join-all3`
(main 04693ac + #235 + #236 + #237), B = switch on, G = 4.
| field | plain, G=4 | hybrid MIN=128 (2 rounds) |
|---|---|---|
| b62 1e17 | ×1.063 (143.17 → 134.73 s) | ×1.075 |
| b62 1e16 | ×1.075 (12.16 → 11.32) | ×1.086 |
| b60 1e16 | ×1.064 (27.08 → 25.46) | ×1.065 |
| b64 1e16 | ×1.140 (38.44 → 33.72) | ×1.129 |
| 1e14 fields | ×0.83–0.92 (3.2 tops per bucket at b62) | ×0.96–0.99 |
| NiceMark | ×1.049 (5538.6 → 5810.8); b58 MSD-strong ×0.90 | ×1.085; b58 MSD-strong ×0.98 |
Join phase −12.5 % at b62 1e17 (75.3 → 65.9 s), −11.9 % at b60; no other phase moved. Against
L1.7's split the AND got only ~×1.3 cheaper, not 2–4×: each digit load is a gather with ~2-way
bank conflicts (d and d+32), so shared-memory wavefronts drop ~25 % (64 → ~48 per warp per 32
tops) while ALU work drops ~3× — the per-top AND is bound by shared loads, not ALU. Building the
transposed copy costs 1.4 % of the field on its own. G=4 beat G=8 (brief's order A) by 0.5–3.4 %
and G=1 (order B) gained nothing. Registers: base 40 (6 cubes/SM); G=4 56 (4/SM; +2 KiB shared
alone caps at 5); hybrid 44 (5/SM). Direct-SPIR-V JoinKernel 109–112 → 123–126 blocks, no
overflow. **Exact everywhere:** CPU-reference parity incl. b50/b54, both dense fields, whole b42,
1e14 counts at b57/60/62/64 identical, every A/B count identical, lavapipe naga + SPIR-V, lint
0 flagged, fmt/clippy clean. **Baseline profile after #237** (b62 1e17, 140.1 s profiled): top
34.6 %, bucket 1.7 %, join 52.8 %, check 6.5 %, other 4.4 %; b60 1e16 join 57.7 %.
Follow-up (L34.2): gate at MIN=256 (full top batches only) / 192, then a PR branch on #236.

## L3.2 GPU detailed finite differences and the readback fix, protocol on a default-power 3080 (2026-10-30, agent; `L3/PR-RESULTS-3080.md`, `L3/pr-raw/3080/`; PRs #224 readback, #225 FD)

RTX 3080 20 GB (58401551, US), power limit 320 W = default = enforced = max; both kernels hit
it (~318 W): division kernel 1755–1770 MHz, FD 1860–1890 MHz (×1.07 clock). `auto` = CubeCL
CUDA. NiceMark detailed GPU, 150 s, A B C × 3:

| | main | readback (rb) | FD | FD/rb | FD/main |
|---|---|---|---|---|---|
| b40_detailed | 1.018e10 | 1.108e10 (+8.8 %) | 3.352e10 | 3.03× | 3.29× |
| b50_detailed | 7.512e9 | 8.052e9 (+7.2 %) | 2.978e10 | 3.70× | 3.96× |
| detailed GPU score | 4609 | 4986 | 16624 | 3.33× | 3.61× |

2e9 windows: FD/rb 3.09× (b40), 3.60× (b50). One 1e10 field (the new server cap, #223): b50
1.218 s → 0.325 s (3.75×), b52 1.288 → 0.333 s (3.86×); the readback fix is nothing at that
size. Per clock FD/rb ≈ 2.8× (b40), 3.5× (b50), same as the capped card yesterday.
Exactness: all CUDA FD tests; main vs FD identical on 100 windows across every base 10–64
(8.6e9 numbers, 261 near-misses); bases 10–28 in full (73 near-misses). Portability: wgpu uses
a 32-bit split seed (no u64 in WGSL); lavapipe passes via naga WGSL and CubeCL SPIR-V, also
`NICE_CUBECL_WIDE=1`; all 19 CI lavapipe tests pass; Metal translated by naga 29.0.4, no Mac
(the macOS CI job is the first real run); HIP not built. Branch heads: readback 6a1e396
(CubeCL `offset_end` read of `count` records, hand-CUDA slices its copy; 3 tests), FD f3a33cf
(`common/src/cubecl_detailed_fd.rs`, FD_RUN_LEN 128, all of bases 10–64's legal ranges;
division kernel kept above 64 and as reference). 4090 numbers pending (agent running).

## L8.1 Near-miss tail test of the probability model (2026-11-01, agent; `L8/RESULTS.md`, `L8/models.py` etc., `L8/data/`)

Exact detailed histograms for bases 12–49 + base 50's 24 % sample (~1.1e9 numbers in the top 7
bins; brute-force recount of b20/22/24 matches the API). **Near tail (3–6 missing digits): the
project's model applied at every depth fits within 2–3 % (pooled 0.97–0.98); the plain iid model is
13 % high** (so dropping August's ×0.846 was right). **A leading-digit factor is missing from λ**:
the top digits of n² and n³ are both set by n's top digits; adding the top digit of each power
brings depths 3–6 to 0.99–1.00 and explains the per-base scatter (χ² 3,890 → 156 over 25 bases;
correlation 0.91); at k = b it is 0.86–1.06 per base; folding it in moves today's 5.45 % to 5.34 %
(ahead: b60 ×0.99, b62 ×0.91, b64 ×1.02). **Two missing digits: 512 observed vs 582 expected, ratio
0.88 [0.81–0.96]**, even across bases but mostly from the bases that flagged it in August; the bases
added since give 0.96 [0.82–1.12]; no arithmetic cause found. One/zero missing: 7 vs 5.7, 0 vs 0.05.
**For the cost model:** the correction at k = b is ~0.67–1.0 (0.53–1.14 with CIs); today's 5.45 %
→ **~4.7 % best guess (3.7–5.3 %)**; nothing shows under-prediction; costs and search order
unchanged; METHODOLOGY's "the tail is untested" → "tested to two missing digits; may be up to
~1.5× optimistic"; 77 % of today's odds come from bases 12–25. Per-base factors: `L8/data/top_factor.csv`.
Proposed (needs the user's OK: it changes the published headline): add the leading-digit factor to
`scratchpad/2026-08-cost-probability/build.py` and the METHODOLOGY note.

## L9.1 H100 SXM and L40S on the join and detailed mode (2026-11-01, agent; `L9/RESULTS.md`, `L9/raw/`)

Upstream main fae7398, `auto` = CubeCL CUDA; nothing uploaded. Both host-capped (H100 500 of 700 W,
~1.6 GHz; L40S 300 of 350 W, ~2.15 GHz), no thermal limits.

| | H100 SXM ($2.14/h) | L40S ($0.54/h) | RTX 3080 180 W ($0.11–0.15/h) |
|---|---|---|---|
| NiceMark nice-only (median of 3) | 8,349 | 10,245 | 3,711 |
| NiceMark detailed (2 runs) | 33,056 | 43,579 | 16,624 (320 W) |
| b60 1e16 s/field | 20.1 | 16.4 | — |
| b62 1e16 s/field | 12.7 | 10.6 | — |
| b62 1e17 s/field | 103.8 / 103.5 | 81.4 / 79.5 | 229 |
| numbers per $ at b62 1e17 | 1.6e18 | 8.3e18 | 1.05–1.43e19 |
| per $ vs the 3080 | 0.11–0.15× | 0.58–0.79× | 1 |
| break-even $/h | 0.24–0.33 | 0.31–0.43 | — |

vs the 4090 (21.6–25.7k NiceMark per $/h): L40S 19.0k (0.74–0.88×), H100 3.9k. Join layout identical
on both (b62 1e17: 7 slices × 3,844 partitions, 3,785 batches of 6, 2,594 MiB); survivor and check
counts match the 3080 to 4–5 figures. The work is integer-bound: the H100's clock cap and bandwidth
do not help. The join's memory budget stops at 4 GiB (join_plan.rs) so 46/80 GB sit idle (slices
were measured not to be a lever in L1.7, so no action). **Fleet guidance:** never buy H100 at
market; L40S only under ~$0.35/h.

## L33.2 Top kernel part 2 as a PR: limb skip + (a) + (c) on #235 (2026-11-01, agent; `L33/PR-RESULTS.md`, `L33/pr-raw/`; PR #237, branch `pr/join-top-cert-2` 252e69e on 6e7475e)

RTX 3080 180 W (1406–1474 MHz), A = #235, interleaved, medians (every round faster):
| field | vs #235 | per round | implied vs main |
|---|---|---|---|
| b62 1e17 (5 rounds) | ×1.100 | 1.089–1.122 | ×1.210 |
| b62 1e16 | ×1.098 | 1.098–1.113 | ×1.196 |
| b60 1e16 | ×1.092 | 1.077–1.110 | ×1.150 |
| b64 1e16 (2 rounds) | ×1.019 | 1.015–1.023 | ×1.015 |
| NiceMark 4048 → 4484 | ×1.108 | 1.094–1.124 | ×1.186 |
Exact: certificate test with #235's counts (102,365 / 33,582 / 69,824) on CUDA, lavapipe naga and
SPIR-V (word-for-word difference check kept); join parity incl. b50/b54 on CUDA and lavapipe SPIR-V;
both dense fields; whole b42; COMPARE 1e14 counts = #235 at b57/60/62/64; digit-count host test;
fmt/clippy ×3; lint 0 flagged; TopKernel constant divisions 539 → 270; SPIR-V blocks 478 → 366
(b57), 496 → 384 (b64). Not run on Metal (M4) — stated in the body. Stacked on #235, independent of
#236. With #236 the three join PRs together project to ≈ ×1.50 at b62 1e17 vs main.

## L33.1 Early reject in top certification: no-go, and the limb-skip side finding (2026-11-01, agent; `L33/SCOPING.md`, `L33/raw/`; branch `exp/top-early-reject` f409f51)

150.7 G pairs counted (one field each at b60 1e16, b62 1e16, b62 1e17). At b62 67.6 % of pairs fail:
60 % share a digit between a² and a³, 33 % repeat within a², 31 % within a³ (overlapping), 1.7 %
closure only; carry/ndig never reject alone. The first repeat is always among the two lowest
certified digits of a power (the parent certified the higher ones); digits come out low first, but
partners come later, often in the other power; nothing is known before the square's 10th pass of
13; 22.5 % of pairs are dead after the square (39.9 % with the parent's cube digits on the device,
+2 words per `tlay` entry; sound on all 150.7 G). **An in-place exit cannot fire (99.9998 % of 32-lane
planes hold a kept pair): ×1.010; block-level compaction ×1.000 (1e17) / ×1.018 (1e16); parent-digit
version ×1.036 (≈ ×1.045–1.053 without its host pass) → the early reject fails the bar.**
**Side finding, clears the bar:** the long division ran all 12 or 18 limbs every pass though the top
ones are known zero; skipping them (~8 lines) cuts 60 % of division steps: exact (certificate test
with #235's counts, join parity, counts identical), no SPIR-V blocks added, lint clean; **×1.051 at
b62 1e17 (6 rounds), ×1.058–1.071 b62 1e16, ×1.057 b60, NiceMark ×1.066**; with the parent-digit
compaction ×1.092–1.099 at b62. PR candidate: limb skip + L31's (a)+(c) (≈ ×1.10 together), needs an
M4 run and a combined measurement.

## L31.2 (a)+(c) on the combined tree (2026-11-01, agent; `L31/AB-COMBINED.md`, `L31/ab-raw/`; branch `exp/top-cert-2b` eb3d7e6 on e9cdac4)

RTX 3080 180 W (m139250), A = combined e9cdac4, interleaved: **b62 1e17 ×1.045 (5 rounds, 1.023–1.057;
A's spread 3.9 %), b62 1e16 ×1.038 (6 rounds), b60 1e16 ×1.059, b64 1e16 ×1.022, NiceMark ×1.041**
(b60 ×1.056, b62 ×1.054, b58 weak ×1.041, strong ×1.019). The ~7 % projection came out at 4–6 %
(top kernel not profiled; gap unexplained). Exact: certificate test with #235's counts on CUDA,
lavapipe naga and SPIR-V (now also checks the power differences word for word; the old binary
search stays in the reference scan); join parity incl. b50/b54, dense fields, whole b42; 1e14
counts = A; new host test for the digit-count constants at bases 10–64; fmt/clippy ×3 clean; lint 0
flagged. SPIR-V TopKernel blocks 478 → 366 (b57), 496 → 384 (b64). **Verdict: no-go narrowly** (b60
clears 5 %, b62 does not). Options for the user: ship as an exact ×1.04–1.06 kernel shrink; add the
Barrett step after an M4 run; fold into the next cert_power change.

## L32.1 Wave padding after #236: bucket-sized tail wave (2026-11-01, agent; `L32/SCOPING.md`, `L32/raw/`; branch `exp/join-padding` ed8bc8c, switch `NICE_EXP_JOIN_TAIL=1`)

Combined tree (e9cdac4), RTX 3080. Accounting: at b62 1e17 every bucket fits one 512-lane wave
(256–479 entries; 78 % of pairs in 288–351); waves use 64.8 % of lanes (35 % empty); b60 1e16 uses
77–79 % (buckets 384–447); buckets under half a wave 0–3 % of pairs. Re-fit over 12 profiled runs:
1.64 ps per real lane-pair, 0.64 ps per empty lane, **21 ps per survivor (61 before #236)**, 104 ps per
top; empty lanes cost 8.7 s per b62 1e17 field (5.1 %), 1.0 s per b60 1e16 field (3.2 %). Candidates:
EPT 1 ×0.92–0.95 (same lanes, twice the waves); packing two small buckets: nothing to pack; EPT 3/4 +
tail ×1.044/×0.973. **Prototype: a partial wave uses only the planes its entries need, planes skip
the AND for slots they don't hold**: removes 87–93 % of empty lanes; exact (join parity incl.
b50/b54, dense fields, COMPARE 1e14; counts = base); WGSL lint clean; SPIR-V blocks 109 → 123;
registers 40 → 41 (likely one fewer resident cube per SM; a 40-register bound would need a spill
CubeCL can't emit). **A/B: b62 1e17 ×1.040 (5 rounds), b62 1e16 ×1.051, b60 1e16 ×1.028, NiceMark
×1.078 (5016 → 5406).** Verdict: below 5 % at the live sizes; NiceMark alone clears it. Not run on
lavapipe or Metal (plane skipping inside the wave must be checked for barrier uniformity there).
**Parked**; `2a681f6` is the measured commit (fails fmt/clippy), head ed8bc8c is clean.

## L30.4 Second card: #235, #236 and both on an RTX 4090 (2026-11-01, agent; `L30/second-card/RESULTS-4090.md`)

RTX 4090 (58626188, GB, $0.309/h; power limit set to 300 W of 450; 2,360–2,470 MHz; no thermal
throttling), interleaved main/#235/#236/both, medians of 3, spreads ≤ 2.9 %:

| | #235 | #236 | both |
|---|---|---|---|
| b62 1e17 | ×1.101 | ×1.181 | ×1.341 |
| b62 1e16 | ×1.116 | ×1.182 | ×1.339 |
| b60 1e16 | ×1.084 | ×1.235 | ×1.361 |
| b64 1e16 | ×1.002 | ×1.309 | ×1.331 |
| NiceMark nice-only | ×1.076 | ×1.167 | ×1.260 (10,093 → 12,718) |

The savings add: `both` within ±1.2 % of the additive prediction (100.4–103.1 % of the product); #235
gains nothing at b64 on one card (the 3080's apparent shortfall came from cross-box comparison).
Exactness on `both`: CPU-reference test passes; 1e14 join = stride and counts = main to the digit;
1e16/1e17 counts identical every run and equal to the 3080's. PR bodies #235/#236 updated with the
second card.

## L30.3 #235 + #236 combined vs main, and the profile after both (2026-11-01, agent; `L30/COMBINED.md`, `L30/combined-raw/`; merge branch `exp/join-235-236` e9cdac4)

Merge: cubecl_join.rs and join_plan.rs merged on their own; only the CHANGELOG line conflicted.
Exactness: CUDA certificate test (L29 counts), join parity incl. b50/b54, both dense fields; 1e14
counts = main at b57/60/62/64; 1e16/1e17 counts = #236's exact counts every run; fmt/clippy/lint clean.
RTX 3080 (m139250, 180 W), interleaved, medians, spreads ≤ 2.2 %, every combined round faster:
**b62 1e17 ×1.365 (226.8 → 166.2 s); b62 1e16 ×1.350; b60 1e16 ×1.379; b64 1e16 ×1.305; NiceMark
3676 → 4871 (×1.325).** Each PR alone on the same box at b62 1e17: #235 saves 20.7 s (×1.100, up
from ×1.075 thanks to its SPIR-V fix), #236 saves 39.4 s (×1.210); product ×1.332, additive 166.65 s
vs measured 166.16 s: **they compound** (each shortens only its own kernel). At b64 #235 does nothing
(×0.996); the combined b64 gain is #236's. **Profile after both:** b62 1e17 top 43.3 %, join 45.9 %,
check 5.7 %, other 5.2 % (main: top 41.3 %, join 50.7 %); b60 1e16 top 36.6 %, join 50.4 %. The stage
never overflows now. **35 % of the join's lanes are padding at b62 1e17** → next levers: the top
kernel (L31's (a)+(c), no Apple risk, ~18 % off the top kernel ≈ 7–8 % whole-field at this share) and
wave padding (L32: bucket-sized tail wave / EPT 1 at 1e17).

## L31.1 Top kernel part 2 scoping (2026-11-01, agent; `L31/SCOPING.md`, `L31/raw/`; branch `exp/top-cert-2` 3eb8e5e, switches `NICE_EXP_TOP_*`)

Top kernel time at b62 1e16 (on #235): long division of a^j 33 %, digit extraction/bookkeeping 22 %,
binary search for ndig(d) 14 %, computing a^j/e^j 10 %, in-kernel bookkeeping 8 %, launch + a/e 6 %,
closure 5 %, carry test 4 %; scan + fill kernels another 16 %. Whole-field (180 W 3080, interleaved,
spreads 1–4 %): (a) e^j − a^j from e − a ×1.020 (b62 1e16) / ×1.016 (b60); (b) Barrett digit step
×1.011 / ×0.995 (CUDA already turns the constant division into a multiply); (c) ndig from the bit
length + one compare ×1.042 / ×1.039 (top kernel −14 %); (a)+(c) ×1.062 / ×1.031, **b62 1e17 ×1.021**;
**all three ×1.056 / ×1.047, b62 1e17 ×1.053.** Certificates identical to #235's everywhere; tests pass
on CUDA and lavapipe (WGSL and SPIR-V); SPIR-V blocks b57 478 → 366 ((a)+(c)) → 258 (all), b64 270
(#235: 496); lint 0 flagged; no constant division in the new code. A PR needs: an M4 run of (b)
(`mul_hi` = 64-bit product >> 32, never divided; unproven on Apple), switches removed, host tests for
the precomputed constants, b64 + NiceMark + an uncapped card. **Parked at ~5 %: marginal; revisit
after #235/#236 land and the combined profile shows the new split.** (c) alone is worth keeping.

## L30.2 Prefilter in the walk, PR #236 (2026-11-01, agent; `L30/RESULTS.md`, `L30/pr-raw/`; branch `pr/join-prefilter-in-walk` dd4a0eb on fae7398)

One commit; the prefilter runs in the set-bit walk before staging and is the only path (no switch);
handles every join shape the host accepts (old test windows b10–64, k = 1–5, with/without key level
run the new code); compile-time zero terms as in `cpu_join`; `mid_pass`, the flush-time prefilter,
its plane compaction and `ext_pk` deleted; the flush is one atomic + a plain copy; join kernel
registers 62 → 39. Memory plan: `ext_q` 8 B per entry×slot (was `ext_pk` 4 B), counted by `Footprint`;
plans +2–11 MiB, partitions per launch unchanged.
RTX 3080 (180 W), interleaved ×3, median device s/field: **b62 1e17 225.9 → 186.0 (×0.823)**, b62
1e16 ×0.846, b60 1e16 ×0.806, b64 1e16 ×0.769; **NiceMark nice-only 3768 → 4500 (×1.194)**; every
round faster; spreads main ≤ 3.1 %, PR ≤ 1.6 %. Exactness: counts identical run to run and to the
prototype; at 1e14 survivors/prefilter survivors/hits = main; larger fields differ from main only
by main's stage overrun; CPU-reference test (CUDA), both dense-field tests now assert exact equality
with the CPU join and pass, whole b42 matches; lavapipe join tests pass via naga and CubeCL SPIR-V
(no RUST_MIN_STACK); lint 0 flagged with JoinKernel@57/BucketKernel@57 met; fmt/clippy ×3/host
suites clean. Not run on Apple (lint is the Metal check). Merges cleanly with #235 except a
one-line CHANGELOG conflict (whichever lands second rebases).

## L30.1 Survivor handling in the join kernel: breakdown and the prefilter-in-the-walk prototype (2026-11-01, agent; `L30/SCOPING.md`, `L30/raw/`; branch `exp/join-survivors` 655f953)

RTX 3080, b62 1e16, profiled join phase, runtime switches removing one piece at a time (2 rounds):
survivor handling = **81 ps per AND survivor** (73 % of the join, 35 % of the field; the fit's 61 ps
understated it because survivors and AND lanes co-vary): prefilter arithmetic 35.5 ps (~290
instructions, rebuilds all 8 digit columns though only positions 6–7 are new); staging + flush
barriers/scans 17.7 ps (the shared atomic ~1 ps); set-bit walk 14.9 ps (23 % lane use); list writes
+ global atomic per flush round 11.9 ps. Prefilter keeps 6.13 / 6.13 / 6.70 % (b62 1e16 / 1e17 / b60
1e16); position 6 alone ~26 %, n²'s digit at 6 alone ~52 %; a third position would leave 20–21 %
(≤ 1.9 % gross, ~1–1.5 % net). Ballot compaction of the atomic ~1 ps (not worth it).
**Prototype (`NICE_EXP_L30=256`, ~110 lines): the prefilter runs in the walk, before the stage,
hoisted as the CPU join does (per-top part, per-entry part, ~50 instructions per pair).** Speed:
**b62 1e17 ×0.833 (225.7 → 188.0 s)**, b62 1e16 ×0.839 (3 rounds; ×0.850 vs main's own binary), b60
1e16 ×0.803; clock-normalised ×0.847 / 0.860 / 0.819. Exact: AND survivors = PROFILE-3's counts to
the last digit at all three sizes; the stage overrun disappears; CPU-join comparison on 4 partitions
equal. Registers 62 → 44 (occupancy is not the source: capping it back costs 1.3 %). Before a PR:
the per-entry buffer in the memory plan; the Metal rule on the new `(ac >> 16) + …` division (a sum
dividend; the lint decides). Unprototyped follow-ups: plane-compacting survivors before the
prefilter (est. 5–10 % more), the third prefilter digit (~1–1.5 %).

## L29.2 #235 SPIR-V compiler stack overflow, cause and fix (2026-11-01, agent; `L29/SPIRV-FIX.md`, `L29/spirv-raw/`; head 6e7475e)

CubeCL's SPIR-V compiler nests ~1 `compile_block` frame per 2 code blocks (~1.1 kB each) on the
device thread `DSD-4-0` (default 2 MiB stack); gdb showed 1,079 nested frames at the overflow. The
PR's certificate test kernel (four power scans + `top_cert`, up to 2,101 blocks; b47 with 3 words
failed first; b50 needs 2.26 MB) overflowed; production kernels did not, but the PR had grown the
b64 top kernel 580 → 778 blocks (peak 620 → 868 kB in the join parity test). naga's WGSL path
compiles differently. **Fix:** `cert_power` branches once per chunk (a chunk wholly below c0 is used
as its value; other chunks fold digits with selects): b64 top kernel 496 blocks (< main's 580),
512 kB peak; the test launches in three parts (largest 548 blocks). Verified on the box (Mesa 25.2.8,
rustc 1.99.1): both lavapipe steps (SPIR-V 24, naga 29), lint 0/15, CUDA parity + certificate test
with L29's exact counts, fmt/clippy clean. Speed RTX 3060 b62 1e16, 2 rounds: main 35.18 s, PR
32.84 (×1.071), fix 32.09 (×1.096 over main). **#235 CI green (25 pass).**

## L29.1 GPU top certificate from one endpoint's digits and a carry test (2026-11-01, agent; `L29/RESULTS.md`, `L29/raw/`; PR #235, branch `pr/join-top-cert-fast` d6cc9da on 9bde4a8)

`cert_power` divides only a^j into digits, keeps both candidate answers while scanning, and picks
with (a^j mod b^c0) + (e^j − a^j) ≥ b^c0; the remainder is built in 16-bit limbs from the digits
below c0 by compile-time-constant multiplies; the long division is #228's; no new division.
Exactness: new test `top_certificates_match_the_lockstep_scan_and_the_cpu` (wgpu + CUDA): 102,365
intervals, 33,582 kept, 69,824 powers taking the carry, word-for-word vs the old lockstep scan and
vs the CPU `Base::cert`/`cert_floor`; all existing join parity tests (b50/b54 windows, dense fields,
whole b42, join = stride), host 221; lint clean; WGSL lint 0 flagged (incl. the test kernel at bases
10–64). Certified-top counts = main at 1e16; survivors/checks = main to the last digit at 1e14 (at
1e16/1e17 they vary run to run on main too, via the stage overrun, by the same amount).
RTX 3080 host-capped 180 W, interleaved, medians of 3 (spreads ≤ 2.7 %, every PR round beat the main
round before it): **b62 1e17 229.3 → 213.3 s (×1.075); b62 1e16 ×1.089; b60 1e16 ×1.053; b64 1e16
×1.040**; NiceMark 3711 → 3976 (×1.071), scenarios ×1.049–1.106, none slower; 1e14 ×1.007–1.055 (2
rounds). Top kernel alone ×1.24 (b62), ×1.22 (b60), ×1.08 (b64: its chunk divisor 2^12 was already
a shift). Not done: e^j still computed in full (only e^j − a^j is needed); a limb-bounded division
variant was bit-identical with no clear gain (patch saved); AMD/Apple not run.

## L1.7 Join profile at b62 1e17 (the live size) on main 9bde4a8 (2026-11-01, agent; `L1/PROFILE-3.md`, `L1/profile3-raw/`; branch `rp/gpu-profile-3` bddf20f)

RTX 3080 10 GB **host-capped at 180 W** (1430–1510 MHz; absolute seconds ~1.22× PROFILE-2's card;
shares and the fit carry over). **b62 1e17: 223 s device per field = 7.28 µs per prefix, the same
as b62 1e16.** Profiled shares (probe excluded, +7.2 % overhead): top certification **37.8 %**, join
45.7 % (survivor handling 26 % of the field, real AND lanes 12 %, per-top chunk cost 4 %, padding
3 %), check 3–4 % unprofiled (7.9 % profiled), bucket 3.3 %, other 5.3 %. Stage-overrun extra
checks 0.014 % (1.1e-4 of survivors). Layout 11 slices, 6,439 batches of 5–8 partitions, 30.6M
prefixes; host setup 19 s CPU per field, overlapped except the first slice.
**Refit (1e16 + 1e17, 12 runs, rms 1.6 %):** join = 1.18 ps × real lane-pair + 0.49 ps × empty lane
+ 60.8 ps × AND survivor + 238 ps × top; fitted on 1e16 alone it predicts 1e17 within 4 %: **1e17
adds no new cost term.**
**Levers at b62 1e17:** (1) top certification: 12 % faster = 5 % win, 25 % = 10 %; it costs 0.77 ns
per (prefix, partition) and only 32 % of those pairs certify; (2) survivor handling: 18 % cheaper
per survivor (or 18 % fewer survivors) = 5 %; (3) AND lanes: 37 % per lane-pair = 5 %; nothing else
reaches 5 % (padding 3 %, per-top 4 %, per-check 2.4 %). **Batches/slices are not levers
(measured):** halving the survivor bound (38 % fewer batches) ×0.994; 11 → 4 slices ×0.991 (wider
slices prune 9.4 % less). Notes: the first unchecked b62 field has no top-layer prefixes (empty);
at b64 #228's top kernel reads ~12 % slower than clock-scaled (b64 not live; card confounded).

## L28.1 Two-word digit mask in the native FD kernel on wgpu (2026-11-01, agent; `L28/RESULTS.md`, `L28/raw/`; branch `pr/fd-u32-mask` 2b8d524, NOT opened)

`fd_mask_u32` moved from cubecl_web.rs into cubecl_detailed_fd.rs and shared; `fd_mask_sc` picks
u64 on CUDA/HIP and the u32 pair on wgpu (switched on `wide_chunk`); no divisions. RTX 3060:
CUDA 3 FD tests + 44-base sweep (132 windows, 9.6e8 numbers, 180 near misses) exact; lavapipe via
naga and via CubeCL SPIR-V: FD tests + browser FD tests + sweep exact; host 221; fmt/clippy clean;
WGSL lint 0 flagged; u64-naming lines in the native FD kernel's WGSL 135 → 32 at b40 (prologue,
seed word split, near-miss record remain); browser kernels' WGSL byte-identical to main.
**Speed:** CUDA PR vs main 0.992 / 1.001 / NiceMark 0.996 (unchanged). **The pair forced on CUDA is
24 % slower** (0.766 / 0.763), so CUDA/HIP keep u64. lavapipe PR 0.91–0.94× main on a noisy shared
host → Vulkan on native-u64 cards (AMD, NVIDIA-wgpu) may lose. **Apple M4 and AMD unmeasured.**
Decision: hold the branch; measure on the M4 and on AMD before opening; if AMD loses, gate the pair
to Metal adapters only (the wgpu backend enum is already read for the earlier Metal gate).

## L24.4 AMD parity for #233, run by the user (2026-10-31; `parity-demoux-1031.json`)

demoux, RX 9070 XT, LibreWolf (Firefox 155, wgpu → naga → Vulkan), `parity.html` served from
ivory (https://100.109.36.42:8443), build ae8b0bd, `gpu_build_info.detailed_kernel = "fd"`.
**199 windows, 25,471,443 numbers, 50 near misses, 0 differences, 23 s wall**; adapter present,
not a fallback (Firefox blanks vendor/architecture/description). Rate check: 2e8 at b40 in 0.117 s
= 1.71e9 n/s with Firefox's 16.7 ms timer steps (sanity floor only; the browser benchmark suite
on AMD is still unmeasured). The user noted LibreWolf now runs it without flags ("they must have
pushed some updates"). With this, #233 is exact on: lavapipe, SPIR-V, SwiftShader, M4 Chromium
(Tint → Metal), M4 native (naga → Metal), and AMD Firefox (naga → Vulkan).

## L24.3 Browser GPU detailed mode by finite differences (PR #233) (2026-10-31, agent; `L24/RESULTS-B.md`, `L24/raw-b/`; branch `pr/web-detailed-fd`, rebased onto main ba03322)

Exactness, 0 differences everywhere: native lavapipe (naga) `web_fd_matches_cpu_detailed` 430
windows (§3.3 list), `web_fd_seed_matches_cpu` 132/132 word for word, existing `web_kernel_*`
tests; CubeCL SPIR-V compiler: same five tests; CUDA FD suite + native lavapipe FD suite (native
kernel unchanged); host 221; fmt/clippy clean (default, gpu, gpu+spirv, wasm crate host and
wasm32 `--no-deps`); WGSL lint 122 shaders 0 flagged (FD kernel + seed probe at all 44 bases; no
u64; hot loop has no division); SwiftShader (CI image) `run.sh`, harness parity 199 + 13 windows,
seed probe 132/132, 78 run-shape runs; **M4 Chromium 151 headless no flags: parity 201 windows
(4.25e8 numbers, 50 near misses) + 440-window sweep, seed probe 132/132, 318 run-shape runs**; M4
native naga→MSL (Firefox's path): five tests pass, with the half-shift reproducer still failing
there as a live control.
**M4 speed (3 rounds, interleaved, spreads ≤0.4 %):** b40 6.59e8 → 4.40e9 (**6.7×**), b50 3.82e8 →
3.86e9 (**10.1×**), browser GPU NiceMark 265 → **2170 (8.2×)**. The browser now runs ~1.8× the native
wgpu FD kernel on the same M4 (guess: the native kernel's u64 mask is emulated on Apple; a u32 mask
there is a separate change = new lead). Run length stays 128 (64 is 3–5.5 % slower, 256 +0.7/+2.4 %).
Machine time 29 min wall (~15 min running). CI cost: +~85 s per lavapipe pass, +~140 s on SPIR-V.
**Coordination:** #231's lint `--require DetailedKernelU32@40/50` must gain `DetailedFdKernelU32@40/50`
(and keep one per-number call) once both are in; whichever lands second carries that edit.

## L24.2 Parity step, adapter check and WGSL lint (PR #231) and the CI flake (2026-10-31)

**PR #231** (`pr/browser-parity-step` 0f87771 on 2a1caf2): `web/search/parity.html` + `parity.js`
compare `process_chunk_gpu` vs `process_chunk_wasm` as raw JSON byte for byte and show adapter info;
the e2e drives the same page (CI: 13 windows, 9.3 s; `--parity hw`: 199 windows, 2.5e7 numbers);
a difference fails with the window and first differing field; a hung window fails and continues;
no adapter → `PARITY SKIPPED`; `--hw` requires a real non-fallback adapter matching
`--expect-vendor` and a warm 2e8 b40 call > 1e8 n/s. `scripts/wgsl-lint.py` + ignored test
`wgsl_dump_for_lint` (browser, detailed, stride, join kernels) in the lavapipe job: 8 s, 14 shaders,
0 flagged on main; flags the pre-#225/#228/#229 shaders and the reproducers. CI e2e 64 s vs 50–53 s
on main. M4 headless: `--hw --parity hw` passes in 26 s (199 windows, 50 near misses identical);
`--parity-random 10`: 639 windows identical; `--expect-vendor amd` fails as designed. Side note:
rootless podman on ivory leaves an empty `oom` file in the cwd; **upstream main has a tracked
`oom` at the repo root since #226** (same cause, the user's commit).
**CI flake diagnosed:** run 41219859643 attempt 1 (main 2a1caf27, NVRTC job) failed
`gpu_niceonly::tests::threaded_pipeline_matches_the_one_field_form_field_by_field` at
gpu_niceonly.rs:1730: left = 250000-wide descriptors, right = 500000-wide; the log shows the
adaptive MSD floor firing under load ("250000 → 270856, cpu waited 33 %"). The same test failed 3×
on the boxes under `--test-threads 8`, always passing alone (L25/L26). Timing-dependent test →
fix = pin the floor in the test (L27, agent running).

## L24.1 Headless WebGPU bring-up on the M4 and PR #230 (seed refactor) (2026-10-31, agents; `L24/BRINGUP-M4.md`, `L24/RESULTS-A.md`)

**Bring-up (22 min of Mac time):** Playwright 1.62 `channel: "chromium"` (Chrome for Testing 151),
macOS 26.3, over SSH, no GUI: adapter `apple`/`metal-3`, `isFallbackAdapter` false, warm 2e8 b40
call 6.56e8 n/s with **no flags**; `--enable-webgpu-developer-features` unmasks "Apple M4";
SwiftShader (CI pin) reports google/swiftshader, fallback true, 1.77e7 n/s. **Today's browser GPU
kernel is exact on Apple through Chrome's Tint:** 201 windows (§3.3 + both 2e8 benchmark windows),
4.25e8 numbers, 46 bases, 50 near misses, 0 differences; repeat identical; extra seeded sweep 440
windows 0 differences; CI subset on SwiftShader ~11 s. Rates: b40 6.58e8, b50 3.83e8, browser GPU
NiceMark 263–265. Harness: fork `exp/browser-gpu-harness` 5eeed09 (`wasm-client/e2e/hw/`).
**PR #230 (`pr/fd-seed-split16` 215952d):** `fd_seed_split16(nw: &Array<u32>, …)`; step helpers,
`fd_to_digits`, `NO_CARRY` pub(crate); CUDA/HIP branch untouched. 3080: fmt, 3 clippy runs, 220
lib tests, 3 CUDA tests (+ `NICE_CUBECL_WIDE=0` exercising the shared fn on the GPU); lavapipe seed
132/132 + FD/near-miss/detailed; **M4 seed 132/132 on Metal**, FD + near-miss pass; the half-shift
reproducer still fails there (control). WGSL: same code up to renaming at 14 bases + the seed
probe at 44 bases; only n's words go through an `array<u32, limbs>`. NiceMark split16 path
+0.2 % / −0.3 % (drift ~1 %). M4 34 min wall (~2 min compute).

## L26.1 Stride prefilter defensive fix (2026-10-31, agent; `L26/RESULTS.md`, `L26/raw/`; PR #229, branch `pr/metal-halfshift-prefilter`)

`candidate_check`'s low-digit prefilter (b ≤ 40 only). The #228 "top pair as one u32" construction
would, at two limbs (b33–40), divide `u32(n_lo >> 32)` = the u64 form of the bug (a compiler folds
the rebuilt halves back into the word; #228 escapes because its pair is a u32 sum). So each pass
divides the top pair as hi·Q + (hi·R + lo)/K with 2^16 = Q·K + R; every dividend is that sum or
`rem << 16 | limb` with a run-time remainder. Python model exact over ~3M cases, no overflow.
RTX 3060 (58548226, 1.08 h): lavapipe probe/cross-filter/`matches_cpu_niceonly`/`finds_69` pass;
CUDA `cubecl_cuda_matches_cpu_niceonly` + local CUDA copies of the probe and cross-filter tests
pass; 27-window sweep b28–40: 9,675 of 1,475,822 survivors = host mirror = main on both runtimes.
WGSL flagged sites main → fix: b30 6→0, b34 6→0, b40 6→0. Host 208/208, fmt/clippy clean. Not
M4-run (the paired form passes there today; the fix is defensive). Note: `matches_cpu_niceonly`
and `finds_69` barely touch the prefilter (none at b10/12/25; b40's 5e6 window launches nothing);
M4-CONFIRM's "b25 runs the prefilter" was wrong. Rebased onto main 7362e18 (CHANGELOG conflict).

## L25.2 M4 confirmation of #228 and the stride prefilter probe (2026-10-31, agent, 8 min of mayalaran; `L25/M4-CONFIRM.md`, `L25/raw/m4/`)

**#228 prediction confirmed (twice):** 472c9a0 + windows fails `cubecl_join_matches_the_cpu_reference`
at b50 with **0 join survivors vs the CPU's 934** (prefilter 0 vs 97); a per-window run shows b54
**0 vs 445** (0 vs 51); the other 18 windows agree. The branch (56b68bf) passes everything incl.
both windows, the b57 frontier field, tight/sliced/refused layouts; `join_sample_runs_partitions_
of_a_production_field` passes on both trees. The device loses every survivor → missed nice numbers
at b49–55 on a Mac without the fix. PR body + comment updated.
**Stride prefilter (cubecl_backend.rs:433–437), main:** `cubecl_prefilter_survivors_match_the_host_
mirror` passes twice at b30/34/40 (every lane width); `cubecl_matches_cpu_niceonly` (b10–80),
`cubecl_cross_filter_survivors_match_the_host_mirror`, `cubecl_niceonly_finds_69_in_base_10` pass.
So the paired `/`+`%` form still dodges the bug today; the fix is defensive (user: fix unless it
costs current work; it runs only at b ≤ 40, so it cannot).

## L25.1 Apple half-shift-divide audit of the GPU kernels (2026-10-31, agent; `L25/AUDIT.md`, `L25/raw/`; PR #228, branch `pr/metal-halfshift-top-kernel` 56b68bf on 472c9a0)

Source audit + WGSL dumps of 97 kernels on lavapipe (RTX 3060 box 58492432, $0.056/h, 1.17 h).
**One production kernel carries the pattern: the join's `top_kernel` (`cert_power`,
cubecl_join.rs:656–665)**: unrolled split16 division, first dividend each pass `x[top] >> 16` ÷ b^k;
28–64 flagged WGSL sites per base. Harmless at b40–44 and b57–64 (top limb of n², n³ is 0; b64's
divisor is a power of two); **wrong on Apple at b49–55** (the low-half model predicts 76–100 % wrong
digits) → lost join survivors → a nice number could be missed on a rescan/verification run on a Mac.
Stride prefilter (b ≤ 40 only) has the shape (6 sites) in a paired `/`+`%` form that passed the M4
probe in August (that August mul-sub failure was very likely this bug). Everything else is clean.
**Fix (ed972c7):** powers in 16-bit limbs, top limb pair divided first (the #225 construction);
no flagged sites in any of the 97 dumped kernels; `56b68bf` adds join windows with survivors at b50
(934/97) and b54 (445/51). CUDA 3/3 and lavapipe 3/3 on the branch and on main+windows; host 208;
lint clean. Throughput 0.997 (b58) / 0.984 (b62), inside main's 1.2 % / 2.4 % spread; survivor and
check counts identical over 3 × 1e14 fields per base. Not run on the M4 (needs a window): main +
windows expected to FAIL `cubecl_join_matches_the_cpu_reference`, the branch to pass.

## L23.1 Browser CPU detailed mode on finite differences (2026-10-31, agent; `L23/RESULTS.md`, `L23/raw/`, `L23/harness/`; PR #227, branch `pr/wasm-detailed-finite-diff` fe38c7e on #221's 7019653)

`process_chunk_wasm` → `process_range_detailed_fd` (2 files, 7 lines). Exactness: old wasm (d1ff798)
vs new, same `wasm-pack` command as CI, headless Chromium 151 (Playwright 1.62 image via rootless
podman on ivory): 141 windows, 36.4M numbers, raw JSON byte-identical (benchmark windows in three
chunkings, the 10M offline field, six windows per base 40–64, full ranges of bases 10–24 with 27
near misses, the e2e's b49 near miss above 2^53, 20M around the first b40 near miss). CI's e2e
`run.sh` passes locally; its CPU-vs-WebGPU histogram check agrees.
Speed (page suite, 60 s, 3 workers, interleaved ×3, M n/s): b40 3.564 → 36.571 (×10.3); b50 4.715
→ 31.127 (×6.6); b50_1t 1.782 → 8.776 (×4.9); NiceMark 246 → 1711 (×7.0); spreads ≤1.8 %. Per
number: wasm 683 → 58 ns (b40), 508 → 70 (b50), 655 → 72 (b60); native on the same box 266/43,
414/49, 541/50. The page + worker pool adds ~45–55 ms fixed per suite window (why `_1t` gains less).
Note: wasm32 clippy without `--no-deps` fails on a pre-existing lint at cubecl_web.rs:63 on main too
(CI never runs it); left alone.

## L3.7 Verification of the fixed FD branch on CUDA and lavapipe (2026-10-30, agent; `L3/verify/VERIFY-297a969.md`)

RTX 3080 (58428313, KR; host-capped at 150 W, 1545 MHz), 297a969: fmt, both lint clippy lines +
`--features gpu`, release build; 209 host tests; CUDA `cubecl_cuda_fd_matches_cpu_detailed` (every
window exact, FD = division = CPU on the benchmark windows, 73 near-misses), `..._matches_cpu_detailed`,
`..._reads_back_every_near_miss`, hand-CUDA `gpu_matches_cpu_detailed_small`; lavapipe all six wgpu
tests incl. `cubecl_fd_seed_matches_cpu` 132/132 windows; reproducer passes on llvmpipe. A
diagnostic build confirmed FD serves every b40/b50 window on CUDA and llvmpipe. Speed vs the
pre-fix PR (18cba8b), interleaved: 1.000× (b40), 0.999× (b50); absolute 2.86e10 / 2.50e10 at 150 W.
**#225 → single commit dbe2ab7 on main 9747e39 (tree = 297a969 + main's pool-size change), body
rewritten, marked ready for review, resolution comment posted.**

## L3.6 Root cause and fix on the M4 (2026-10-30, agent, 1 h 11 min of mayalaran; `L3/METAL-FIX.md`, `L3/metalfix/`; branch `pr/gpu-detailed-fd-metalfix` 297a969)

**Apple GPU compiler bug, confirmed with hand-written MSL (no wgpu/naga):** unsigned division or
remainder by a non-power-of-two constant is wrong when the dividend is a right shift by half the
width: `naga_div(x >> 16u, K)`, `(x >> 16u) % K`, `uint(ulong p >> 32) / K`. The unrolled split16
seed (`fd_to_digits`) made the first dividend of every chunk a bare `top_limb >> 16`, so n²'s (and
at some bases n³'s) digits were wrong from digit 0; limbs were exact. b23 is the same bug (at
K = 12167 a zero dividend returns 4), not a second fault. The per-number kernel is exact because
its long division is a runtime loop with a loop-carried remainder.
**Fix (af41956):** the wgpu seed in 16-bit limbs, u32 arithmetic only, each chunk's division
starting from the top two limbs as one u32 (no bare shift; one division fewer per chunk);
CUDA/HIP path, hot loop, mask and histogram unchanged. d9261a8: `fd_seed` + per-n seed test
`cubecl_fd_seed_matches_cpu` (1024 n at start/middle/end of all 44 bases, word for word) + the
minimal reproducer `metal_half_shift_div_repro` (ignored, `NICE_METAL_DIV_REPRO=1`). 297a969
reverts the gate.
**M4:** seed test failed before at b23, 25, 27–30, 49, 50, 52–55 and passes after; all FD/readback
tests pass; 220-window sweep of bases 10–64 (3.08e7 numbers, incl. run length 1) identical to the
CPU. Speed unchanged vs the PR: b40 2.435e9, b50 2.187e9, NiceMark 1216 (main 330): 3.00× / 4.54×.
Not done: CUDA/Vulkan re-run (verification agent), other Apple GPUs/macOS versions, Apple
Feedback report, **nice-only kernels not audited for the pattern (L25)**.

## L3.5 Metal gate for #225 and the desk root cause (2026-10-30, agent; `L3/METAL-ROOT-CAUSE.md`, `L3/pr-raw/gate/`)

Gate commit d8038d6 (head of `pr/gpu-detailed-fd`): the wgpu context records whether the adapter
backend is Metal (wgpu's backend enum, not the name); `DetailedKernel::for_device(base, metal)`
sends Metal to the per-number kernel; CUDA/HIP/Vulkan/DX12/GL keep FD; unit test
`detailed_kernel_by_device`. RTX 3080 box 58419619: fmt, all clippy lines, 210 lib tests, CUDA FD
tests and lavapipe FD tests pass with FD still serving; speed unchanged (b40 3.339e10 vs
3.331–3.467e10; score 16,591–16,614 vs 16,571–17,121).
**Root cause, modelled:** the seed's digit conversion computes `(x >> 16) / K` on the top word x
of n² and n³; if Apple's compiler divides the low 16 bits of x instead (the 16-bit form of the
2026-10-06 `hi(a·b)/K` miscompile), the model reproduces all 400 per-number results at b50 and
77 of 79 sweep windows exactly, including the base bands, the b32 exemption (power-of-two
divisor) and the passing windows inside failing bases. **b23 is not explained** (top words too
small). Artefacts for the Mac: `h2_repro.swift` (standalone Metal reproducer), `seed-dump-diag.patch`
(ignored test `zz_seed_dump_wgpu`, exact on CUDA and lavapipe). Cheapest fix: seed through the
per-number kernel's shared-memory long division (exact on the M4); never fold into one `x / K`.

## L3.4 #225 on Apple M4 (Metal): WRONG RESULTS (2026-10-30, agent, user-authorised 1 h; `L3/METAL-M4.md`, `L3/pr-raw/m4/`)

mayalaran: macOS 26.3 (25D125), M4, Rust 1.99.1; offline build (179 crates copied from ivory);
29 min of machine time, cleaned up. `auto` = CubeCL wgpu, "Apple M4 (Metal, wgpu<wgsl>)".
- `cubecl_fd_matches_cpu_detailed` FAILS (first b50 window; all b40 windows pass under every run
  shape); `cubecl_reads_back_every_near_miss` FAILS at b23; main's tests pass on the device.
- Per-base sweep: FD wrong at b23, b27–30, b49 (mid), b50, b52 (mid), b53–55; division exact in
  all 79 windows. Per n: 77 % wrong at b23 start, 87 % at b50; window histograms move only a few
  percent (the tests barely catch it).
- Every run length fails incl. 1 number per run → not stepping; seed, packing or mask build as
  compiled by Metal. Root cause unknown; prime suspect the Apple Metal compiler (cf. the
  2026-10-06 hi(a·b)/const miscompile seen via cubecl-metal). WGSL + naga MSL dumps saved.
- The CI "cubecl (Metal) on macOS" job (paravirtual GPU, #218) passed the same commit: it does
  not reproduce real-hardware Metal behaviour.
- Speed (3 rounds, spreads ≤0.3 %): b40 8.116e8 → 2.437e9 (3.00×); b50 4.812e8 → 2.183e9 (wrong
  kernel); NiceMark 329 → 1216. No thermal decline over 60 s reruns.
Action: #225 → draft + comment; gate FD off on Metal adapters pending the root cause.

## L3.3 Second card for #224/#225: RTX 4090 (2026-10-30, agent; `L3/AB-4090.md`, `L3/pr-raw/4090/`)

Vast RTX 4090 (58401579, CA, $0.374/h), not power-limited (480 W limit never reached) but
thermally limited (85–90 °C vs 83 °C target, fan 100 %, slowdown active in every snapshot);
clocks ~2.5–2.6 GHz main/rb, ~2.63 GHz FD. Trees main 46e4dc4 / rb 6a1e396 / fd f3a33cf.

| measurement | rb vs main (b40 / b50) | FD vs main |
|---|---|---|
| NiceMark detailed GPU, 6 interleaved rounds | 1.137 / 1.093 | 3.459 / 3.922 |
| NiceMark score (main 11,493) | 12,800 (×1.114) | 42,296 (×3.680) |
| 2e9 windows, 3 rounds | 1.023 / 1.007 | 3.022 / 3.634 |
| 1e10 fields, production path (`--repeat`, mock API, 3×8) | 0.997 / 0.995 | 3.061 / 3.767 |

FD vs rb per clock 2.87× / 3.31× (3080: 2.78× / 3.42×). An FD 1e10 field is ~0.11–0.12 s, so a
4090 needs ~9 claims/s. Exactness: all FD tests under CUDA; results identical across the three
trees on every window and on all 147 production submissions. wgpu FD test ran on llvmpipe only
(the NVIDIA Vulkan driver did not load in the container). Both PR bodies updated with these.

## L1.6 Partitions per launch + pruned buffer sizing, and the flush race (2026-10-30, agent; `L1/LAUNCH-RESULTS.md`, `L1/launch-raw/`; branches `pr/join-partitions-per-launch` c4ac700, `rp/join-flush-barrier` 61e6ba9 → PR #222, `rp/launch-with-barrier`)

RTX 3080 20 GB (58361499, 320 W = default), 10 GB layouts via test-only `NICE_TEST_JOIN_MAX_BUFFER`.
- **1e14, 10 GB budget, 3 rounds:** ×0.881 / 0.868 / 0.793 / 0.832 of main's time at b58/60/62/64
  (16 → 64 partitions per launch; 211–256 → 53–64 batches). 20 GB: ×0.899 / 0.868 / 0.787 / 0.826.
  Cap 64 beats "as many as fit" (105–177) by 1–4 %; a 16–177 sweep is fastest at 64 at every base.
- **1e16: neutral** (×0.992–1.011); 1e15 neutral with b58 1–2 % slower; NiceMark ×1.002
  (b58_msd_weak ×0.969 in 3 rounds, within that scenario's ±3 % noise here).
- **PARKED (director):** the live fields are 1e16 at b60 and **1e17 at b62** (data API
  `fields`, 2026-10-30), so a change that is neutral above 1e15 does not help production and
  does not move NiceMark. The "production size = 1e14" premise in the L1.5 brief came from a
  stale code comment ("Production fields at the frontier are 1e14"). Keep for small-field work.
- **The extra full checks are a race in `join_kernel`'s per-chunk flush decision**, not stage
  overruns: no barrier between the `s_cnt` load and the next chunk's appends, so a late plane
  can decide alone to flush and the cube's barriers pair at different call sites; stale list
  entries get fully checked and entries can be overwritten (survivors never checked). Frequent
  once cubes grid-stride (>16–19 partitions per launch); possible by the code in main's 1e16
  layouts. Instrumented: 12 of 50 base-runs at ≥64 per launch without the barrier showed a
  signature, 0 of 18 with it; 0 of 76 at 16–32. Fix = one `sync_cube()` after the load; cost
  within noise at 1e14 (×0.99–1.00), ≤ ~1.5 % at 1e16 unresolved. **PR #222.**

## L3.1 GPU detailed mode by finite differences, prototype (2026-10-30, agent; `L3/GPU-FD.md`, `L3/raw-fd/`; branch `exp/gpu-detailed-fd` e0c1b4c on the fork)

Vast RTX 3080 (58350503, KR, $0.108/h), **power-capped at 180 W** (default 340 W): the old
kernel ran ~1,425 MHz, FD ~1,690 MHz, so ~1.18× of the gain is clock; per clock FD is ~2.2×
(b40) / 2.7× (b50). 3 interleaved rounds, medians. Best variant v3: 128 numbers per thread,
high words of n²/n³ masked once per run (they change only on a rare carry; removes 14 of 50
masked digits at b50), one rare-carry branch per step.

| measure | b40 | b50 |
|---|---|---|
| benchmark harness, production host path | 2.60× (2.05e10 vs 7.88e9 n/s) | 3.22× (1.86e10 vs 5.78e9) |
| harness, both arms with the near-miss readback fix | 3.22× | 3.97× |
| 2e9-number window (mostly kernel) | 3.28× | 3.97–4.03× |

Run length flat within 3 % from 64 to 512 numbers per thread. Per-thread histogram was 5–7 %
slower than one shared atomic per number; a 2-digit lookup table within 2 % (both off).
Registers 96 (v1) → 48 (v3), no spills, 83 % occupancy; limited by integer instruction rate:
mask build ~4.5 instructions per digit = 55–60 % of the work, digit adds ~30 %.
Exactness: histogram and near-miss list equal the CPU's at every commit; test covers b40/b50
range start/end, 8 random windows, addend digit-gain windows, a window straddling the range
start (split across the two kernels), under 7 option sets, plus the full 2e8 benchmark windows
and every base 10–28 in full (73 near-misses). CUDA parity test, library tests, clippy clean.
**Side finding (independent of FD):** every call copied back the whole 20 MB near-miss buffer
(~1.7 ms over PCIe 3) even with zero misses; reading only what was written gives +5–8 % for
the current kernel and +30 % for FD. Worth its own small PR.
**Caveat for production:** at FD speed a 1e9-number detailed field is ~40 ms of GPU, so the
claim/submit round trip may dominate wall-clock; server-side detailed field size (BACKLOG 13)
becomes the limiter before the 3–4× shows in production throughput.

## L1.5 Join re-profile on main d1ff798 (prune + EPT 2 + closure + memory budget) (2026-10-30, agent; `L1/PROFILE-2.md`, `L1/profile2-raw/`; branch `rp/gpu-profile-2`)

Vast RTX 3080 **20 GB** (58350591, US, $0.149/h; 320 W cap = default; so the memory budget is
4 GiB and 1e16 layouts differ from 10 GB cards). Profiled with the probe readback excluded;
profiling adds 6–10 % at 1e14, ~0 at 1e16; unprofiled main matches within 1.5 %.

| | device s/field (b58/60/62/64) | top | bucket | join | check | other |
|---|---|---|---|---|---|---|
| 1e14 (20 fields) | 0.689 / 0.585 / 0.569 / 0.679 | 22/19/17/9 % | 11/14/16/14 % | 52/50/49/58 % | 6–7 % | 9–12 % |
| 1e16 (2 fields) | 46.3 / 33.9 / 14.6 / 42.9 | 30/34/41/15 % | ≤1 % | 62/57/51/77 % | 5–7 % | 1–3 % |

Refit at 1e16: 0.62 ps per padded lane-pair + 64 ps per AND survivor (rms 5.7 %, max 11 %,
over-predicts b64: empty lanes are cheaper than filled); + 406 ps per top → rms 2.9 %. At
1e14 the two-term fit fails (rms 33 %); + 15.6 ns per (partition, bucket) work item → rms
5.9 %. Each launch costs ~0.5 ms; **the 1e14 per-field fixed cost is 40–74 % of a field.**

**Levers ranked:** (1) more partitions per launch at 1e14: 16→32 gives ×0.92/0.90/0.83/0.87
of the time, 16→64 ×0.88/0.86/0.78/0.83 (b58/60/62/64); 32 fits 10 GB cards, 64 needs the
lists sized by the pruned slice (#215's deferred buffer sizing); one b64 run at 64 showed
0.4 % extra full checks, cause unknown, to be understood first. (2) survivor handling at
1e16: 25–59 % of device time. (3) top certification: 15–41 % (41 % at b62 1e16). (4) real
AND lanes at 1e16: 13–26 %. (5) wave padding: ~0 at 1e14 (EPT 1 costs ×1.08–1.10), 2–7 %
at 1e16, 9–15 % at b64. (6) bucket build 11–16 % at 1e14. (7) b60 stage overrun ~0.3 %.
(8) partitions per launch at 1e16: nothing.

## L2.2 Detailed finite differences through the client, NiceMark protocol (2026-10-30, agent; `L2/PR-RESULTS.md`, `L2/pr-raw/`; PR #221, branch `pr/detailed-finite-diff` 7019653)

Vast box 58350466: Xeon E5-2682 v4 (Broadwell), container quota 15.36 CPUs (`--threads 0`
→ 15), clocks uncapped. A = main d1ff798, B = branch (045797e, comment-only diff to
7019653), `nice_client detailed --benchmark --benchmark-secs 150`, A B A B A B.

| scenario | A (M n/s) | B | B/A |
|---|---|---|---|
| b40_detailed, 15 threads | 51.55 (−0.1/+0.9 %) | 287.95 (−0.2/+1.2 %) | **5.59×** |
| b50_detailed, 15 threads | 33.80 (−0.3/+0.1 %) | 271.09 (−0.0/+0.5 %) | **8.02×** |
| b50_detailed_1t | 2.22 | 15.23 | **6.85×** |
| detailed score | 1247 | 8424 | **6.76×** |

`--threads 1`: 5.57× / 8.12× / 6.80×, score 6.75×. `--threads 64` (4× oversubscribed,
cgroup throttled): 3.10× / 5.15×, score 4.80×; both trees slow, the new loop more. Pinned
per-number: b40 280→50 ns, b50 435→57, b60 560→58. Tests on the box: 180 passed, 5 ignored.
Production = the packed variant only (8 digits per 64-bit biased add); dispatch in common
(`process_range_detailed_fd`, bases 40–64 with a legal range except 63; others → division);
client's CPU chunk path calls it. Not run: GPU-feature clippy, WASM build (CI will).

## L1.4 Prune against new main on an RTX 4090, and the wave size (2026-10-29, agent; `L1/AB-4090.md`, `L1/pr-raw/4090/`)

Vast RTX 4090 (58197772, Poland, $0.375/h; **power-limited to 330 W**, so absolute times
are slow, ratios hold). A = upstream main 2709d3f (+ the two test-only harness commits);
B = `pr/field-cert-prune` 26a8b15 (rebased prune). 3 interleaved rounds, spreads ≤ 2.4 %.

| fields | b58 | b60 | b62 | b64 |
|---|---|---|---|---|
| prune vs main, 1e16 (2 per base) | ×1.097 | ×1.084 | ×1.112 | ×1.205 |
| prune vs main, **1e14 (production size, 20 per base)** | ×1.41 | ×1.50 | ×1.87 | ×1.79 |
| prune + EPT 2 vs main, 1e16 | ×1.19 | ×1.16 | ×1.26 | ×1.52 |
| prune + EPT 2 vs main, 1e14 | ×1.55 | ×1.55 | ×1.97 | ×2.08 |
| old pair on this card (85b5b4e base vs prune), 1e16 | ×1.14 | ×1.14 | ×1.37 | ×1.58 |

The 1e16 gains are below the 3080's day-1 numbers because new main carries #205's EPT 6 at
b62/b64 (a bad wave for pruned buckets) and #203/#206's own gains; the card is not the
cause (old pair reproduces the 3080). NiceMark (prune as pushed): 8086 → 9494 (×1.174);
b58 weak ×1.152, b58 strong ×1.330, b60 weak ×1.075, b62 weak ×1.126; all on the join.
**EPT with the prune: 2 < 3 < 4 < 6 in every round at every base**; 2 beats 4 by
×1.07–1.13 and 6 by ×1.15–1.27; at 1e14 EPT 1 is ~5 % better at b58 and tied elsewhere.
Exactness: `NICE_TEST_JOIN_COMPARE=1` 0 = 0 at every base; survivor and check counts identical
to the last digit across trees at 1e14; CUDA parity 3/3; CPU prune test passes; the 3080's
stage-overrun shift does not appear on new main. Bottoms removed: 55–77 % at 1e16, 72–86 %
at 1e14. Not done: the b64 1e16 dense test timed out at 300 s; NiceMark with EPT 2; EPT 1 at 1e16.

## L2.1 Detailed mode by finite differences, CPU prototype (2026-10-29, agent; `L2/RESULTS.md`, branch `rp/l2-finite-diff` on the fork: b003967 scalar, da9aaeb 8 digits per 64-bit add)

`common/src/detailed_fd.rs::process_range_detailed_fd`, same signature and output as
`process_range_detailed`; bases 40, 42–45, 47–50, 52–55, 57–60, 62, 64 (others fall back).
Not wired into the client. ivory, one thread pinned to core 3, the `b50_detailed_1t` window
(base-range start, 1,000,000 numbers), two passes of 3 interleaved rounds, median ns/number:

| base | old | scalar | × | 8 digits per add | × |
|---|---|---|---|---|---|
| 40 | 265 | 60 | 4.4 | 42 | 6.2–6.3 |
| 50 | 416–418 | 73–74 | 5.6–5.7 | 48–49 | 8.5–8.6 |
| 60 | 537–541 | 89 | 6.0–6.1 | 50–53 | 10.1–10.8 |

Old within ±1 %, new within ±2–5 %. Cycles per number at b50: old 1,390, scalar 244, packed 163.
Exactness: 11 tests, all pass for both variants: per-number equality with `get_num_unique_digits`
on 20 seeded 10k windows plus both range ends at b40/50/60 and b42/47/53/59/64; 7 windows per
base around every digit-gain point of n² and n³; b7 and b10 from n = 0; whole `FieldResults`
identical on the b40_detailed and b50_detailed windows; 27 near-misses identical over bases
10–24. Clippy clean, 179 lib tests pass.
Lessons: LLVM first compiled the digit carry as a mispredicted branch (17.5 misses per number,
only 1.6–2.2×); a branch-free select fixed it, and the GPU port must watch for the same. Packed
version profile: adds + bookkeeping 57 %, mask build 30 %, popcount + histogram 13 %. Production
builds target baseline x86-64, so `count_ones()` is a 17-instruction software popcount (both paths).
Next: wire into `client/src/main.rs` (~line 845) and run the 5 % protocol on b40_detailed,
b50_detailed, b50_detailed_1t (needs a box: ivory cannot build the client); then the GPU port
(each thread walks a run of ≥100 consecutive numbers with ~24 u32 of digit arrays in registers).

## L1.3 Field-certificate bottom prune, GPU A/B (2026-10-28, agent; `L1/PRUNE.md`, `L1/prune-raw/`)

Branches on the fork: `rp/field-cert-prune` (head 4670ffe; the prune is c1174c1, the rest
tests), `rp/field-cert-prune-base` (2d740d3 = 85b5b4e + the same harness, the A tree),
`rp/field-cert-prune-ept` (6e4e895, prune + EPT override). Vast RTX 3080 (58056651),
1e16 fields, 2 per base, the L1.2 starts, A B A B A B (3 rounds), median s/field (spread):

| base | main | prune | speed-up | bottoms removed |
|---|---|---|---|---|
| 58 | 69.36 (0.9 %) | 60.18 (1.1 %) | **1.153×** | 59.5 % |
| 60 | 45.26 (1.2 %) | 39.52 (1.2 %) | **1.145×** | 54.6 % |
| 62 | 26.98 (1.0 %) | 19.07 (0.6 %) | **1.415×** | 74.3 / 66.7 % |
| 64 | 83.42 (2.4 %) | 50.79 (0.6 %) | **1.643×** | 77.1 % |

NiceMark nice-only, 3 rounds, every scenario on the join in both trees: b58_msd_weak
+17.6 %, b58_msd_strong +32.5 %, b60_msd_weak +20.1 %, b62_msd_weak +43.9 %; score
2892 → 3705 (+28 %). Batches and slots identical (buffers still sized by the unpruned
count). At 1e14 production size the prune removes 73–86 %, so production gains are
probably larger (unmeasured).

Exactness on the box: CUDA kernel compiles; 194 host tests; `cubecl_cuda_join_matches_the_cpu_reference`,
the dense-field and whole-field CUDA tests, the CPU reference test, and the throughput
harness with `NICE_TEST_JOIN_COMPARE=1` (join = stride on 1e14 fields) all pass; clippy
`--features gpu -D warnings` clean. One behavioural ripple: the prune tree records 0.94× the
AND survivors and correspondingly more unfiltered prefilter survivors (2–2.5e-4 of
survivors), i.e. survivors that overflow the join kernel's staging area go to the check list
unfiltered, as on main but a little more often; +0.3–0.4 % full checks, and b64 crosses the
dense-field test's 1e-4 limit. Fix for the PR: flush every 16 tops or a larger stage.

**EPT sweep with the prune (`rp/field-cert-prune-ept`):** EPT 2 is best at every base:
×1.088 (b58, 1 round), ×1.053 (b60, 1 round), ×1.060 (b62, 2 rounds), ×1.139 (b64, 2
rounds) over EPT 4; EPT 1 worse than 2 everywhere. Prune + EPT 2 vs main at EPT 4:
**1.51× at b62, 1.91× at b64** (against the L1.2 numbers on the same machine, not
interleaved). So PR #205's EPT 6 and the EPT 5 note both give way to EPT 2 once the prune
is in; pruned buckets are 3–4× smaller, so the wave shrinks.

## L1.2 GPU join phase profile by base (2026-10-28, agent; `L1/GPU-RESULTS.md`, branch `rp/gpu-profile` on the fork)

Vast RTX 3080 (instance 58051111, $0.134/h), upstream 85b5b4e + `NICE_EXP_GPU_PROFILE=1`
(costs 3.9–6.3 % of device time; shares from profiled runs, seconds from unprofiled),
1e16 fields, 2 per base, CubeCL CUDA.

| base | roots | device s/field | top | bucket | join | check | other |
|---|---|---|---|---|---|---|---|
| 58 | 4 | 68.8 | 19.5 % | 3.8 % | 64.8 % | 4.7 % | 7.3 % |
| 60 | 2 | 45.2 | 23.3 % | 5.1 % | 55.8 % | 5.3 % | 10.5 % |
| 62 | 2 | 26.1 | 21.9 % | 7.2 % | 57.9 % | 3.6 % | 9.5 % |
| 64 | 8 | 83.1 | 7.1 % | 3.3 % | 82.6 % | 3.1 % | 3.9 % |

| base | µs/prefix | RX 9070 XT | AND survivors/prefix | prefilter survivors (= full checks) |
|---|---|---|---|---|
| 58 | 11.44 | 11.2 | 63.7k | 3.84k |
| 60 | 8.51 | 6.8–7.3 | 43.8k | 3.10k |
| 62 | 9.96 | 9.2–9.6 | 34.8k | 2.20k |
| 64 | 26.84 | 19.5 | 139.8k | 8.77k |

- Everything but the join kernel costs 4–5 µs per prefix at every base; tops per prefix
  1180–1300 everywhere. The join kernel carries the whole b64 jump (23.0 µs vs 6.1 at b62).
- Survivors per prefix = tops × roots × bucket occupancy (930–1210 at every base) × AND
  pass rate. b64/b62 survivors 4.02× = roots 8/2. b58/b60 1.45× (pass rate 1.41 % vs 1.81 %).
- **Join kernel cost model** (10 fields, four bases, max error 1.9 %): **0.58 ps per
  lane-pair, lanes padded to whole 1024-entry waves, plus 74 ps per AND survivor.** Wave
  padding is 1.07–1.10× at b58/b60 and 1.69–1.72× at b62/b64 (buckets of ~1200 spill into
  a second wave): ~18 % of b64 device time, 12 % of b62's.
- **Entries per thread (`NICE_EXP_JOIN_EPT`, 2 interleaved rounds, first field):** 5 gives
  ×1.12 (b62) and ×1.19 (b64) over 4; 6 (= PR #205) gives ×1.08 / ×1.13, matching #205's
  own 3080 numbers. So 5 beats #205 by 3.4 % / 5.4 % on this card. Needs a third round and
  other GPUs before it is a claim. The model fitted on EPT 4 predicts 5 and 6 within 0.6–3.4 %.
- L4: the check kernel is 3.1–5.3 % of device time (3.8–9.8 % of the join's), under the
  15 % kill criterion.
- Caveats: no hardware counters (`ncu` blocked on Vast); the b60 window used is denser
  (44k survivors/prefix vs ~26k on the 9070 XT's fields) so b60's µs/prefix reads high.

**What the prune should buy (director's estimate from the model, to be measured):** per prefix the
AND term is tops × roots × padded occupancy × 0.58 ps: b58 2.9 µs, b60 1.5, b62 2.8, b64 11.4;
the survivor term 4.7 / 3.2 / 2.6 / 10.3 µs. Pruning 73–86 % of bottoms (1e14 fields) cuts
the AND term by 2× at the current wave size (one wave instead of two) and by 3–7× with a
smaller wave, leaving survivors unchanged: 10–30 % of device time by base.

## L3.0 Detailed mode on the GPU (2026-10-28, agent; `L3/NOTES.md`)

RTX 3080, `auto` = CubeCL CUDA. b40_detailed 1.04e10 n/s, b50_detailed 7.8e9 (references
2.4e9 / 1.5e9 are for a weaker card). CPU 16 threads: b40 4.4e7, b50 2.86e7, one thread
1.87e6. GPU = 236–273× this CPU. `nvidia-smi dmon`: SM 98–99 %, memory controller 0 %.
Kernel: one thread per number; n², n³ in u32 limbs; digits peeled by long division by b⁵
in shared memory; OR into a mask, popcount, one shared atomic into the histogram. About
750 (b40) / 1,000 (b50) integer ops per number ≈ the card's integer throughput:
**compute-bound on the divisions.** The L2 finite-difference scheme (digit arrays updated by
addition) removes exactly those divisions, so L2 and L3 are one lead with a CPU prototype first.

## L1.1 CPU join counts by base (2026-10-28, agent; `L1/RESULTS.md`, branch `rp/l1-selectivity` a76984f on the fork)

Item 23's field per base plus a second field, 6 stratified partitions per field, ivory (EPYC
Rome) under `nice -n 19`, 3 threads; a second round reproduced counts exactly and stage
times within ±5 %. Ignored tests `cpu_join::selectivity::l1_selectivity`, `l1_probe_windows`.

| | b58 | b60 | b62 | b64 |
|---|---|---|---|---|
| roots | 4 | 2 | 2 | 8 |
| L / digits of n², n³ | 12 / 23, 35 | 12 / 24, 36 | 13 / 25, 37 | 13 / 26, 38 |
| bottoms per key list (per class) | 54.8k (961) | 54.9k (931) | 72.7k (1191) | 76.4k (1212) |
| ANDs per top | 3,844 | 1,863 | 2,383 | 9,702 |
| top popcount (n² + n³ known) | 15.7 (7.7 + 7.9) | 16.2 (8.1 + 8.2) | 17.3 (8.9 + 8.5) | 18.4 (9.6 + 8.9) |
| AND pass rate, measured / uniform model | 1.37 / 1.40 % | 1.64 / 1.42 % | 1.25 / 1.23 % | 1.06 / 1.06 % |
| AND survivors per top | 52.7 | 30.5 | 29.8 | 103 |
| full checks per top | 3.3 | 2.0 | 1.9 | 6.6 |
| CPU ms per prefix | 5.8 | 3.5–3.9 | 4.0–4.4 | 11.0–11.5 |
| RX 9070 XT µs per prefix (BACKLOG 68) | 11.2 | 7.0 | 9.4 | 19.5 |

- ANDs per top = roots × mean class size within 0.1 %: hypothesis A holds exactly.
- Pass rates follow the uniform model C(b−pc, 12)/C(b, 12); b64's tops know the most
  digits, so its pass rate is the lowest (0.85× b62). Net AND survivors per top: b64 3.5× b62.
- Tops per prefix (1.2–1.3k) and certificate cost (405–471 ns per prefix tried) are flat.
- Of the +7.6 ms per prefix from b60 to b64: 52 % survivor handling (range test, prefilter,
  dispatch, 32–41 ns each), 33 % the ANDs (0.22 ns each), 9 % full checks. ANDs are 13–17 %
  of a partition at b58–b62 and 26–27 % at b64. CPU scan shares match item 23's Zen 2 profile.
- CPU cost per prefix relative to b60: ×1.6 / 1 / ×1.15 / ×3.1; GPU: ×1.6 / 1 / ×1.33 / ×2.8.

**Lever counts (share of ANDs skipped).** Sub-bucketing by mask ∩ S: digits 0..s−1 skip
21–42 % (s = 4–8); the s most frequent top digits skip 56–81 %, but those digits are the
field's own certificate (4–7 leading digits of n², n³ every top knows). **Dropping bottoms
that share a digit with the field certificate skips 66 / 60 / 70 / 79 % of ANDs at
b58/60/62/64 with no bucketing.** CPU saving bound: 7–12 % at b58–b62, 20–23 % at b64
(only failing ANDs are skipped). GPU share unknown until the GPU profile lands.

## L1.0 Digit-sum class roots per base (2026-10-28, director, no hardware)

In the join each top probes one bottom bucket per root of x² + x³ ≡ b(b−1)/2 (mod b−1)
(overlap_join.rs module doc). The root count by base, from a 3-line enumeration:

| base | b−1 | roots | measured µs/prefix (RX 9070 XT, BACKLOG 68) | survivors per top-layer prefix |
|---|---|---|---|---|
| 58 | 57 = 3·19 | 4 | 11.2 | — |
| 60 | 59 prime | 2 | 6.8–7.3 | ~26k |
| 62 | 61 prime | 2 | 9.2–9.6 | 27–44k |
| 64 | 63 = 7·9 | 8 | 19.5 | 112–176k |

Roots for 40–97: 40:4 41:6 42:2 43:0 44:2 45:2 46:8 47:0 48:2 49:2 50:8 51:0 52:4 53:2
54:2 55:0 56:4 57:6 58:4 59:0 60:2 61:4 62:2 63:0 64:8 65:1 66:4 67:0 68:2 69:2 70:4
71:0 72:2 73:12 74:2 75:0 76:12 77:2 78:4 79:0 80:2 81:2 82:10 83:0 84:2 85:4 86:4
87:0 88:4 89:6 90:2 91:0 92:4 93:2 94:4 95:0 96:4 97:10. (Zero roots = residue-dead
bases, which the server never inserts; matches the known list.)

Reading: the b64 survivor count per prefix is ~4× b62's, exactly the roots ratio 8/2;
per-prefix time is ~2× because the tops phase does not scale with roots. b58 > b60
follows the same ordering (4 vs 2 roots). Hypothesis A of L1 is therefore the
explanation to beat; the CPU counting run (L1/RESULTS.md) checks it and sizes the
signature-bucketing lever.

