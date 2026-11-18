# The middle-out join, build day 1 (2026-11-18, 16:43–22:30 UTC)

Brief: `G2/BUILD-BRIEF-1.md`. Branch **`dev/middle-out-join`** (from upstream main `be9cc923`), worktree
`~/projects/nice/.worktrees/midout`, pushed to the fork only. Box: Vast 61286074, RTX 3080 at the host's 240 W cap,
i9-9900 with a **5.12-CPU cgroup quota** (16 threads visible), CUDA 12.8 image, Mesa 25.2.8 lavapipe. Box scripts and
raw logs: `G2/build1/box/`, `G2/build1/raw/`.

## 1. Where it stands (kept current)

**2026-11-18 ~19:00 UTC, end of day 1.** Branch head **`7ba982c7`** (7 commits on `be9cc923`), on ivory and on
`fork/dev/middle-out-join`. Nothing outside `common/src/midout/`, `common/examples/midout_bench.rs`, one line of
`lib.rs` and the example entry in `common/Cargo.toml`; no route reaches it; no server, schema or API change.

- **Runs end to end and exactly on the RTX 3080 (CUDA):** whole base-64 fields of the new kind, `(64, 2^75 + t·2^57,
  2^57)`, through `midout::gpu::search_field`: tops, parents, main kernel, record expansion and production's full
  check on the card, one synchronisation per 16 slices, every account verified. **1.752 fs per admissible n over 10
  fields spread across the base, against today's main 6.615 fs in the same session: ×3.78** (§6).
- **Exact:** the CPU reference equals brute force on whole bases 10–25 (every b mod 5 class, odd bases, two shapes,
  69 at base 10) and the staged prototype on two real b64 slices; the device equals the CPU reference on 5 b64
  slices on CUDA (tops, survivor sets n for n, and every order-independent count), and on 2 whole slices on
  lavapipe W 8 through SPIR-V; production's check rebuilds exactly our survivors (probe mode).
- **Does not run yet:** lavapipe W 16 (lavapipe 25.2.8's 512-bit JIT aborts, "stack smashing", in our device-top
  kernel and in the port's preparation kernels); W 64 / the RX 9070 XT (not attempted: no AMD card today); masks
  above 64 bits on the device (CPU reference only); any client route; a prefilter before the check.
- **The gap to the ×4.6–5.5 of the example** is the work the measurements assumed at 0.115 fs and did not run:
  tops 0.10, record expansion 0.22, unprefiltered check 0.13 fs (§6, §8 item 1).

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
  production's `checked` (survivors after the prefilter). Day one has no prefilter, so `checked = survivors`, and the
  device proves it per launch batch (the check kernel's own count and index sum against the list). Both are
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
- **Records name their job and chunk position, and phase 1 writes the child lists.** The port's record held the
  chunk's first parent and the host re-walked the parents to expand it. The library path needs the survivors on the
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
prefilter (it lives inside `join_kernel`'s walk; day one checks every survivor, 0.57 ms per slice).

**New** (all under `common/src/midout/`, 3,4xx lines with tests; `common/examples/midout_bench.rs`):
`coord.rs` (the work unit), `arith.rs`, `mask.rs`, `cpu.rs` (the reference: certificates, bottoms, parents,
slice join, field search, brute-force predicate), `gpu.rs` (device tops, record expansion, top records, host tops by
shifts, the driver `GpuJoin` and `search_field`). No new dependency.

## 5. Tests and results

All on the box (Vast 61286074), release builds, from the committed head `7ba982c7` (raw: `build1/raw/final_tests.log`,
`lvp_*.log`, `staged_*.log`). Times are per run.

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

**Ratio ×3.78** (6.615 / 1.752), end to end with tops and survivor checks on the card. Against the example's
measured ×4.61 at 1.322 + 0.115 fs, the difference is the per-slice work it did not run.

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
checked), and inside the device path **the survivor list** (`(top, r0)` entries + one 8-word top record per top,
production's layout) between "join" and "check". Pieces touching different sides of those can run in parallel.

| # | piece | files | interface | test | card? |
|---|---|---|---|---|---|
| A | **Survivor prefilter**: production's middle-digit prefilter as its own pass on the list (or folded into the expansion) before the check; `checked` becomes production's meaning | `midout/gpu.rs` (post), `midout/cpu.rs` (mirror) | list in, list out; `checked` | CPU mirror = device on 5 slices; `checked` equal CPU/device | yes (CUDA or lavapipe) |
| B | **Expansion cost** (0.98 ms per slice, the largest new overhead): per-job probe prefix rows instead of the 8-segment walk, denser slabs (fewer idle slots), or record → list in the main kernel's slab flush | `midout/gpu.rs` (kernels, post) | records → list (unchanged list) | `gpu_slices_equal_cpu`, `gpu_check_rebuilds_the_survivors` | yes |
| C | **Top hierarchy across a field**: certificates at f0 6 once per field, f0 5 per 64 slices, f0 4 per slice only under a valid parent (tops 0.46 ms per slice now); orders slices so digit-4 siblings run together | `midout/gpu.rs` (dtops, driver order) | tops in production-free form (`tmask`, `thd`, `tseg`) | device tops = host tops (existing test) on 3+ slices | yes |
| D | **Main-kernel items left from the port** (8-byte records, root pass, LDS diet) and the 9070 XT window for the whole path | `midout/gpu.rs` (kernels) | records (with B) | `gpu_slices_equal_cpu` on CUDA + lavapipe W 8, then RADV W 64 | yes; AMD window |
| E | **Wide masks (b65–70)**: the device kernels with two-word masks and mod-b digits; staged b65 slice (`g2proto dumpsu 65 4 10 …`) as the reference; the CPU reference already runs `u128` | new `midout/gpu_wide.rs` or a comptime width in `gpu.rs` | same `GpuJoin` surface | CPU reference (`search_field::<u128>`) vs device on b65 slices | yes |
| F | **Local coordinator + client route** (C′ of PROPOSAL, no server change): a `client` mode taking v-fields from a local stub; every other route refuses a coordinate base (the third guard); telemetry with the shape label | `client/src/main.rs`, `gpu_route.rs`, a stub script | `search_field` | stub end to end on one field; refusal tests | lavapipe enough |
| G | **Audit tool**: CPU reference per slice (20 s per slice per thread today) recomputes random slices of a submitted field and compares `survivors`; a faster power-of-two CPU path | `midout/cpu.rs`, `scripts/` | `FieldOutcome`, `Counts` | against the device on the same slices | no |
| H | **Driver overheads**: four small buffer creations per batch → rings; double-buffered group counters so the read of group g overlaps g + 1; measure host time per slice | `midout/gpu.rs` (driver) | `search_field` | field counts equal at group 1, 4, 16 | yes |
| I | **lavapipe W 16** crashes (Mesa 25.2.8, "stack smashing", already in the first device-top kernels, `MIDOUT_STOP=11`): bisect per kernel on ivory's `lvp26` container (Mesa 26.0.8), then run `gpu_slices_equal_cpu` at W 16 | none, or a kernel rewrite | — | lavapipe W 16 parity | no (lavapipe) |
| J | **The coordinate decision**: `q0` (6 → fields of 2^57; 7 → 2^63) and whether base 65's form is wanted; write the field-insert arithmetic for the owner (sizes, counts, padding) | `midout/coord.rs`, notes | `Coord` | `coord` tests | no |

Order for one engineer: B, A, C (together ≈ −1.4 ms of 8.2 ms per slice), then D. A, B, C, G, I, J are independent of
each other; E waits for nothing but is the largest; F needs only the `search_field` surface, which is stable.

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
