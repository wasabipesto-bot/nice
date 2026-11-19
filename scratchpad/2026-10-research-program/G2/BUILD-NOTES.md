# The middle-out join, build day 1 (2026-11-18, 16:43–22:30 UTC), step 2A (19:05–23:45 UTC), step 3A (2026-11-19, 01:25–05:15 UTC) and step 3W (03:07–06:00 UTC)

Briefs: `G2/BUILD-BRIEF-1.md` (day one), `G2/BUILD-BRIEF-2A.md` (step 2A: pieces B, A, C of §7), `G2/BUILD-BRIEF-3A.md`
(step 3A: accounts that prove the work ran, from the audit `G2/AUDIT-MO.md`). Branch
**`dev/middle-out-join`** (from upstream main `be9cc923`), worktree `~/projects/nice/.worktrees/midout`, pushed to the
fork only. Box: Vast 61286074, RTX 3080 at the host's 240 W cap, i9-9900 with a **5.12-CPU cgroup quota** (16 threads
visible), CUDA 12.8 image, Mesa 25.2.8 lavapipe. Box scripts and raw logs: day one `G2/build1/box/`, `G2/build1/raw/`;
step 2A `G2/build2a/box/`, `G2/build2a/raw/`; step 3A `G2/build3a/`. Step 2A's account is §9; step 3A's is §10
(the accounts, the fault switches before and after, the cost, its tests in §10.7); step 3W's (`G2/BUILD-BRIEF-3W.md`: the merge of the wide branch, its accounts and speed work, the base-65 number) is §11, raw logs `G2/build3w/`; section 1 is current for it.

## 1. Where it stands (kept current)

**2026-11-19 ~05:00 UTC, end of step 3W: one trunk.** Branch head **`4abfab5c`** on ivory and on
`fork/dev/middle-out-join`. `dev/mo-wide` is merged (`23ce3cf6`); there is no other live branch of the join. Still
nothing outside `common/src/midout/`, the examples `midout_bench.rs` and `midout_wide_bench.rs`, one line of `lib.rs`
and the two example entries in `common/Cargo.toml`; no route reaches it; no server, schema or API change.

- **Two device paths, one library.** Base 64: `midout::gpu` (64-bit masks; `search_field`). Bases 65–70 (and any base
  3–70 in tests, base 64 forced): `midout::gpu_wide` (two-word masks; `search_field_wide`). A client route would pick
  the path per base. Both return `FieldOutcome` with the same counters (`survivors`, `checked` = after production's
  middle-digit prefilter).
- **Both paths prove their work ran** (§10 for the narrow path, §11.2 for the wide): per-slice accounts, the two
  conservation laws, a done word per slice, guards, `MIDOUT_STOP` out of the library, the sampled CPU check. On the
  wide path every applicable fault (dropped main kernel, dropped tops, dropped probe, dropped parent, failed device
  allocation, `MIDOUT_STOP` in the environment) is loud by test at base 65, at base 64 forced wide and on lavapipe
  W 8; a wrong parent and a too-strict prefilter pass the accounts and are caught by the sampled check, as on the trunk.
- **The wide path has the trunk's speed work** (§11.3): the top hierarchy and the prefilter before the check, exact
  against brute force (bases 10–25), the CPU reference (b30–b65 slices incl. both range ends; b64 forced) and the
  narrow path's counts at b64.
- **The numbers** (this box, 240 W cap, same session, §11.4): base 64 narrow **1.710 fs** per admissible n; base 65
  wide **3.561 fs = ×2.08** of base 64 (last night ×2.04 on an uncapped card before the accounts; the accounts cost
  the wide path ~+9 %, the speed port gave back −7.8 %); 0.49 card-years for base 65. Base 64 against main: ×3.91
  without the sampled check (§10.6). The sampled check is affordable at b64 (+0.4 %) but **not at b65** (its CPU slice
  takes 93 s against a 56 s field); it is off by default on the wide path.
