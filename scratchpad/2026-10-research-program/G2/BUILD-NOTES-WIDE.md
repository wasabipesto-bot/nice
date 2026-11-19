# The middle-out join, step 2E: masks wider than 64 bits (2026-11-18, 18:55–00:30 UTC)

> **Merged (2026-11-19, step 3W).** `dev/mo-wide` (`a8a76315`) is merged into `dev/middle-out-join` at `23ce3cf6`;
> this branch is closed. The wide path's current state, its accounts, its speed work and its number are in
> `BUILD-NOTES.md` §1 and §11. What follows is the branch's record as of 2026-11-18, unchanged.

Brief: `G2/BUILD-BRIEF-2E.md` (rules of `BUILD-BRIEF-1.md`). Branch **`dev/mo-wide`** from `7ba982c7`, worktree
`~/projects/nice/.worktrees/midout-wide`, pushed to the fork only. Box: Vast 61303619, RTX 3080 20 GB, power limit
320 W (uncapped), 64 threads with a 7.68-CPU cgroup quota, 251 GB, CUDA 12.8 image, Mesa 25.2.8 lavapipe (LLVM
20.1.2, 256 bits). Production hosts mapped to 127.0.0.1 and ::1 at 18:56 UTC, before any binary of ours ran
(`build2e/raw/proof_hosts_block.txt`). Box scripts: `build2e/box/`; raw logs: `build2e/raw/`.

## 1. Where it stands

**2026-11-18 ~22:30 UTC.** Branch head **`a8a76315`** (4 commits on `7ba982c7`), on ivory and on
`fork/dev/mo-wide`. Nothing outside `common/src/midout/` (new `gpu_wide.rs`; one line in `mod.rs`; one match arm in
`coord.rs`: bases 68–70 take the padded form), the new example `common/examples/midout_wide_bench.rs` and its `Cargo.toml`
entry. **`gpu.rs` is untouched.** No server, schema or API change; no route reaches it.

- **Bases 65 and 68 run on a GPU, end to end and exactly**: whole fields of the padded coordinate through
  `midout::gpu_wide::search_field_wide` (tops, parents, main kernel, expansion, full check, all on the card).
- **Exact at base 65**: the device equals the `u128` CPU reference on 5 real b65 slices (3 of them again on the
  final code), survivor sets n for n and every count (tops, tested prefixes, children, chunks, flat, kept, survivors
  = checked) and the check's distinct-digit count of every survivor; among them slice 532260419, where the range's
  start clips a top, and the first and last slices. It equals the **staged prototype slice** 717171717 (`bases/proto`, an independent implementation) unit
  by unit. On CUDA (W 32) and on lavapipe W 8 (SPIR-V).
- **The wide code checked where references are strong**: every slice of 17 whole small bases/shapes (10–25) against
  brute force, including 69 at base 10 found by the device's own check; bases 30, 40, 50 slices and base 64 slice
  712012851 against the CPU reference; 15 whole base-64 field runs (7 distinct fields) against the narrow path
  (survivors equal field for field).
- **Base 65: 3.484 fs per admissible n** (5 warm whole fields, 3.473–3.490), base 64 through the narrow path 1.709 in
  the same session: **×2.04**. **0.48 card-years** for the whole of base 65 on one RTX 3080 at this box's 320 W limit.
- **Width costs base 64 +3.7 %** when forced on (1.772 against 1.709 fs, 5 warm field pairs, 3.6–3.8 % per field;
  +4.6 % in an earlier session on the code before the last fixes). Base 64 keeps its narrow path; nothing pays this.
- **Base 68: exact on two slices** (143.4M and 143.1M survivors; every count and every survivor's digits equal the
  reference) and **2.13 fs per admissible n on a warm whole field** (2.19 on the cold first): **5.6 card-years** for
  base 68 on one card.
- **Two exactness defects of the wide path were found by the brute-force test and fixed** (§2): survivors of tops
  the range's ends clip, and empty top masks. Neither touches base 64; neither occurred in the b65 slices tested
  before the fixes; every exactness and timing result above is on the fixed code.

## 2. The design for width, and why