- **Not run / not proven**: base 68 since the merge (does not fit this 10 GB card; its exactness is last night's two
  slices on the wide branch, `BUILD-NOTES-WIDE.md`), bases 69–70, the staged-prototype test at b65 (staged slice lost
  with the wide branch's box), lavapipe W 16, W 64 / the RX 9070 XT, any client route.
- *Step 3A's account of the narrow path (§10) and step 2A's (§9) are unchanged and still true.*

## 2. The interface: what a field is, and what it permits and forbids

**A field is `(base, v_start, v_size)`** in a per-base coordinate `v` (`common/src/midout/coord.rs`, the only piece
that would ever reach the server; it knows nothing of the join):

    n = h·b^k1 + key·b^k0 + low            key = digits [k0, k1) of n,  low = n mod b^k0,  h = n div b^k1
    v = start + key·(H·b^k0) + (h − h0)·b^k0 + low

- `h0 = start div b^k1`, `H` = the number of values of `h` in the base's range. `v` is one to one from the range into
  `[start, start + H·b^k1)`; the rest is padding (`n_of_v` returns `None`).
- **Base 64** (`k0 = 4, k1 = 9`): exactly PROPOSAL §2's bit renumbering (π′ = bits 24–53 of n moved to bits 45–74),
  no padding (`H = 2^21`). Tested on 10,000 random n and both ends against the formula of §2.
- **Base 65** (same digits): the padded form of `bases/RESULTS.md` §5, here padded at `b^9` granularity (§5 padded
  at `b^10`): `H = 13,410,973`, padding 9.5e15 of 2.78e23 n (0.03 ppm), quantum `H·65^6 = 1.011e18`, 65³ quanta.
  Test `b65_padded`: bijection at the ends, quantum counts sum to the range. Defined only to show the form fits.
- **A field must be whole quanta**: `v_start − start` and `v_size` multiples of `quantum = H·b^q0`. One quantum is
  exactly the n whose digits `[q0, k1)` take one value t; a field is the n whose digits `[q0, k1)` lie in a range
  `[t0, t1)`, **every other digit free**. Base 64: `q0 = 6`, quantum 2^57 (262,144 fields per base, about 33 s each
  on a 3080 today), a field fixes digits 6–8.
- `range_size` (what the server sums) is `n_count(v_start, v_size)`, the n the field holds; equal to `v_size` at 64.
- **The contract**: a search of a field may rely on the *set* (digits `[q0, k1)` in `[t0, t1)`) and nothing else. The
  order of v inside a quantum, and the digits `[k0, q0)`, are not part of it; k0 only fixes how v is written, and a
  join is free to cut a field however it likes.

**How the join meets it** (`midout/cpu.rs`, `Shape`): the join chooses its shape `(f0, k)` per coordinate
(`Shape::for_coord`: (4, 10) at base 64) and checks `Shape::fits`: `f0 <= q0` and `k1 < k` (the field's fixed
digits lie inside the slice's `[f0, k − 1)`), so a field is a whole number of slices (4,096 at base 64). Nothing
outside `midout/` sees `(f0, k)`, the slice key, the chunking, the kernels or the slab layout. Results carry the
shape's label because the counters below are properties of (shape, field).

**What a field of this kind permits** (each changes only code inside `midout/`, never a field row):

1. Any shape with `f0 <= 6` and `k >= 10` at base 64: tops down to digit 3–6, bottoms of 10–12 digits, a slice key
   that is any window `[f0, k − 1)` containing 6–8 (shown: the CPU reference searches the same small-base fields
   with two shapes and gets the brute-force answer with each, `whole_small_bases_vs_brute_force`).
2. Any chunking, key, sort, kernel, plane width, mask width, top hierarchy, prefilter, or device: the field only
   names a set of n.
3. Work shared across slices *inside* a field: a field holds 64² values of digits 4–5 for each fixed digits 6–8, so a
   join may build tops' certificates at f0 6 once per field and refine them per slice (the top hierarchy), or share
   parents across the 64 slices that differ in digit 4. Today's code shares nothing between slices.
4. Work shared across *fields* on one client (the 9.3M depth-4 roots are built once per process today).
5. Splitting one field across devices or resuming it part-way (slices are independent and their counters add).
6. Bridges and mixed bases: base 64 fields are a partition of the base; other bases are untouched.

**What it forbids** (would need new fields or a re-cut):

1. A join whose slices are *coarser* than a field in the fixed digits, i.e. that needs digits 6, 7 or 8 to vary
   inside one unit of work (a shape with `k <= 9` or `f0 >= 7` at base 64: its bottoms or tops would be rebuilt per
   field, 262,144 times per base, which is the cost that killed contiguous fields for G2, RESULTS §7).
2. Any search that needs a field to be an interval of n: today's overlap join (its tops are intervals of n), the
   stride path, "searched up to n = X" statements, interval queries on the fields table for base 64.
3. Fields smaller than a quantum (2^57 at base 64) without a coordinate change: a v-range inside a quantum is not
   a set the join can search slice by slice (it would cut through h, the leading digits).
4. A different coordinate for base 64 once fields exist (the v of every searched field would change meaning).
   The coordinate is the commitment; choose `q0` (how many digits a field fixes) with that in mind: `q0 = 6` keeps
   fields 4,096 slices deep, so the join keeps two free digits (4, 5) to move its slice key and share work.

## 3. Design decisions and why

- **The coordinate is general, the base-64 instance is PROPOSAL §2's.** One formula with three digit positions
  (`k0, k1, q0`) covers 64 (exact) and every padded base; small bases get explicit positions in tests. The join's
  shape is *not* derived from the field: `Shape::for_coord` picks (k0, k1 + 1) as a default and `fits` is the only
  coupling, so changing the shape is a one-line, test-covered change.
- **`q0 = 6` at base 64** (the brief's "6–8"): a field is 4,096 slices (≈ 33 s on a 3080 today); 2^57 as PROPOSAL
  §2 sized it. Fixing 7–8 only (2^63 fields, 64× larger) would also be legal; fixing 5–8 would forbid the
  shape changes in §2 item 1 that move `f0` to 5–6 *and* any top hierarchy across digit 5.
- **Two exact counters, defined as production's** (`FieldOutcome`): `survivors` = the n of the field that pass the
  join's predicate (n's class is a root mod 63, its top and bottom certificates are valid and disjoint, n is in its
  top's interval) — production's `survivors`, for this shape; `checked` = the n the full check examined —
  production's `checked` (survivors after the prefilter). Since step 2A the prefilter runs (§9.2), defined once in
  `cpu::prefilter` and mirrored on the device; the device proves per launch batch that the expansion read every
  survivor the kernel counted and that the check took every entry listed (its own count and index sum). Both are
  functions of (shape, field) only: equal on CPU and on every device, but not comparable across shapes or with
  today's join; telemetry would carry the shape label (`Shape::label`).
- **CPU reference generic over the mask word** (`Mask` for `u64`, `u128`): bases above 64 run through the same code
  (item 5). The device path is `u64` and base 64 only; a wide device path is a second instantiation, not a rewrite
  (§7, piece W).
- **Tops on the device, not the host.** The plan was host tops in parallel with the card; the box's cgroup quota is
  5.12 CPUs (16 threads visible): host tops measured 91 ms per slice on one thread, 18–19 ms per slice on all of
  them, against 5.4 ms of main kernel. Fleet boxes are the same kind of host. New kernels `dtops::tops1/tscan/tops2`
  (certificate by 32-bit limbs and shifts; count, scan, scatter into segments) cost 0.46 ms per slice.
- **The kernel's key from the field's first slice.** The 8 key digits only order the parents (any key is exact);
  the port computed them per slice from all parents and tops. The driver computes them once per field on the host
  from that field's first slice (tops + a 1/16 sample of parents). Kept fraction on slice 1 with the field key:
  0.1963 against 0.1960 with its own key (`kept` 38,533,873 vs 38,501,362) — noise.
- **Jobs past PMAX probes run twice.** The port's probe table holds 576 probes; 1 slice in 1,024 sampled has a job of
  587 (slice 318575442), which the port's kernel would have counted as an error. Every job is queued as two cube
  instances (probes [0, 576) and [576, 1,152)); the second exits at once unless it has probes, counts no children or
  chunks, and its records carry the probe offset. More than 1,152 probes is still an error (never seen; the mean
  is 473).
- **Records name their top and chunk position, and phase 1 writes the child lists.** The port's record held the
  chunk's first parent and the host re-walked the parents to expand it. (Day one's record named its job and probe slot;
  since step 2A it holds the top's index, carried in spare bits of the probe table, and the chunk's absolute position
  in the child lists: §9.1.) The library path needs the survivors on the
  device: phase 1 now writes each certified child's r4 at its position in its job's list (one store per child,
  +0.13 ms per slice), and a record holds (probe slot + offset, unit, class; first list position of its chunk). The
  expansion (`post::expand_kernel`, grid-stride over used slabs) then needs no search. The first version (separate
  ordered child-list kernel + binary search) cost 3.2 ms per slice; this one 0.92 ms.
- **Production's check, fed in production's layout.** n = P·64^5 + r0 with `r0 = n mod 2^30` (the child's r4 and
  digit 4) and `P = n div 2^30 = h·2^30 + d·2^24 + (π′ >> 6)`, which depends on the top only: one 8-word top record
  per top (`toprec2_kernel`), one 2-word list entry per survivor, `CheckShape::new(64, 13, 26, 38, 5, 10, 10)`.
- **One stream, no per-slice synchronisation.** Slices are queued back to back; buffers are allocated once and reused
  (the stream orders reuse); per launch batch only four small counter buffers are created. One synchronisation per
  group of 16 slices reads the counters and checks every account; a failed account is an error, never a field with
  fewer candidates.
- **Launch batches of classes** (`Caps::classes`): 63 (one batch per slice) on CUDA; 4 on lavapipe, whose 128 MiB
  binding limit the records and child lists exceed otherwise.

## 4. Reused from production, and new

**Reused unchanged from production** (`common/src/`): `cubecl_join::check_kernel` (the full check, with its
completeness account in `ran`), `join_check::CheckShape` and `GATE_DIGITS`, `cubecl_join::{TOP_REC_WORDS,
CHECK_HITS, ballot_append}`, `base_range::get_base_range_u128`, `cubecl_backend::CubeclContext`. Production's
check-kernel grid constants and `RAN_WORDS` are private there and copied as constants (2048 cubes of 256; 9 words).
No production file was changed except `lib.rs` (`pub mod midout;`) and `common/Cargo.toml` (the bench example).

**Moved from the G2 port** (`common/examples/g2_cubecl.rs` at `1313018a`, branch `g2-cubecl-local`, into
`midout/gpu.rs`): the main kernel (form D: shuffle transpose, ept 2, ballot ranks, common masks from registers,
`tdig` per slice) and the preparation kernels `hist2`, `scan16`, `scatter3`, `hsort`, `tdigz`. Changes inside the
main kernel, all marked `midout`: the job word (unit | probe offset << 8), the probe window, the second instance's
early exit and counters, the child-list stores in phase 1, and the record's words 0–1.

**Not reused, and why**: production's `top_fd_kernel` (bound to its partitions, slot groups and record layout; a
b64 certificate kernel for 2^21 prefixes was simpler to write and test than to adapt); production's middle-digit
prefilter (it lives inside `join_kernel`'s walk; day one checked every survivor, 0.57 ms per slice). Step 2A
re-implements the same test in the expansion (§9.2): production's is fused into its join's walk with per-entry and
per-top terms that our records do not carry.

**New** (all under `common/src/midout/`, 3,4xx lines with tests; `common/examples/midout_bench.rs`):
`coord.rs` (the work unit), `arith.rs`, `mask.rs`, `cpu.rs` (the reference: certificates, bottoms, parents,
slice join, field search, brute-force predicate), `gpu.rs` (device tops, record expansion, top records, host tops by
shifts, the driver `GpuJoin` and `search_field`). No new dependency.

## 5. Tests and results

All on the box (Vast 61286074), release builds. Day one's table first (from `7ba982c7`; raw: `build1/raw/final_tests.log`,
`lvp_*.log`, `staged_*.log`), then step 2A's (from the commits named; raw: `build2a/raw/`). Times are per run.

| test | what | result |
|---|---|---|
| `coord::b64_is_the_bit_renumbering` | v = PROPOSAL §2's formula and back, 10,002 n | pass |
| `coord::b64_quantum_fixes_digits_6_to_8` | quantum 2^57, digits 6–8 constant, misaligned fields refused | pass |
| `coord::small_bases_bijection_and_counts` | 9 bases (all classes): bijection, padding, per-quantum counts = direct | pass |
| `coord::b65_padded` | padded base: bijection at the ends, 65³ quanta sum to the range | pass |
| `arith::known_nice_and_roots` | 69 nice at b10; roots of 64 | pass |
| `cpu::whole_small_bases_vs_brute_force` | bases 10, 12, 13, 14, 17, 18, 19, 20, 22, 24, 25; 1–2 shapes each; every field: survivors = brute-force predicate, no n twice, n in its field, nice = brute force (69), u64 = u128 masks | pass (13 s) |
| `cpu::shapes_that_do_not_fit_are_refused` | `fits`, 4,096 slices per b64 field | pass |
| `cpu::b64_slice_vs_staged` (ignored; `MIDOUT_SU_DIR`) | slices 712012851 and 391856203: every unit's survivor set = the staged `surv.bin`; counts = the port's (children 33,705,647, chunks 528,635, flat 250,486,772, kept 123,163,397, survivors 11,768,560) | pass, both (20 s each) |
| `gpu::top_cert_b64_equals_the_reference` | host b64 certificate = reference on 20,000 prefixes | pass |
| `gpu::slice_tops_equal_the_reference_units` | host tops of 3 units = reference; 238,813 per slice | pass |
| `gpu::gpu_slices_equal_cpu` (ignored), CUDA | slices 712012851, 318575442 (a 587-probe job), 391856203, 1, 1073741823: device tops = host tops; survivor sets equal n for n; children, chunks, flat, survivors, checked equal (kept too where the key matches) | pass |
| `gpu::gpu_check_rebuilds_the_survivors` (ignored), CUDA | production's check in probe mode rebuilds our 188,905 survivors (class 0 of 712012851) exactly | pass |
| `gpu::gpu_slices_equal_cpu`, lavapipe W 8, SPIR-V, 16 batches of 4 classes | whole slices 712012851 and 318575442 | pass (65 s) |
| same, lavapipe W 16 | — | **aborts** in lavapipe (bisected with `MIDOUT_STOP=11`: `tops1_kernel` alone; with host tops, the port's preparation) |
| field runs (bench) | 13 whole b64 fields: survivors = checked on every field, every account (kernel errors, caps, check count and index sum, listed = counted) passed; field 77777 at group 16 and 4: identical survivors (48,199,033,671) | pass |
| production suite | `cargo test --release -p nice_common --lib` (default features) on the branch | 214 passed, 0 failed, 10 ignored (as on main) |
| lint | `cargo fmt --all --check`; clippy `-D warnings` on `nice_common`, all targets, default and `cubecl-cuda,cubecl-spirv` | clean |

**Step 2A** (the tests are the same functions, extended; each piece's commit was tested before the next started):

| test | what | at | result |
|---|---|---|---|
| `cpu::whole_small_bases_vs_brute_force` | as above, plus: `checked` (survivors that pass `cpu::prefilter`) = the brute-force count (`q_checked`: the prefilter with the top's certificate from the definitions) on every base and shape; u64 = u128 masks for `checked` too; nice numbers (69) still found, so the prefilter dropped none | `60ff7c98` | pass (13 s) |
| `gpu::top_cert_b64_equals_the_reference` | also the prefilter's part of the certificate (positions >= 12): host `top_cert_b64_split` = `cpu::top_cert_split` on 20,000 prefixes | `60ff7c98` | pass |
| `gpu::slice_tops_equal_the_reference_units` | also each top's prefilter mask (host = reference, 3 units) | `60ff7c98` | pass |
| `cpu::b64_slice_vs_staged` (ignored) | slice 712012851 against the staged prototype (unchanged by the prefilter: every survivor is still reported) | `60ff7c98` | pass (27 s) |
| `gpu::gpu_slices_equal_cpu` (ignored), CUDA | the device's prefiltered list = the CPU reference's survivors that pass, n for n; survivors, checked, children, chunks, flat equal; device tops = host tops. B: 2 slices (`4291e56f`, `6ec998e5`); A: 3 slices (`60ff7c98`; 712012851: 337,904 of 11,768,560 pass, 2.87 %); C and the A follow-up: 5 slices 712012851, 318575442, 391856203, 1, 1073741823 (`9e4b99f1`, `03091f72`) | as stated | pass |
| same, host tops (`MIDOUT_HOST_TOPS`) | the host path's top records and prefilter masks | `60ff7c98` | pass |
| `gpu::gpu_check_rebuilds_the_survivors` (ignored), CUDA | production's check in probe mode rebuilds exactly the list it is given (class 0 of 712012851: 5,413 entries after the prefilter) | `03091f72` | pass |
| `gpu::gpu_slices_equal_cpu`, lavapipe W 8, SPIR-V, batches of 4 classes | whole slices 712012851 and 318575442: tops, lists, all counts | `03091f72`, `91ac0761` | pass (69 s each) |
| `gpu::gpu_slices_equal_cpu` and `gpu_check_rebuilds_the_survivors`, CUDA, after the last commit | the 5 slices above; the check's probe mode | `91ac0761` | pass |
| field runs (bench) | the 10 fields of §6: survivors equal day one's field for field (e.g. t 13107: 48,211,413,201); checked 1,382.7M–1,385.4M per field (2.87 %); every account passed; field 77777 checked 1,384,147,294 at every step from A on | `03091f72` | pass |
| production suite | `cargo test --release -p nice_common --lib` (default features; the later commits touch only `midout/gpu.rs`, which the default build does not compile, and a doc comment) | `03091f72` | 214 passed, 0 failed, 10 ignored |
| lint | `cargo fmt --all --check`; clippy `-D warnings`, all targets, default and `cubecl-cuda,cubecl-spirv` | `b55b48be`, `91ac0761` | clean |

## 6. The number

**Measured** on Vast 61286074 (RTX 3080, host power cap 240 W, i9-9900 with a 5.12-CPU quota), one session,
2026-11-18. Both runs sat at the cap: main 239 W at 1,696 MHz mean SM clock (167 busy samples), the middle-out
join 239 W at 1,562 MHz (174 samples); max 71 °C. Raw: `build1/raw/out_m1.jsonl`, `client_m1.log`, `smi_m1.csv`,
`mo1.log`, `mo2.log`, `smi_mo2.csv`.

| run | what | time | fs per admissible n |
|---|---|---|---|
| **main** `be9cc923` (`nice-main` md5 `c2d248f5`), 17:54–18:08 UTC | real client, local stub, 10 b64 1e17 n-fields at 0.05…0.95 of the base (the window's set) | 840.0 s | **6.615** (morning, another 3080 box: 6.619) |
| **middle-out** `7ba982c7` (`mo_bench_7ba` md5 `b44a47ef`), 18:35–18:41 UTC | 10 whole b64 fields t = 13107 … 249036 (0.05…0.95), 2^57 n each, group 16 | 320.6 s (30.9–33.0 s per field) | **1.752** |
| middle-out, earlier the same session | 3 fields (t 4095, 77777, 200000), `96aa0909`, 18:19–18:21 UTC | 96.2 s | 1.751 |
| **step 2A: middle-out** `03091f72` (`mo_bench_0309` md5 `3d041381`), 20:40–20:45 UTC | the same 10 fields, group 16 | 303.95 s (30.1–31.6 s per field) | **1.661** |
| **step 2A: main** `be9cc923` (the same `nice-main`), 20:46–21:00 UTC | the same 10 n-fields, real client, local stub | 840.0 s | **6.615** |
| **step 2A: middle-out, head** `91ac0761` (`mo_bench_head` md5 `51cef178`), 21:31–21:36 UTC | the same 10 fields, group 16 | 301.35 s | **1.647** |
| **step 2A: main, at the end** `be9cc923`, 21:42–21:57 UTC | the same 10 n-fields | 840.0 s | **6.615** |

**Ratio ×3.78** (6.615 / 1.752) on day one, end to end with tops and survivor checks on the card. Against the
example's measured ×4.61 at 1.322 + 0.115 fs, the difference is the per-slice work it did not run. **Step 2A: ×4.02**
at the head (6.615 / 1.647; ×3.98 at `03091f72`), one box session (the box has run since 16:42; main measured 6.615
three times today, 18:08, 21:00 and 21:57, to 0.1 s), all at the 240 W cap: main 239 W at 1,694–1,700 MHz mean SM
clock (167 busy samples each run), the middle-out join 239 W at 1,561 MHz (60 samples); at most 71 °C.

Per slice (4,096 per field), from cumulative stops on one field (`MIDOUT_STOP`, `96aa0909`): tops 0.46 ms;
parents (the port's preparation) 0.66; main kernel incl. the child-list stores 5.44; expansion 0.92; check 0.57;
total 8.05 ms = 1.80 fs (that field). The main kernel + preparation, 6.1 ms, equals the port's 1.322 fs measured
this morning on the same kind of box (6.0 ms): moving it into the library cost nothing. Host time is hidden (the
driver waits on the card 30.5 of 31.7 s).

**Estimated, not measured:** the 9070 XT. By the window's own method (the card's main base 4.71 fs, the example's
pipelined D 0.77 fs) plus this day's measured extra 0.45 fs × (4.71 / 6.62) ≈ 0.32 fs: ≈ 1.09 fs, **≈ ×4.3**. It
rests on CUDA's cost ratios carrying over, which the window showed they do not always.

## 7. Work breakdown for the next days (independent pieces)

Each piece names its files, its interface to the others, its test, and whether it needs a card. The interfaces are
the three that exist now: **`Coord` + `(v_start, v_size)`** (the field), **`FieldOutcome`** (nice, survivors,
checked), and inside the device path **the records** (main kernel → expansion: top index, absolute child-list
position, the 64-pair word) and **the survivor list** (`(top, r0)` entries + one 8-word top record per top,
production's layout) between "expansion" and "check". Pieces touching different sides of those can run in parallel.

**Revised after step 2A** (§9). Done: **A** (prefilter, `60ff7c98` + `03091f72`), **B** (expansion without the probe
walk, `6ec998e5`; its first form `4291e56f` is superseded), **C** (top hierarchy at the 64-slice level, `9e4b99f1`;
the per-field level was not built: it would save 1/64 of a certificate pass per slice, under 0.01 ms). Per slice now
(field 77777, the 3080): tops 0.36, parents 0.67, main kernel 5.46, expansion + prefilter 1.11, check 0.12 ms.

| # | piece | files | interface | test | card? | worth (estimated) |
|---|---|---|---|---|---|---|
| D | **Main-kernel items left from the port** (8-byte records, root pass, LDS diet) and the 9070 XT window for the whole path; now 71 % of a slice | `midout/gpu.rs` (kernels) | records | `gpu_slices_equal_cpu` on CUDA + lavapipe W 8, then RADV W 64 | yes; AMD window | the largest: 10 % of the kernel is 0.55 ms |
| K | **What bounds the expansion** (1.11 ms for 10.9M records, against about 0.25 ms to read their 175 MB at the card's bandwidth): §9.3 rules out the probe walk, the single atomic, the child-list gathers alone, the grid size and the batch width; next, the probe build of §9.3 (records only / + gathers / + prefilter) on a card with counters, then e.g. a per-record thread layout without the plane-take loop, or the prefilter's per-child terms carried in the child list | `midout/gpu.rs` (post, maybe phase 1) | records → list | `gpu_slices_equal_cpu`, probe-mode check | yes (a card with profiler access helps: Vast refuses counters) | up to 0.6 ms (×4.3 with nothing else) |
| L | **Parents' preparation** (0.67 ms per slice, the port's hist2 over 9.3M roots): roots valid at depth 5 per value of digit 4 (about 75 % of them), slices run digit-4-major with the 64 level-5 top lists of C kept per field (≈ 100 MB) | `midout/gpu.rs` (prep, driver order, dtops) | parents (unchanged) | `gpu_slices_equal_cpu` | yes | ≈ 0.15 ms |
| E | **Wide masks (b65–70)**: in progress on `dev/mo-wide` (another engineer); step 2A added `thm`/`tmhi` (the prefilter masks) and `l5` (the hierarchy) to the device tops and a 64-bit prefilter: both need the wide form there | `midout/gpu.rs` or `gpu_wide.rs` | same `GpuJoin` surface | CPU reference (`search_field::<u128>`) vs device on b65 slices | yes | (bases) |
| F | **Local coordinator + client route** (C′ of PROPOSAL, no server change) | `client/src/main.rs`, `gpu_route.rs`, a stub script | `search_field` | stub end to end on one field; refusal tests | lavapipe enough | (route) |
| G | **Audit tool**: CPU reference per slice recomputes random slices of a submitted field and compares `survivors` and now `checked` | `midout/cpu.rs`, `scripts/` | `FieldOutcome`, `Counts` | against the device on the same slices | no | (trust) |
| H | **Driver overheads**: measured small now (`MIDOUT_STOP=10`, every buffer made and nothing launched: 0.18 s per field, 0.04 ms per slice) | `midout/gpu.rs` (driver) | `search_field` | field counts equal at group 1, 4, 16 | yes | < 0.04 ms |
| I | **lavapipe W 16** crashes (Mesa 25.2.8): bisect per kernel on ivory's `lvp26` container (Mesa 26.0.8) | none, or a kernel rewrite | — | lavapipe W 16 parity | no | (coverage) |
| J | **The coordinate decision** (`q0`, base 65's form) for the owner | `midout/coord.rs`, notes | `Coord` | `coord` tests | no | (decision) |

Order for one engineer now: D (by size), then K, then L. Around the kernel, the step-2A target (×4.4 on this box)
needs about 0.8 ms more per slice than B, A and C gave; K and L together are worth about that at best, so ×4.4 most
likely needs D as well.

## 8. What the design documents got wrong (or did not cost)

1. **"Tops and survivor checks 0.085–0.115 fs" (BENCH, PROPOSAL §1, WINDOW-RESULTS)** left out the step between
   them: the kernel's records name 64-pair words, not n, and something must turn 10.9M records per slice into 11.8M
   checkable entries on the device. Measured on the 3080 (one field, cumulative stops): tops 0.46 ms, expansion
   0.98 ms (3.2 ms in the first version), check 0.57 ms per slice: **0.45 fs, not 0.115**, of which the expansion
   is 0.22 and the unprefiltered check 0.13. Pieces A and B in §7 are where it comes back.
2. **The port's kernel was not exact for every slice**: its probe table (PMAX 576) is overrun by some jobs (587
   probes in slice 318575442; 1 slice in 1,024 sampled); the port counted an error and truncated. Fixed here by the
   second job instance. MAXPOP 17 is also exactly the largest popcount seen in 1,024 slices; an 18-digit top would
   now stop the field with an error, not lose survivors.
3. **Host tops in parallel with the card** (the shape of PROPOSAL §5 item 2's "roots and parents on the host" and
   the plan's fallback) does not work on rented boxes: a 5.12-CPU cgroup quota on a 16-thread host. Everything per
   slice must be on the device; the host should only queue.
4. **The record format** (BENCH, PORT-NOTES: "unit << 16 | probe slot, first parent of the chunk, word") cannot be
   expanded on the device without a search or a re-walk; the library needs (job, chunk position) and the child lists
   that phase 1 can write for 0.13 ms.
5. **bases/RESULTS §5's field sizes** ("a multiple of H·b^(f0+1)") align fields to super-units; a field that fixes
   only the central digits 6–8 is a multiple of `H·b^q0` instead (base 65: 1.011e18), which is what keeps the join
   free to change shape.
6. Not wrong but untested before today: the check kernel with (f0 5, k2 10) at base 64 (production uses other
   shapes); shown exact on CUDA in probe mode (`gpu_check_rebuilds_the_survivors`).

## 9. Step 2A: the cost around the kernel (pieces B, A, C; 2026-11-18 19:05–23:45 UTC)

Brief: `G2/BUILD-BRIEF-2A.md`. Same box, same rules. Method throughout: cumulative stops (`MIDOUT_STOP` 1 tops,
2 + parents, 3 + main kernel, 5 + expansion, 6 everything) on field 77777, each variant run minutes after the one it
replaces; per slice = seconds per field / 4,096. Field-to-field noise of these runs is about ±0.1 s per field
(±0.03 ms per slice). Every number here is **measured** on the 3080 at its 240 W cap unless marked estimated. Raw:
`build2a/raw/stops_*.log` (one file per variant), `build2a/raw/*_tests.log`, `mo2a.log`, `mo2b.log`, `smi_*.csv`,
`out_m2.jsonl`/`out_m3.jsonl` (main); scripts `build2a/box/` (`stops.sh`, `run_mo.sh`, `final.sh`, and the edit
scripts that made each uncommitted variant, e.g. `v2.py`, `xm.py`, `fuse.py`).

### 9.1 B, the expansion

- **First form, committed and superseded** (`4291e56f`): the main kernel writes list entries `(top, r0)` itself into
  plane-private slabs (the child's r4 read from the child list, a device-memory barrier for SPIR-V), and a
  compaction pass packs the slabs. Exact, but the main kernel costs 1.2 ms more per slice (stop 3: 31.72 s against
  26.72 s per field) for 0.67 ms less after it. A store-only variant (the entry holds the child's list position; the
  compaction reads the r4) cost the kernel as much (stop 3: 31.23 s) and the compaction 0.7 ms: not committed. So the
  kernel's cost is not the loads but the work per output step: per-bit loops, two plane scans and slab bookkeeping
  at every step with an output, against two ballots and one vector store for a record (estimated ~140 against ~30
  warp instructions per step, on ~4M such steps per slice).
- **Kept** (`6ec998e5`): back to the records, which now name their top (its index rides in spare bits of the probe
  table's word 3: the kernel reads 17 digits of 20) and their chunk's absolute position in the child lists. The
  expansion reads the record and the child's r4, nothing else (no 8-segment probe walk, no class or job arithmetic).
  Expansion 3.94 → 3.66 s per field: **−0.07 ms per slice**.

### 9.2 A, the prefilter before the check

- **Definition** (`cpu::prefilter`, the device mirrors it): for a survivor n of shape k, the digits at positions k
  and k + 1 of n² and n³ (10, 11 at base 64) are four distinct digits that miss the bottom's (positions 0..k) and the
  top's certified digits at positions ≥ k + 2 (`mhi`). Production's test is the same at the same digits, except that
  it uses the top's certificate only when its seed flag says all of it sits above k2; ours always uses the part above
  k + 1, which is sound for every nice n (those digits are digits of n² and n³ at other positions) and at least as
  strong. `checked` therefore means what it means in production (survivors after the middle-digit prefilter), with
  the shape label as before. 2.87 % pass (337,904 of 11,768,560 on slice 712012851; 1.38G of 48.2G per field).
- **Device** (`60ff7c98`): the tops carry `mhi` (device `cert_pow` returns it; tops2 writes it per top; host
  `top_cert_b64_split`; CPU `top_cert_split`); the expansion forms n mod 2^72 from r0 and the top's P (from `thd`
  and the slice's digits), squares and cubes it mod 2^72, and tests the 24 low digits at once (the bottom's 20 are
  distinct already); only passing entries are listed. Variants measured on the way: masks in the top record's words
  2–3 (words the check does not read) 5.36 s per field for the expansion; dense `thd` + `tmhi` arrays 5.10 s (kept);
  the bottom's mask from the parent instead of from n (child lists hold parent indices, the expansion gathers 16-byte
  parent records) 7.16 s (dropped). Follow-up (`03091f72`): the arithmetic in 32-bit limbs and the digits as a
  one-hot pair of 32-bit words, one loop over a record's 64 bits: 4.63 s.
- **Net:** the check 2.42 → 0.52 s per field (−0.46 ms per slice), the expansion +0.24 ms (with the follow-up): with
  B, expansion + check 1.54 → 1.23 ms per slice.

### 9.3 C, the top hierarchy, and what was tried and dropped

- **C** (`9e4b99f1`): once per 64 slices (one value of digits 5–8) `tops5_kernel` certifies every prefix n div 2^30
  over its 2^30 n and lists the valid ones (19.4 %: ~406k of 2^21); a slice's tops are certified only under them
  (tops1/tops2 grid-stride over the list). Exact by containment (a sub-interval's certificate holds its parent's
  digits). Tops 0.466 → 0.361 ms per slice (same session). What is left of the tops (bisect, `MIDOUT_STOP=10…13`):
  certificates 0.17, scan 0.025, scatter 0.04, digits + top records 0.08, fixed (buffers, syncs, no kernels) 0.04 ms.
  The per-field level (f0 6) was not built: it would save 1/64 of one certificate pass per slice, under 0.01 ms.
- **Dropped as neutral or worse** (not committed): fusing the digits and top records into tops2 (31.42 against 31.57
  s per field, noise); single-bit records carrying the child's r4 (gathered in the kernel): kernel +0.3, expansion
  +0.14 ms; expansion grids of 1,024 and 16,384 cubes (32.12 and 31.47 against 31.55 s); the expansion's atomic
  spread over 64 counters (timing only: 4.84 against 4.63 s, so the single atomic is not what bounds it); launch
  batches of 21, 9, 3 classes (32.19, 35.15, 47.59 s against 31.6 s at 63); one-bit records carrying the child's r4
  again with a single prefilter call (kernel +0.32, expansion −0.10 ms); the top's `thd` and prefilter mask merged
  into one 16-byte record per top (expansion 4.73 against 4.63 s).
- **A probe of the expansion** (a timing-only build, `XM`; `build2a/raw/xm.log`, stop 5 − stop 3 on field 77777):
  reading the records and running the takes with nothing else, 0.32 ms per slice (close to reading 175 MB);
  adding the top loads and the child-list gathers, without the prefilter or any write, 0.94 ms; everything, 1.17 ms.
  With the experiments above (neither the child gathers alone, −0.10, nor the top loads' layout, 0, nor the atomic
  account for it), the likeliest reading is latency: each take is a chain of dependent loads (record → top → child
  r4 → prefilter → atomic → write) with too few of them in flight. **Kept on that reading** (`91ac0761`): two
  records per lane and take, their loads issued together: expansion 4.52 against 4.63 s per field; A/B on two fields
  twice, 61.28 and 61.38 s against 61.58 and 61.82 s (−0.6 %, −0.05 ms per slice). Four records per lane: neutral
  (61.16 and 61.25 s against 60.85 and 61.36 s), dropped.

### 9.4 Before and after, the number, and why not ×4.4

Per slice, field 77777, both binaries in one session (20:37–20:40 UTC, `build2a/raw/stops_final.log`):

| stage (cumulative stop) | before: day one `7ba982c7` | after: `03091f72` | change |
|---|---|---|---|
| tops (1) | 0.466 ms | 0.361 ms | −0.105 (C) |
| parents (2) | 0.652 | 0.671 | +0.02 (same code: noise) |
| main kernel (3) | 5.400 | 5.459 | +0.06 (record words only: noise or the extra word work) |
| expansion (5), with the prefilter after | 0.959 | 1.108 | +0.149 (B −0.07, prefilter +0.22) |
| check (6) | 0.576 | 0.120 | −0.456 (A) |
| **slice** | **8.054** | **7.720** | **−0.334 (−4.1 %)** |
| around the kernel (1 + 5 + 6) | 2.001 | 1.589 | −0.412 (−21 %) |

Per piece, each against the step before it (§9.1–9.3): B −0.07, A −0.05 (check −0.43, expansion +0.38 in its first
form), C −0.13 (tops; −0.23 on the whole field), A's arithmetic −0.11, two records per lane −0.05 ms per slice.

**The number:** the 10 fields in 301.35 s at the head `91ac0761`, **1.647 fs** per admissible n (day one 1.752,
−6.0 %; `03091f72` 1.661), against main **6.615 fs** in the same session, run again at the end: **×4.02** (§6).

**Why not ×4.4:** ×4.4 against 6.6 fs is 1.50 fs, about 1.1 ms per slice below day one; B, A and C gave 0.4–0.45.
What is left around the kernel is 1.59 ms, of which the expansion with its prefilter is 1.11: it reads 175 MB of
records per slice (about 0.25 ms at the card's bandwidth) and runs the prefilter's ~150 instructions on 11.8M
survivors (estimated 0.15–0.25 ms), so ~0.6 ms of it is unexplained by the experiments above (piece K, §7). With the
expansion at that floor and nothing else changed, the slice would be ~7.1 ms, **≈ ×4.3 (estimated)**; ×4.4 needs the
main kernel (piece D) or the parents (piece L) as well.

## 10. Step 3A: accounts that prove the work ran (2026-11-19, 01:25–05:15 UTC)

Brief: `G2/BUILD-BRIEF-3A.md`; specification: the audit `G2/AUDIT-MO.md` (§1.1, §1.2, §1.3, §3, §4.1). Same box, same
rules. Commits: `7a9fd414` (merge of `dev/mo-audit`: the auditor's sweep, tops scan, fault switches and tests),
`197c1e94` (accounts, `MIDOUT_STOP` out of the library, guards, sampled CPU check), `a7d3099a` (the acceptance tests),
`46c99784` (account checks moved off the main kernel's live range, one read per group, the sampled slice's own field
counts), `c0ad3f4a` (MAXPOP's proof, group cap). Raw logs: `G2/build3a/`: `final/` the verification chain at
`46c99784` (`box/chain.sh`), its lint and suite at `c0ad3f4a` (`final/lint/`, `box/lint.sh`) and the per-stage A/B at
`c0ad3f4a` (`final/stops.log`, `box/stops.sh`); `early/` the first acceptance runs at `197c1e94`'s tree; `run1/` the
first measurement, whose main-kernel cost led to `46c99784` (stopped part-way); `ab/` the A/B pairs in between.
Code moved to the box as bundles of the commits; between commits, uncommitted trees went over as `git diff` patches
(each later committed on ivory and fast-forwarded on the box from a bundle).

### 10.1 Accounts: what every stage returns and what the host compares it with

Each slice gets its own 20-word account buffer `acc` (created with the slice, zeroed by the upload); the 64-slice tops
level gets a second word in its `l5n`; each launch batch's `stat` grows from 3 to 5 words; the group's counter buffer
gains three words. Every count is made **positive**: it must equal a number the host queued or a number another stage
counted, so all-zero counters fail for every slice, including slices that legitimately have no survivors or no tops
(slice 0: 0 survivors, 504 jobs with no probe, passes; it still has its cubes, jobs, parents and tops to show).
`GpuJoin::check_slice` and `finish_group` (`gpu.rs`) do the comparisons; one failed comparison is an error naming the
slice, the account and the whole account vector.

| stage (kernel) | evidence it returns (where) | the host compares it with |
|---|---|---|
| `tops5` (once per 64 slices) | cubes done (`l5n[1]`, thread 0 of each cube) | its grid, 2^21 / 256 = 8,192 |
| `tops1` | valid parents examined (`A_T1_EXAM`), tops certified (`A_T1_CERT`); plane sums, lane 0 adds | `l5n[0]` (the valid parents `tops5` listed); `tstat[0]` (`tscan`'s sum of the segment counts) |
| `tscan` | ran (`A_TSCAN`) | 1 |
| `tops2` | tops placed (`A_T2_PLACED`) | `tstat[0]` (≤ the tops cap, checked as before) |
| `tdigz2`, `toprec2` | rows written (`A_TDIG`, `A_TREC`) | `tstat[0]` |
| `hist2` | cubes done (`A_H2_CUBES`); parents certified, counted by a ballot of `m ≠ 0` apart from the list's own count (`A_H2_CERT`, per cube in shared memory) | the grid, ⌈depth-4 roots / 256⌉ = 36,323; `lcnt` (the list length the expansion copies into `stat[0]`) |
| `scan16` | ran (`A_SCAN16`) | 1 |
| `scatter3` | rows moved (`A_SCAT`); **children of the listed parents** (`A_SC_CHILD`: for each parent, the units d (of 64) whose child mask is valid, by the main kernel's own `child_mask`) | `lcnt`; the main kernel's children (below) |
| `hsort` | cubes done (`A_HSORT`) | 16,128 |
| main kernel (`g2_kernel`) | **job instances that reached their end** (`A_JOBS`, the wide branch's `C_JOBS` per slice); probes it runs (`A_PROBES`, added once per instance before the rounds); children seen (`A_CHILD`, the existing per-job count) | the instances queued for the slice (2·classes·64 per batch, summed over the batches queued); **8 × tops** (every top is a probe of exactly one job per root, over the job's two instances); **`A_SC_CHILD`** (the last two only when every batch of the slice was queued) |
| expansion (`expand_kernel`, per batch) | cubes done (`stat[3]`), slabs walked once per plane (`stat[4]`) | 4,096; `min(slabn, slab cap)` |
| check (production's, unchanged) | its `ran` words, as before | entries = list length, index sum (as before) |
| per slice (`done_kernel`, new, after the slice's last batch) | `A_DONE` += 1 and the group's `C_SLICES` += 1 | 1; **the number of slices queued in the group** (the field's slice count now comes from the device, not the host's loop) |
| any kernel | `A_ERR_PLANE` (`hist2`: plane width or lane layout differs from the comptime width); `C_ERR_IDX`, `C_ERR_CLST` (guards, §10.3) | 0 |

The accounts that existed (kernel error counters, caps, list = check, bits read = survivors counted) are unchanged.
The plane sums with a lane-0 add (`tops1`, `tops2`, `tdigz2`, `toprec2`, `scatter3`, the expansion's slabs) are
self-checking against partly filled planes: a plane without lane 0 under-counts, and the comparison fails.

Not done from the audit's list in §1.1: (c) the write-and-read-back of each large buffer at `new` (the accounts catch
the same failure at the first group, shown below) and (d) a panic hook that aborts the process when CubeCL's stream
thread panics (a library should not set a process-wide hook; **the client route (piece F) must**, so that nothing is
submitted after such a panic).

### 10.2 The fault switches and the reproductions, before and after

Before: the audit's §1.3 table at `91ac0761` (`G2/audit1/faults*.log`). After: `accounts_faults_are_loud` (new,
`audit.rs`; asserts each one), on the production group path (`queue_dev` + `finish_group`, exactly `search_field`'s),
each fault followed by a clean run that must give the unfaulted counts. CUDA: slices {502136830, 0} and {806726610
(a 141-probe job), 712012851, 2^30 − 1} (`build3a/final/faults_cuda*.log`); lavapipe W 8 through SPIR-V, 4 classes per
batch: slice 712012851 (`final/lvp_faults.log`).

| fault (switch) | before (`91ac0761`) | after: what fails (CUDA, first account to fail) | lavapipe W 8 |
|---|---|---|---|
| `F_SKIP_MAIN` (2), main kernel dropped | **silent** (survivors 0) | loud: "main-kernel job instances done: 0, want 8064" | loud (same account) |
| `F_SKIP_TOPS` (4096), `tops1` dropped | **silent** (tops 0, survivors 0) | loud: "tops1 valid parents examined: 0, want 405593" (and `tops2` placed 219,137 stale tops from the previous slice: the account would have failed there too) | loud (same; `tops2` placed 238,813 stale tops, the same slice's from the clean run, which would have looked right) |
| `F_DROP_PROBE` (8), each job's last probe not run | **silent** (−50,412 survivors, −0.21 %) | loud: "probes run = 8 x tops: 1906740, want 1910856" | loud (1906472 vs 1910504) |
| `F_DROP_PARENT` (8192), 1 parent in 997 uncertified | **silent** (−23,963 survivors, −68,072 children) | loud: "parents certified (hist2) = listed: 1040898, want 1039848" | loud (1042046 vs 1040986) |
| `F_PF_DROP` (1024), prefilter rejects ~1/1024 of survivors | **silent** (checked −672) | accounts still pass (no account can see it); **the sampled CPU check fails**: "device … checked 337845 …, CPU … checked 338191" | accounts pass; sampled check loud (337578 vs 337904) |
| `F_DROP_REC`, `F_SLABCNT`, `F_SKIP_CHECK`, `F_PMAX300`, `F_POP12`, `F_SLAB_CAP`, `F_SCAP` | loud | loud (accounts unchanged) | — |
| `F_IDX13` | loud by accident | loud by accident (the 16-bit guard checks the class size, not the read) | — |

The reproductions of §1.1 and §1.2, now tests that fail if the path is silent:

- **§1.1, a failed device allocation** (`audit_oom_is_loud`): in-process, 9,216 MiB filled first, CubeCL's stream thread
  panics "can't allocate buffer of size: 647127040", `GpuJoin::new` still returns `Ok`, and **both slices fail
  loudly**: "expansion ran 0 of 4096 cubes, walked 0 of 0 slabs" (`final/oom_inproc_9216.log`). With a helper process
  holding 7,680 MiB (card at 8.9 GB), unmodified join in a fresh process: the same (`final/oom_helper_7680.log`). Before
  (audit `oom*.log`): `Ok` with survivors 0, every account passed.
- **§1.2, `MIDOUT_STOP` in the environment** (`audit_stop_env_is_loud`): with `MIDOUT_STOP=2` set, `GpuJoin::new` no
  longer reads it (stop stays 6) and slice 712012851 gives its full counts (survivors 11,768,560, checked 337,904);
  with the stop set through the new `set_timing_stop(2)` (the bench's only way), `search_field` refuses: "a timing stop
  (2) is set: this join only times stages" (`final/stop_env.log`). Before: `Ok` in 5 s with survivors 0, slices 4,096.
  Timing now goes through `time_field`, which returns only a time.

### 10.3 The guards (AUDIT-MO §3)

| § | guard | how |
|---|---|---|
| 3.1 | 16-bit pending parent index | per job, before the rounds: a class of more than 65,536 parents counts `C_ERR_IDX` (host: error) |
| 3.2 | 20-bit top index in the probe word | `GpuJoin::new` refuses a tops cap above 2^20 |
| 3.3 | child-list write unbounded per batch | the kernel takes the list's length; per job, the range `[lb, lb + class size)` past it counts `C_ERR_CLST`; the store is clamped to the list (no write past it) |
| — | `scatter3` read the list up to `lcnt`, unbounded | bounded by the list's capacity (an overflow is already an error) |
| 3.4 | MAXPOP 17, margin 0 | the audit's proof written at the constant |
| 3.5 | slice count compared with itself | slices counted from the device's done words (`C_SLICES`), compared with the slices queued per group and per field |
| 3.6 | nice numbers not checked to lie in the field | `search_field` checks each reported n's v lies in `[v_start, v_start + v_size)` |
| 3.7 | u32 counters per unit per group | `search_field` refuses groups above 256 slices |
| plane | kernels without a plane check | `hist2` (the one that takes a comptime width) checks `PLANE_DIM` and the lane layout (`A_ERR_PLANE`); the others use `PLANE_DIM` at run time and their lane-0 counts fail their account on a partly filled plane |

### 10.4 The sampled CPU check (`GpuOptions::cpu_check`; on in the bench, `--no-cpu-check` turns it off)

One slice of the field, chosen at random (`RandomState` hashed with the field), is computed by the CPU reference
(`cpu::slice_join`, the same as the parity tests) on a host thread started with the field. When the field's slices are
done: (1) the field run's **own** survivors and checked for that slice (the expansion's bits read and the check's
entries for its batches, recorded by `finish_group`) must equal the CPU's; (2) the slice is run again alone on the
device (`run_slice_dev`, the field's key) and its prefiltered list must equal the CPU's **n for n**. Any difference is
an error for the field. On the 3080 box (10 fields): the CPU thread takes 26.6–27.1 s against a 30.6 s field, so the
host never waited for it (0.00 s); the device rerun costs 0.16 s (0.32 s on the first field, with its compilation),
**+0.4 % on the field**. It costs one host core for ~27 s per field (a client with fewer than 2 free cores would wait).

What it sees that nothing else does: a kernel that does all its work and computes wrongly (§10.5); with probability
about 1 − (1 − f)^k after k fields for a defect touching a fraction f of slices (f = 1/1,000: 1,000 fields ≈ 0.4 % of
the base for 63 %).

### 10.5 What only the sampled check, or nothing, can see

- **Only the sampled CPU check** (all the accounts are conservation of work, not of correctness): a wrong certificate
  in `tops5`/`tops1` (a valid top rejected lowers `tstat[0]`, the tops placed and the probes together); a wrong
  `parent()` mask (the audit's `F_DROP_PARENT` is loud only because its flag is cleared after `parent()`: the
  certified count is taken from `m`; a `parent()` that returns 0 for a valid parent is seen by nothing else); a wrong
  `child_mask` (`scatter3` uses the same function); a false common-mask skip or a wrong transpose mask in phase 2; a
  wrong segment table whose counts still sum right; a slice run with the wrong digits; a prefilter that rejects too much
  (`F_PF_DROP`, shown); a wrong `r0` or top record written by the expansion.
- **Partly**: a defect that only touches the field path and not a slice run alone is seen by the sampled check's
  first half (the field run's own counts), at count level only (not n for n).
- **Nothing**: a defect shared by the device and the CPU reference (the shape's predicate; covered by the small-base
  brute-force test only); production's check kernel judging a nice n not nice (production's own exposure); a defect
  in slices the sampled check never draws, until it draws one; the W 64 paths (never run).

### 10.6 Cost (measured, Vast 61286074, RTX 3080 at its 240 W cap, one session)

Ten fields (the set of §6), group 16, binaries `mo_bench_head` (`91ac0761`, md5 `51cef178`) and `mo_bench_final`
(`46c99784`, md5 `fcdd191c`), back to back 02:19–02:35 UTC (`final/ten_*.log`, `final/smi_ten.csv`: 237 W mean, 1,553
MHz mean SM clock, at most 72 °C). Survivors and checked equal field for field in all three runs.

| run | 10 fields | fs per admissible n | against main (6.615 fs) |
|---|---|---|---|
| before, `91ac0761` | 302.04 s | **1.6505** (tonight's 1.647, repeated) | ×4.01 |
| after, `46c99784`, no sampled check | 309.48 s | **1.6911** (+2.5 %) | ×3.91 |
| after, `46c99784`, sampled check on (the bench's default) | 310.74 s | **1.6980** (+2.9 %) | ×3.90 |

Per slice (field 77777, cumulative stops, `final/stops.log`), two rounds each, `91ac0761` against `c0ad3f4a`
(02:55–03:03 UTC), seconds per field / 4,096; noise about ±0.03 ms per slice:

| stage (cumulative stop) | before | after | change |
|---|---|---|---|
| tops (1) | 0.376 ms | 0.413 ms | +0.037 (tops accounts, the per-slice account buffer, the done kernel) |
| parents (2 − 1) | 0.660 | 0.731 | +0.071 (mostly `scatter3`'s children count) |
| main kernel (3 − 2) | 5.454 | 5.547 | +0.093 (job and probe counts, the guards) |
| expansion (5 − 3) | 1.080 | 1.110 | +0.030 |
| check and the group's accounts (full − 5) | 0.144 | 0.090 | −0.05 (noise; the accounts are read once per group) |
| **slice, no sampled check** | **7.714** | **7.891** | **+0.177 (+2.3 %)** |
| slice, sampled check on (one field per process: the rerun includes its compilation) | — | 7.975 | +0.261 |

Over the ten fields the change is +2.5 % (no check) and +2.9 % (check on); the table above is one field.

**The first form was dearer** (`run1/`): the per-write bound on the child list and the probe and guard checks at the
kernel's end cost the main kernel 0.55 ms per slice (stop 3: 28.86 s against 26.59 s per field), which `46c99784`
removed by taking those checks once per job before the rounds (no value stays live through them) and clamping the
store: the kernel's cost fell to ~0.09 ms per slice (the commit message's "about 0.03" was from one A/B pair; the
table above is the better number). Batching the group's reads into one call changed nothing
measurable. The rest of the cost is the per-slice account buffer and done kernel (~0.03 ms), the children count in
`scatter3` (64 child-mask tests for each of ~1.04M parents, ~0.06 ms) and the plane sums in the tops kernels.

### 10.7 Tests at the head (`46c99784`; `c0ad3f4a` adds a doc comment and the group cap)

| test | what | result |
|---|---|---|
| `audit::accounts_faults_are_loud`, CUDA | §10.2, two slice sets | pass (every fault loud) |
| same, lavapipe W 8 (SPIR-V), 4 classes per batch | slice 712012851, no clean rerun between faults | pass (every fault loud; llvmpipe, Mesa 25.2.8, LLVM 20.1.2, 256 bits; 88 s) |
| `audit::audit_oom_is_loud`, CUDA | in-process 9,216 MiB; helper process 7,680 MiB | pass (loud) |
| `audit::audit_stop_env_is_loud`, CUDA | §10.2 | pass |
| `gpu::gpu_slices_equal_cpu`, CUDA | the 5 slices of §5; host tops (712012851); part of a slice (3 batches of 4 classes: the probe and children laws skipped, the rest checked) | pass |
| same, lavapipe W 8 | 712012851, 318575442, 4 classes per batch | pass (device tops = host tops, lists n for n, every count; 72 s) |
| `gpu::gpu_check_rebuilds_the_survivors`, CUDA | probe mode | pass |
| `audit::audit_sweep`, CUDA | the first 100 slices of the audit's list (its 48 extremes, 24 range-end slices, 28 seeded) | pass: all 100 equal (device tops, prefiltered lists n for n, whole survivor sets with the prefilter off, every count; 1,140,052,210 survivors, 32,714,757 checked; jobs up to 619 probes; slices 0 and 2^30 − 1 included), every account passed on every run (`final/sweep100.*`) |
| production suite | `cargo test --release -p nice_common --lib`, default features | 214 passed, 0 failed, 10 ignored (as on main), at `c0ad3f4a` |
| lint | `cargo fmt --all --check`; clippy `-D warnings`, all targets, default and `cubecl-cuda,cubecl-spirv` | clean at `c0ad3f4a` |

### 10.8 What remains from the audit, and what it got wrong

Remains: §1.1 (c) and (d) (above; (d) belongs to the client route); the W 64 parity run before any field on the RX
9070 XT (§8.1); lavapipe W 16 (aborts in lavapipe); a sampled check of the host-tops path's field runs (the host path
has the main-kernel, preparation and expansion accounts but no tops accounts: its tops come from the CPU); the wide
kernels (`gpu_wide.rs`, untouched here) need the same accounts ported (only `C_JOBS` is there).

The audit, checked against what was found here: nothing material was wrong; every reproduction and fault behaved as it said, the
two conservation laws it proposed hold exactly on every slice run tonight (the 100-slice sweep, slices 0 and 2^30 − 1,
the part-slice runs aside, where they do not apply), and its CPU estimate for the sampled check (35 s) was close (27 s
measured). Three refinements: (1) §3.1's limit is a class of **65,536** parents, not 65,535 (indices 0…65,535 fit in
16 bits); (2) `F_DROP_PARENT` is injected after `parent()` returns (the flag, not the mask), so it is loud through a
count of `m ≠ 0`; the defect it is meant to model, a wrong `parent()`, is still seen only by the sampled check (§10.5);
(3) with `tops1` dropped, `tops2` still places tops from the previous slice's buffers (219,137 on CUDA; on lavapipe,
rerunning the same slice, exactly the right 238,813), so "tops 0" in its table was `tscan`'s count, not what the later
kernels used: stale buffers can look exactly right, and only counts that each kernel makes of its own work, compared
with each other (examined = listed, certified = counted, placed = counted), tell a dropped launch from a run.

## 11. Step 3W: one trunk, and the wide kernels brought level (2026-11-19, 03:07–06:00 UTC)

Brief: `G2/BUILD-BRIEF-3W.md` (rules of `BUILD-BRIEF-1.md`). Same box (Vast 61286074, RTX 3080 at its host's 240 W cap,
5.12-CPU quota), production hosts mapped to 127.0.0.1 and ::1 before every run (`build3w/raw/*/hosts_block.txt`).
Commits on `dev/middle-out-join`: **`23ce3cf6`** (merge of `dev/mo-wide` `a8a76315`), **`f246d9fd`** (accounts, guards,
sampled check on the wide path), **`4abfab5c`** (top hierarchy and prefilter on the wide path; two clippy findings of
`f246d9fd`'s tests). Scripts `build3w/box/` (`build.sh`, `chain.sh` for the merge, `chain_port.sh` / `chain_port2.sh`
for the two ports, `measure.sh`, `final.sh`, `lint.sh`); raw logs `build3w/raw/`: `merge/`, `port1/` (= `f246d9fd`'s
tree), `port2/` (= `4abfab5c`'s tree before its last fixes), `port2d/` (the head's tree), `m1/` (the number),
`lint_s2/`, `lint_p2/`, `lint_head/`. The box's trees: `/root/midout` (checkouts of the bundles, lint), `/root/mp`
(the ports; its own target directory `/root/t/mp`); test binaries were copied before each chain so a rebuild could
not swap them.

### 11.1 The merge (`23ce3cf6`)

Files did not conflict (`gpu_wide.rs`, its bench, one line each in `mod.rs`, `coord.rs`, `Cargo.toml`). Three edits the
trunk's later work required, in the merge commit: the CPU reference's sink takes the prefilter flag (wide tests ignore
it: no prefilter on that path yet, `checked = survivors` there), `FieldTiming`'s new fields, `GpuOptions::cpu_check` in
the wide bench's narrow runs. Verified at the merge (`raw/merge/`): the trunk's `accounts_faults_are_loud`,
`gpu_slices_equal_cpu` (712012851, 2^30 − 1), `audit_stop_env_is_loud`, `audit_oom_is_loud` (9,216 MiB) on CUDA;
`wide_whole_small_bases_vs_brute_force` (17 shapes, CUDA); `wide_slices_equal_cpu` b30/b40/b50, b64 forced wide
712012851, b65 717171717 and 532260419 (CUDA); lavapipe W 8: trunk parity 712012851, wide b40 1234 and b65 717171717;
fmt clean, clippy `-D warnings` clean default and `cubecl-cuda,cubecl-spirv`, production suite 214 passed / 0 failed /
10 ignored. The wide branch's staged-prototype test (`wide_slice_vs_staged`) was not run: its staged slice was on the
wide branch's box, which is gone (the CPU reference test covers the same slice).

### 11.2 Accounts and guards on the wide path (`f246d9fd`)

The trunk's step-3A design, wide form (`gpu_wide.rs`: `A_*`, `WideJoin::check_slice`, `finish_group`):

| stage | evidence (per slice `acc`, or the batch's `est`) | compared with |
|---|---|---|
| `wtops5` (since `4abfab5c`) | cubes done, valid parents listed (`l5n`) | its grid; = `wtops1`'s examined |
| `wtops1` | prefixes examined (valid parents since `4abfab5c`), tops certified | `ntest` (then `l5n[0]`); `tstat[0]` |
| `wscan` ×2 | ran (`A_TSCAN`, `A_HSCAN`) | 1 each |
| `wtops2`, `wtdigz` | tops placed, digit rows | `tstat[0]` |
| `whist` | cubes done; parents certified by a ballot apart from the list; plane check | ⌈nrf/256⌉; `lcnt`; 0 |
| `wscatter` | rows; **children of the listed parents over all b units** (`child_w`) | `lcnt`; the main kernel's children |
| `wsort` | cubes done | the buckets (m·256) |
| main kernel | job instances done; probes run (once per instance before the rounds); children (instance 0) | queued; **nroot × tops**; the scatter's count |
| expansion | cubes done, slabs walked; since `4abfab5c` survivor bits read, clipped bits | 4,096, `min(slabn, cap)`; the kernel's survivors |
| done kernel | `A_DONE`, `C_SLICES` | 1; slices queued |

Guards: per job, the child-list range against the batch's list (`C_ERR_CLST`, store clamped); class index limit at
65,536 (was 65,535); groups 1–256; reported nice n must lie in the field. `MIDOUT_STOP` is no longer read by the library
(`set_timing_stop`; `search_field_wide` refuses a stop; `time_field_wide` takes it; the bench reads the variable).
`WideOptions::cpu_check`: the sampled CPU check (one random slice through `cpu::slice_join::<u128>` on a host thread; the
field run's own survivors for that slice, then a device rerun, n for n). **MAXPOP**: the wide path makes a top above
`maxpop` an error of the field (`tstat[1]`), so a margin of 0 cannot lose survivors; a bound like the trunk's
(§3.4 of the audit) was not proven per base (a loose count gives ≤ 20 at b65, `maxpop` is 18; never exceeded).

**The fault table** (tests `wide_faults_are_loud` at base 65 {717171717, 0}, base 64 forced wide {712012851, 0}, and
lavapipe W 8 SPIR-V at base 40 slice 1234; each fault followed by a clean run that must equal the unfaulted counts;
`wide_oom_is_loud`, `wide_stop_is_loud`). Raw: `port1/`, `port2/`, `port2d/`.

| fault | b65 (CUDA) | b64 forced wide (CUDA) | b40 lavapipe W 8 |
|---|---|---|---|
| `F_SKIP_MAIN` | loud: "0 of 16640 job instances ran" | loud | loud |
| `F_SKIP_TOPS` (`wtops1` dropped) | loud: "wtops1 valid parents examined: 0, want 2838017" (stale tops placed: 1,693,682) | loud | loud |
| `F_DROP_PROBE` | loud: "probes run = nroot x tops: 1697785, want 1701945" | loud | loud |
| `F_DROP_PARENT` | loud: "parents certified (whist) = listed: 1268336, want 1267042" | loud | loud |
| `F_BAD_PARENT` (new: `parent_w` wrong for 1 in 997; every law holds) | accounts pass (as designed); **sampled check loud** | same | same |
| `F_PF_DROP` (since `4abfab5c`) | accounts pass; **sampled check loud** (526,566 vs 527,041 checked) | same (after moving the predicate to bits 10–19: r_f ≡ 0 mod 1024 never survives at b64, so the first form dropped nothing) | same |
| allocation failure (8,192 MiB filled, in process) | `WideJoin::new` Ok, stream thread panics, **group loud**: "0 of 8320 job instances ran" | — | — |
| `MIDOUT_STOP=2` in the environment | ignored (survivors 16,482,926); `set_timing_stop(2)` → `search_field_wide` refuses | — | — |

### 11.3 The speed work on the wide path (`4abfab5c`), exact first

- **Top hierarchy** (piece C): `wtops5` once per b consecutive slices (one value of the slice's digits above its
  lowest) certifies each parent prefix over b^(f0+1) n and lists the valid ones; `wtops1`/`wtops2` grid-stride over the
  list. At b65 slice 717171717: 2,838,017 valid parents of 13,410,995 prefixes (21 %); at b64 405,811 of 2,097,152.
  `WideBase::new` now needs a slice digit (f0 + 1 < k).
- **Prefilter before the check** (piece A): `cert_split_w` gives each top its certified digits at positions ≥ k + 2;
  the expansion forms n mod b^(k+2) digit by digit (`pf_w`, the test of `cpu::prefilter`, small-n rule included) and
  lists only passing n; it also counts a clipped top's n outside the range itself (never listed). `checked` now has
  production's meaning on the wide path: 3.2 % at b65 (527,041 of 16,482,926 on 717171717), 2.87 % at b64.
- **Cheaper expansion** (piece B): not ported: the wide record already carries its probe slot and, at b65 (one root),
  the walk to the top is one segment. Two records per lane: not tried.
- **Exactness** (`port2/`, again on the head's tree in `port2d/`): whole small bases 10–25 in 17 shapes against brute
  force, survivors = `q_shape`, the listed n = `q_checked` exactly, nice = {69 at base 10} by the device's check;
  slices vs the CPU reference n for n and every count (checked included): b30 100, b40 1234, b50 77777, **b64 forced
  712012851** (checked 337,904 = the narrow path's), **b65 717171717, 532260419 (start's clipped top), 1160290624 (the
  last slice)**; with the prefilter off (`MIDOUT_NOPF=1`) whole survivor sets at b40, b64, b65; lavapipe W 8 b40 1234
  and b65 717171717; the trunk's fault test unchanged.

### 11.4 The number (measured, this box, 240 W cap, one session 04:17–04:39 UTC, `raw/m1/`)

Same fields as last night (b64 t = 13107, 131072, 249036, 65536, 196608; b65 t = 13731, 77777, 137312, 200000, 260893;
t = 4095 first in each process as warm-up, excluded). Sampled check off unless said. Card while busy: 239 W mean,
1,607 MHz mean, at most 72 °C.

| run | fs per admissible n (warm mean, range) |
|---|---|
| b64 narrow (trunk head), before and after the b65 runs | 1.7137 and 1.7063 → **1.710** (1.671–1.742) |
| **b65 wide at the head `4abfab5c`** | **3.561** (3.550–3.565): **×2.08 of b64** |
| b65 wide at `f246d9fd` (accounts, no speed port) | 3.861 (3.849–3.867): ×2.26 |
| b65 head with the sampled CPU check | 5.93 (the CPU slice takes 93 s against a 56 s field: the host waits ~36 s) |

Last night (another card, 320 W, before the trunk's work): 3.484 fs, ×2.04. So: the accounts cost the wide path about
+8–10 % at b65 (×2.04 → ×2.26, partly the cap: not separated), the speed port gave back −7.8 % (3.861 → 3.561), and
the multiple stands at **×2.08**. Card-time for all of base 65 at the head on this capped 3080: 3.561e-15 × 4.371e21 =
1.56e7 s = **0.49 card-years**. **The sampled CPU check is not affordable at b65 as built** (single-threaded u128
reference slower than the field); `cpu_check` stays off by default on the wide path.

Per stage at the head (cumulative `MIDOUT_STOP`, b65 field 77777, one cold process each, `raw/port2d/stop65_*.log`):
| stage (cumulative stop) | b65 ms per slice at the head | last night (wide branch, 320 W, first code) |
|---|---|---|
| tops (1), incl. ~1.5 s one-time per process (~0.35 ms/slice) | 1.80 | ≈ 2.6 |
| parents (2 − 1) | 1.42 | 1.03 |
| main kernel (3 − 2) | 6.72 | 6.37 |
| expansion (5 − 3), **now with the prefilter** | **3.71** | 1.13 |
| check (6 − 5) | 0.17 | ≈ 2.0 |
| slice (one cold field: 58.44 s / 4,225) | 13.83 | ≈ 13.1 |

So the hierarchy saved about 1 ms of tops and the prefilter about 1.8 ms of check, but **the prefilter's digit-by-digit
arithmetic costs the expansion ~2.6 ms** (16.5M survivors per slice, ~300 dependent operations each, two `% b` per
digit): that, not the idea, is why the port gave only −7.8 %. Parents +0.4 ms is most likely the accounts'
children count in `wscatter` (65 `child_w` with two `% b` per parent).

### 11.5 What is left for the wide path

1. **The prefilter's arithmetic** (the next piece, ~2.5 ms of 13.3 per slice): r = rf + F·b^f0 with F fixed per
   record, so r², r³ mod b^(k+2) need only rf², rf·F and F's powers per record; or the trunk's 32-bit limb form.
   Estimated b65 at ~10.8 ms per slice, ≈ 2.9 fs, ×1.7 of b64 (estimate, not measured).
2. **The accounts' cost at b65** (parents +0.4 ms): `wscatter`'s children count with `% b`; a table of
   `(c + a·d) mod b` or counting children from the main kernel's side only.
3. The sampled CPU check at b65: a multi-threaded or u64-limb CPU slice (or sample one slice every k fields).
4. The trunk's step-2A follow-ups not ported: two records per lane in the expansion, 32-bit limb prefilter arithmetic
   (ours is digit by digit, ~2·(k+2)²/2 multiply-adds per survivor).
5. Not run: `wide_slice_vs_staged` (staged slice lost with the wide branch's box), base 68 (does not fit this card),
   bases 69–70, lavapipe at b65 faults, W 16/W 64.
6. A 2D tops grid (Vulkan at b68+), a 64-bit slice value (b70's (4, 11)), unchanged from `BUILD-NOTES-WIDE.md` §7.

### 11.6 Tests at the head (`4abfab5c`)

| test | result |
|---|---|
| fmt; clippy `-D warnings`, `nice_common`, all targets, default and `cubecl-cuda,cubecl-spirv` | clean on the box's checkout of `4abfab5c` (`raw/lint_head/`; `lint_s2/` and `lint_p2/` are the runs that found the 4 findings fixed in `4abfab5c`) |
| production suite `cargo test --release -p nice_common --lib` | 214 passed, 0 failed, 10 ignored (as on main) |
| `wide_faults_are_loud` b65, b64 forced, lavapipe b40; `wide_slices_equal_cpu` b30, b40, b65 717171717 | pass on the head's tree (`raw/port2d/`) |
| the rest of §11.2–11.3 (brute force, all slices, `MIDOUT_NOPF`, OOM, stop, the trunk's `accounts_faults_are_loud`, lavapipe b65) | pass on `port2/`, whose tree differs from the head only by the F_PF_DROP predicate (fault path), `k - 1 >= tsm` written `k > tsm`, two test attributes and two doc comments |

The b65 number of §11.4 was measured with `port2/`'s bench binary (same production code path as the head; the
differences above are not reachable without a fault bit). Nothing of this step's ran on another machine; the box was
left with no process of this step running.