**A second path (`gpu_wide.rs`), not a width parameter in `gpu.rs`.**
- Base 64 keeps its 64-bit kernels byte for byte: no tax by construction, nothing to re-prove at 64.
- The trunk's engineer is changing the expansion, prefilter and tops of `gpu.rs` tonight: a separate file merges
  without a conflict.
- The cost: the main kernel exists twice. Optimisations of the narrow kernel must be ported (§8).
- **Generic in (b, f0, k)** (comptime), so the same wide code runs at small bases (brute force and the CPU reference
  check it) and at base 64 (the narrow path and day one's references check it). It refuses what its layouts cannot
  hold (`WideBase::new`): b ≤ 70, b^f0 < 2^25, a slice's digits ≤ 2^32 (b70's (4, 11) shape needs a 64-bit slice
  value, §7), n² and n³ of constant length over the range, limb columns below 2^31.

**What widened, and how** (costs per slice at base 65, §4):

| widening | how | cost at b65 |
|---|---|---|
| masks in two words | `(u64, u32)`, digits 64..b in the second word. Parent records stay 16 bytes: the mask's digits 64.. ride in the 7 bits above r mod b^f0 (< 2^25) | small |
| digits by division | parents: r², r³ mod b^k digit by digit; tops and check: n², n³ in base-b² limbs; child digits (c + a·d) mod b; every division by a comptime b or b² | parents 1.0 ms (b64 wide 0.7) |
| tops on the device | one thread per prefix (b·nlead: 13.4M at b65, 89M at b68), certificate by limbs; the range's first and last prefix take start's and end's low digits | **2.6 ms, 0.69 fs** |
| 7-bit digit fields | top digits 4 per word, a fifth word when `maxpop` > 16 (b64 17, b65 18, b68 19; a top with more stops the field with an error) | in the main kernel |
| more slice rows | 65 rows per chunk up to base 64 (as the narrow kernel), (b + 1) \| 1 above (67, 69, 71, 71); digits 64..b transposed by ballots (≤ 6 per chunk segment), their common masks from the same ballots; one zero row for the pad digit | main kernel 6.4 ms (b64 wide 5.7) |
| classes, roots | classes mod b − 1, `nroot` comptime (b65 1, b68 2) | none |
| probe tiling | jobs as `ninst` instances of PMAX = 576 probes (day one's second instance generalised); b68 runs 12 | b68 only |
| its own full check | production's `check_kernel` holds digits in one u64 and refuses b > 64; `wcheck_kernel` rebuilds n from (top, r mod b^f0) and the slice's digits, n², n³ in limbs, distinct digits in two words | **2.0 ms, 0.54 fs** (no prefilter) |
| the padded coordinate | `coord.rs`'s form from day one; `range_size` = `n_count` | none |

- **Survivor entries** are `(top, r mod b^f0)` (day one's `(top, r0)` is production's layout, built for its check).
- **The key** (8 digits ordering the parents) comes from the device: the field's first slice's tops and parents are
  read back and counted (every top, every parent: the reference's rule, so `kept` is comparable with the CPU).
- **Clipped tops.** A top whose interval the range's start or end cuts pairs with every child, so n just outside the
  range came out as survivors (brute force at base 20: n = 58862 below start 58945). The check now recognises them
  (prefix = the range's first or last, r mod b^f0 beyond its end), counts them apart as the reference does
  (`clipped`), and survivors and checked exclude them. Base 64's range is exactly [2^75, 2^76): no clipped top.
- **Empty top masks.** A top with no certified digit padded its digit fields with "digit 96": one past the
  common-mask table and into another chunk's slice rows. Base 20 slice 6 lost 10 of 37 survivors, and only when a
  launch held enough jobs (classes × instances), which is why the per-slice tests at bases 30–50 had passed. The pad
  digit now has a zero row and is never common. Tops at bases 64–70 always certify digits (n² agrees in its top ~9
  digits over a top's interval), so no large-base result changed; **the narrow kernel would put 64 into a 6-bit
  field** for such a top (unreachable at 64; matters if it is ever used at small bases).
- **An account the narrow path lacks: job instances that ran.** With another process holding 13.8 GB of the card,
  CubeCL's CUDA server failed an allocation; every later launch was skipped and every counter read zero, so the
  narrow path *and* the wide path reported whole b64 fields as `survivors 0 = checked 0` and passed their accounts
  (`build2e/raw/m2_oom_failed/`). The wide kernel now counts job instances reaching their end; a group requires the
  number queued (`C_JOBS`). On lavapipe the same failure surfaced as `ServerUnhealthy` at the next sync.

## 3. Tests and results

Final-code runs: CUDA `build2e/raw/v2/` (binary built from the source of `415d3483` before `cargo fmt`; the
formatting commit changes no token), lavapipe `build2e/raw/lvp3/`. CUDA is W 32; lavapipe W 8, 2 classes per
batch (4 at base 64: wgpu's 128 MiB binding limit).

| test | what | CUDA | lavapipe W 8 |
|---|---|---|---|
| `wide_bases_fit_the_layouts` | layouts hold b30–70 shapes; tested-prefix count = `cpu::unit_tops`' rule (b30, b40) | pass | — |
| `wide_whole_small_bases_vs_brute_force` | every slice of whole bases 10, 12, 13, 14, 17, 18, 19, 20, 22, 24, 25 in 17 shapes (every b mod 5 class, odd bases, f0 = 0): survivors = the brute-force predicate, no n twice, each survivor's distinct digits = `unique_digits`, nice = brute force (**69 at base 10, found by the device check**) | pass (17/17) | pass (16/17: b19 (0, 4), 6,859 slices, skipped for time) |
| `wide_slices_equal_cpu`, small bases | b30 (2,5) 100, b30 (1,5) 5000, b40 (3,6) 1234, b40 (2,6) 7, b50 (4,8) 77777 (22.2M survivors): tops, tested, survivor sets, children, chunks, flat, kept, survivors = checked, every survivor's digits | pass | pass |
| same, **base 64 forced wide** | slice 712012851: every count = day one's (children 33,705,647, chunks 528,635, flat 250,486,772, kept 123,163,397, survivors 11,768,560) | pass | pass (4 classes) |
| same, **base 65** | 717171717, 532260419 (the range's start clips a top), 0; before the last fixes also 1160290624 (the last slice) and 1. 717171717: tops 1,701,945 of 13,410,973, children 42,191,028, chunks 661,279, flat 270,545,130, kept 166,499,336, survivors 16,482,926 | pass | pass (717171717, 532260419) |
| `wide_slice_vs_staged`, **base 65** | `g2proto dumpsu 65 4 10 717171717` (staged on the box in 9 min): every unit's survivor set and top count | pass | — |
| same, **base 68** | 123456789: tops 8,100,575 of 89,043,941, children 59,975,022, flat 3,340,314,669, kept 1,776,086,673, **survivors 143,407,016**, every survivor's digits (CPU side 11 min); on the final code again, and 634515713 (the range's start's slice: 143,058,843 survivors) | pass (`fb6962ea`; both on the final code, `v2/b68_final.log`) | — |
| whole b64 fields, wide vs narrow | 15 field runs in 3 sessions: survivors equal field for field (e.g. t 13107: 48,211,413,201) | pass | — |
| whole b65 / b68 fields | every account (kernel errors, jobs ran, list = counted = checked + clipped, index sums, caps) | pass | — |
| production suite | `cargo test --release -p nice_common --lib` (default features) | 214 passed, 0 failed, 10 ignored (as on main) | — |
| lint | `cargo fmt --all --check`; clippy `-D warnings`, `nice_common`, all targets, default and `cubecl-cuda,cubecl-spirv` | clean at `a8a76315` (`build2e/raw/lint2/`; `lint/` is the run that found 3 findings, fixed in `a8a76315`) | — |

**The kept fraction at b65 is 0.615** (166.5M / 270.5M on 717171717): the study's 0.615 exactly.

## 4. The numbers

**Measured** on Vast 61303619 (RTX 3080, power limit 320 W, not capped by its host), 2026-11-18. Fields are whole
quanta of the coordinate (digits 6–8 fixed): base 64 2^57 n (4,096 slices), base 65 1.011e18 (4,225 slices), base
68 8.80e18 (4,624 slices). Admissible n = n × roots / (b − 1). Warm = not the process's first field (that one pays
compilation and the key's first read-back, ~1.5 s).

| run | what | fs per admissible n | card while busy |
|---|---|---|---|
| **base 64, narrow** (`gpu::search_field`) | final session `m4/b64_warm.log`: 5 warm fields, one process alternating per field with the wide path (t 4095 the warm-up) | **1.709** (1.670–1.738) | 271 W, 1,646 MHz |
| **base 64, wide forced** | the same 5 fields, interleaved | **1.772** (1.731–1.801): **+3.7 %** | same |
| base 64, earlier sessions | `m2/` (code before the last fixes): narrow 1.705, wide 1.784, +4.6 %; `m1/` one cold process per field: +4.4–4.7 % | — | 268–273 W |
| **base 65** | final session `m4/b65_warm.log`: 5 warm whole fields t = 13731 … 260893 (0.05 … 0.95 of the base) | **3.484** (3.473–3.490) | 303 W, 1,769 MHz |
| base 65, earlier session | `m1/b65_5f.log` (first code): 3.468 warm, 3.607 cold | — | 301 W |
| **base 68** | final code `m5/b68_f2.log`: 2 whole fields in one process, t = 157216 cold, t = 200000 warm | **2.129** warm (560 s), 2.187 cold (575 s) | 275 W, 1,631 MHz |
| base 68, earlier | `m3/b68_f1.log` (`fb6962ea`): t = 157216 cold, same survivors as the final code (661,500,986,289) | 2.188 | 271 W |

**Base 65 against base 64 on the same box in the same session: ×2.04** per admissible n (3.484 / 1.709). The study
predicted G2's b65 cost at ×2.5 of its b64 cost and 2.5–3.1–4.2 fs: 3.48 lies inside the band, 12 % above its
centre (its "≤ 3.1 confirms" line is missed; its "> 4.2" line is not reached). Base 68: the study's band 1.3–1.6–2.1;
measured 2.13 warm, at its top end.

**Card-years**, measured fs × admissible n of the base on one RTX 3080 at this box's 320 W limit:
- **base 65: 3.484e-15 s × 4.371e21 = 1.52e7 s = 0.48 card-years** (study 0.34–0.43–0.58);
- base 68: 2.129e-15 s × 8.31e22 = 1.77e8 s = 5.6 card-years (study 3.5–4.2–5.4).

**Where the time goes at base 65** (cumulative `MIDOUT_STOP` = 1 tops, 2 + parents, 3 + main kernel, 5 + expansion,
on field 137312, one cold process each, first code; per-slice deltas between stops cancel the ~1.5 s one-time cost;
`m1/b65_stop*.log`, `m1/b64w_stop*.log`):

| stage | b65 ms/slice | b65 fs/adm | b64 wide ms/slice |
|---|---|---|---|
| tops (13.4M prefixes; 2.1M at b64) | ≈ 2.6 | 0.69 | ≈ 0.2 |
| parents | 1.03 | 0.27 | 0.73 |
| main kernel | 6.37 | 1.70 | 5.70 |
| expansion | 1.13 | 0.30 | 0.74 |
| check, no prefilter (16.5M survivors; 11.8M at b64) | ≈ 2.0 | 0.54 | 0.75 |
| **total** | ≈ 13.1 | 3.5 | 8.1 |

- The main kernel per admissible n rises ×1.34 from b64 (6.37 ms over 3.74e12 admissible n per slice against 5.70
  over 4.47e12), less than the study's counts alone (kept words ×1.61 per admissible n, `bases/RESULTS.md` §2).
- What base 65 adds beyond it is what the study said it would: tops ×7.6 more per admissible n (one root class) and
  more survivors (4.40e-6 against 2.63e-6 per admissible n), here without a prefilter.
- Width at base 64 (+3.7 %) is not bisected; the candidates are the fifth digit word (maxpop 17 > 16), 7-bit field
  extraction, `% b` child digits and the device key's read-back (≈ 0.05 s per field).

## 5. Base 68

- Exact on slices 123456789 and 634515713 (the range's start) on the final code (above). Its jobs reach 3.5k–6.3k
  probes: 12 instances of 576 probes ran without a PMAX error on those slices and on 3 whole fields. Every instance
  re-runs the bottom side.
- Two whole fields on the final code: 2.129 fs per admissible n warm (121 ms per slice), 2.187 cold. Not broken
  down by stage. Per slice it holds 89M prefixes, 8.1M tops, 143M survivors (all checked, no prefilter).
- **Will not launch on Vulkan**: its tops grid is b·nlead / 256 = 348k cubes in x, legal on CUDA, over the usual
  65,535 of Vulkan (lavapipe, RADV). Needs a 2D grid (§7).

## 6. What is not proven

- **No lavapipe run at base 68** (grid above) and none at W 16 / W 64 (lavapipe W 16 aborts in day one's kernels;
  no AMD card). The RX 9070 XT has not run the wide path.
- **Exactness at b65 rests on 5 slices** (both range ends included) of 274,625 × 4,225, plus the staged one; at b68
  on 2 slices. Whole fields pass every account but have no independent reference.
- **Bases 69 and 70 have not run.** b69 is b68's code with 193M prefixes per slice (a 3 GB prefix table); b70's study
  shape (4, 11) needs a 64-bit slice value (70^6 > 2^32), refused today.
- `maxpop` per base (b65 18, b68 19) comes from the study's samples; a top with more digits stops the field with an
  error (never seen in 12 whole b65 fields and 1 b68 field); it cannot lose survivors.
- The b65 stage table mixes the stops' cold field with the full run of a warm one (±2 %), on the first code.
- No baseline above 64 measured (production has no join there). Ratios against "today widened" stay the study's
  projection [D]: against its central 22.9 fs, b65's 3.48 would be ×6.6.

## 7. Next, in order of value

1. **Tops at b65 (0.69 fs, 20 %)**: the top hierarchy (piece C) is worth more here than at 64 (one root class: tops
   cost ×7.6 more per admissible n); or incremental limbs (consecutive leads differ by a constant).
2. **Prefilter before the check (0.54 fs at b65)** and the expansion (pieces A, B), ported to the wide path.
3. A 2D tops grid (Vulkan at b68+) and a 64-bit slice value (b70 (4, 11)); then b69 and b70 on one slice each.
4. Bisect the +3.7 % at b64 only if the wide path is ever wanted there (the narrow path stays).

## 8. Merging with the trunk

- `gpu_wide.rs` shares no code with `gpu.rs` except `gpu::FieldTiming`: the trunk's changes to the expansion,
  prefilter and tops of `gpu.rs` merge without a conflict. `mod.rs` gains one `pub mod` line, `coord.rs` one match
  arm, `common/Cargo.toml` one example entry.
- Whatever the trunk changes in the narrow main kernel, record format, expansion or check must be ported to
  `wide_kernel`, `wexpand_kernel`, `wcheck_kernel` by hand; the module documentation lists every widening. A
  prefilter that holds digits in one u64 (production's) needs the second word.
- **For the trunk's narrow path:** take the `C_JOBS` account (a CUDA allocation failure turned whole fields into
  `survivors 0 = checked 0` without an error; production's client may share the exposure, not checked); and pad an
  empty top mask with a zero row, not digit 64, if the narrow kernel is ever run at small bases.
- A client route would pick the path per base (b ≤ 64 narrow, 65–70 wide); both return `FieldOutcome`.

## 9. Commits (`dev/mo-wide`, on `7ba982c7`)

| commit | what |
|---|---|
| `2eddb54d` | the wide device path (`gpu_wide.rs`), the bench example, coordinates for bases 68–70; exact at b30–b65 slices |
| `fb6962ea` | job-instance account (`C_JOBS`) after the allocation-failure surprise; base-68 capacities |
| `415d3483` | survivors of clipped tops; zero pad row for empty top masks; whole-small-bases brute-force test |
| `a8a76315` | clippy (no semantic change) |

The tested binaries were built from the box's tree synced from ivory between commits (scp of the changed files);
the final tree was then moved by bundle and checked: the box's checkout of `a8a76315` is clean. The CUDA and lavapipe
verification binaries are of `415d3483`'s source before `cargo fmt`; `a8a76315` differs from it by formatting and
three clippy rewrites (an `Ok(...?)` and two `if let Ok`), no change of behaviour.
Not used: `m4_aborted/` (a concurrent build on the box) and `v2_badpath/` (a script picked a `.d` file as the test binary).
