# The middle-out join: design

*A description of what is on the branch and why, for a reader who knows the project and today's overlap join and
has seen none of this work. Written 2026-11-19 from the code at `dev/mo-clean` head `c2152084` (worktree
`~/projects/nice/.worktrees/midout-clean`) and from the measurements recorded beside it. The open decisions are
not repeated here; they are in `~/projects/nice/scratchpad/2026-10-research-program/DECISIONS.md` (section A).*

![overview](static/midout-overview.png)

The interactive map (`interactive/midout-map.html`, one file, open it in a browser) shows every stage with its
cost, its check and its file:line; this document is the prose behind it.

**Labels.** Every claim carries one:

- **[measured]**: observed in a run on hardware or in a test, with the date and where the raw data is;
- **[proven]**: follows from the definitions (an argument you can check on paper);
- **[judged]**: an estimate, a model or an opinion. A number computed from measured ones (a model, a sum, a
  ratio across sessions) is judged, and says what it rests on.

Terms are defined where they first appear and collected in §10. Unless a section says otherwise, everything is
base 64 (n in [2^75, 2^76), 13 digits, positions 0–12).

---

## 1. The idea in one page

**What the overlap join does today.** A field is a contiguous range of n (1e17 at base 64). The join splits n
into a *top* (a prefix, n div b^f0) and a *bottom* (n mod b^k) with f0 = 3 and k = 6, so top and bottom overlap in
digits 3–5. A top is kept if the digits of n² and n³ at positions ≥ k are the same for every n under it and
distinct (its *certificate*, a digit mask); a bottom is kept if the low k digits of r² and r³ are distinct. A pair
whose masks are disjoint survives, goes through the middle-digit prefilter and then the full check. Inside one
1e17 field the bottoms (12 output digits) are rebuilt per partition and the tops (prefixes of 3 fewer digits)
are certified per field.

**What the middle-out join changes.** Three things, each needing the one before it:

1. **The unit of work is a *slice*: every n of the base that shares five middle digits, positions 4–8** (a
   30-bit value called `pip` in the code). A slice is 2^45 n spread over the whole leading range of the base, not
   a contiguous piece of it. [proven: a slice fixes digits 4–8 and leaves 0–3 and 9–12 free]
2. **Tops and bottoms are built once per slice, for that whole span.** The shape is (f0 4, k 10): a top is
   n div 64^4 (digits 4–12), certified by n², n³ at positions ≥ 10; a bottom is n mod 64^10 (digits 0–9),
   certified by the low 10 digits of r², r³ (20 digits). They share digits 4–9; the slice fixes 4–8, so the only
   shared digit left to pair on is digit 9, the *unit* `d` (64 values). Bottoms are made as 64 *children* of each
   depth-9 *parent* (digits 0–8), and a child adds two digits that are affine in `d`, so the deepest digit costs
   two additions, not a search. Bottoms carry 20 certified digits instead of today's 12. [proven]
3. **Pairing is bit-sliced.** Children are sorted and cut into *chunks* of 64; each chunk is transposed into one
   64-bit word per digit value ("which of these 64 children has digit v"). A top tests 64 children at once by
   OR-ing the words of its ~17 certified digits: a zero bit is a disjoint pair. A chunk whose common digits meet
   the top's mask is skipped with one AND. [proven: the word is exactly the disjointness test for 64 pairs]

**Why that is faster** [judged, from the measured counts below]: the number of (top, bottom) pairs tested is
about the same as today's at base 64 (the shapes that would test fewer are too expensive to build, §6.1), but
each pair costs about ×6–8 less, because a pair is 1/64 of a word built from shared loads instead of an AND in a
walk, and because the per-n work around the pairs (bottoms, tops, survivors) is spread over a slice of 2^45 n
instead of a 1e17 range. Fewer survivors reach the check: 11.8M per slice of 4.47e12 admissible n, and 2.87 % of
those pass the prefilter [measured, slice 712012851].

**The digits of n at base 64, in one picture:**

```
position:   12 11 10 |  9  |  8  7  6  5  4 |  3  2  1  0
            -------- | --- | -------------- | -----------
            lead h   | unit|   slice (pip)  |  low 24 bits
            (16 bits)|  d  |  digits 4-8    |
top    = n div 64^4  = digits 4..12   certified by n^2, n^3 at positions >= 10
bottom = n mod 64^10 = digits 0..9    certified by the low 10 digits of r^2, r^3
parent = digits 0..8 (one per valid r4 = n mod 2^24, under the slice's digits 4-8)
child  = parent + d * 64^9           (its digits 9 of r^2, r^3 are affine in d)
field (coordinate 4,8,5) fixes digits 5-7: 4,096 slices (digit 4 x digit 8)

today's overlap join at base 64: top = digits 3..12, bottom = digits 0..5, field = a 1e17 range of n
```

**Where it stands** [measured, 2026-11-19]: on the RX 9070 XT, base 64, 0.99 fs per admissible n against 4.76 fs
for v3.4.8's join, **×4.79**, exact at 64 lanes (on the development branch just before the cleanup, `66259bb0`).
On an RTX 3080 at a 240 W cap, 1.62 against 6.62 fs, **×4.09**; the cleanup changed it by +0.17 % (1.627 against
1.624). Base 65, which production has no join for: 3.47 fs on the 3080, 3.1 fs on the RX 9070 XT (untuned there).
(*fs per admissible n*: card time divided by the n whose residue mod b − 1 is one of the base's possible
residues for a nice number; 8 of 63 at base 64.) §8 has the table and the conditions.

---

## 2. The pipeline for one field, stage by stage

A field at base 64 is 4,096 slices. The library entry point is `midout::gpu::search_field`
(`common/src/midout/gpu.rs:3925`), which calls `field_run` (`:4044`). The stage table in `gpu.rs:11–18` is the
code's own summary; this section expands it.

**Costs** are ms per slice, measured on field 77777 by *cumulative timing stops* (the bench runs the field's
kernels up to a stage and nothing after; a stage's cost is the difference between two stops):

- **RX 9070 XT** (demoux, RADV, 64 lanes, 2026-11-19 14:10, trunk `66259bb0`, raw:
  `G2/build4s/window_1119/s_*.log`). Tops and parents were measured with the card at about 1.55 GHz and 90 W,
  because those stages alone do not load it; they are not at the operating point and are too high, which makes
  the main kernel's difference too low by the same amount. Tops + parents + main kernel together (stop 3) is
  3.843 ms; the whole slice is 4.312 ms; both of those ran loaded.
- **RTX 3080 at 240 W** (2026-11-19 09:20–09:42, parents shared, raw: `G2/build5l/raw/m2/`). The cleaned head
  has the same per-stage times to within noise (`G2/CLEAN-NOTES.md` §5).

| stage | runs | RX 9070 XT ms (share) | RTX 3080 ms (share) | guarded by |
|---|---|---|---|---|
| 0. field setup: slice list, sampled slice, key, shared parent lists | host, once per field; device for the lists | (host wait 0.14–0.23 s per field, measured; lists ~0.002 ms per slice, judged from instruction counts) | (in parents) | field is whole quanta; shape fits; list account |
| 1. tops | device, `tops5` once per 64 slices, the rest per slice | 0.759 (17.6 %), off the operating point | 0.393 (5.2 %) | `A_T1_*`, `A_TSCAN`, `A_T2_PLACED`, `A_TDIG`, `A_TREC` |
| 2. parents | device, per slice (over a list shared by 64 slices) | 0.476 (11.0 %), off the operating point | 0.525 (6.9 %) | `A_H2_*`, `A_SCAN16`, `A_SCAT`, `A_HSORT`; children counted here |
| 3. main kernel | device, per batch of classes | 2.607 (60.5 %) | 5.542 (73.2 %) | `A_JOBS`, `A_PROBES` = 8 × tops, `A_CHILD` = stage 2's count |
| 4. expansion + prefilter | device, per batch | 0.356 (8.3 %) | 1.108 with stage 5 (14.6 %) | cubes done, slabs walked, bits read = stage 3's survivors |
| 5. full check (production's, unchanged) | device, per batch | 0.112 (2.6 %) with stage 6 | (in stage 4) | its `ran` words: entries = list length, index sum |
| 6. done, group read | device word; host once per 16 slices | (in stage 5) | (in stage 4) | `A_DONE`; slices done = slices queued |
| 7. sampled CPU check | host thread during the field; one device rerun at the end | 9.2 s of CPU per 18.5 s field; host never waited | 27 s of CPU per 30.6 s field; +0.4 % | the slice's counts and its list, n for n |
| **whole slice** | | **4.312** | **7.568** | |

### Stage 0. Field setup (host)

- **In:** `(Coord, v_start, v_size)`. **Out:** the field's list of 4,096 slice keys, the sampled slice, the 8 key
  digits, the shared parent lists.
- `field_run` refuses anything but base 64, shape (4, 10), whole quanta, groups of 1–256 slices
  (`gpu.rs:4053–4065`; 256 because the per-unit counters are 32-bit, `:4060`). `Coord::field_digits`
  (`coord.rs:283`) turns the v range into the values t of the fixed digits; `Shape::slices_of` (`cpu.rs:105`)
  lists each t's slices, digit 4 innermost, so 64 consecutive slices share digits 5–8.
- **The key**: the 8 digits that order the parents (frequent digits in the tops' certificates first) come from
  the field's first slice, computed on the host by `slice_tops` (`gpu.rs:2372`, `:4104`). Any key is exact; the
  key only changes how many chunks the skip removes. [measured: kept fraction on one slice 0.1963 with the field's
  key against 0.1960 with its own]
- **The shared parent lists** (`build_anc`, `gpu.rs:2861`, kernel `anc8_kernel` `:942`): when the field's slices
  take at most 64 values of digits 4–7, each more than once (true for every field of the default coordinate),
  64 lists of depth-4 roots are built at once, one per value of digits 4–7. 870 MB of card memory.
- **The sampled slice**: one slice drawn at random (`RandomState` hashed with `v_start`, `:4082–4096`) is handed
  to a host thread that runs the CPU reference on it (`cpu_slice`, `:3861`) while the card works.

### Stage 1. Tops (device; `dtops` module, `gpu.rs:1828–2202`)

- **In:** the slice key `pip`. **Out:** the slice's tops sorted into segments by (unit, class), their certified
  digits in two forms, and production's 8-word top records for the check.
- A *top* here is a lead value h in [2^15, 2^16) and a unit d: 2^21 prefixes per slice, each covering 2^24 n.
  About 238,000 of them certify (11 %) [measured, slice 712012851].
- `tops5_kernel` (`:1920`) runs **once per 64 slices** (one value of digits 5–8): it certifies the 2^21 coarser
  prefixes n div 2^30 over their 2^30 n and lists the valid ones (19.4 %). `tops1_kernel` (`:1960`) certifies a
  slice's tops only under those (a finer interval keeps every digit its parent certified: exact by
  containment [proven]). `tscan` (`:2033`, one cube) scans the segment counts, `tops2` (`:2084`) scatters into
  segments, `tdigz2` (`:2124`) writes each top's digits as 6-bit fields (`tdig`), `toprec2` (`:2169`) writes
  production's top records.
- The certificate arithmetic is in 32-bit limbs and shifts (`cert_pow`, `:1879`); the host's version
  (`top_cert_b64`, `:2291`) is tested against the CPU reference on 20,000 prefixes [measured].
- **MAXPOP 17** (`gpu.rs:147`): no top at base 64 can certify more than 17 digits (only digits 17–25 of n² and
  30–37 of n³ can agree at both ends of a 2^24-wide interval with n ≥ 2^75) [proven, written at the constant];
  every slice seen has a 17-digit top, so there is no margin, and an 18-digit top would be an error of the field,
  not a lost survivor.

### Stage 2. Parents (device; `prep` module, `gpu.rs:874–1392`)

- **In:** the 9.30M *depth-4 roots* (values r4 = n mod 2^24 whose digits 0–3 of r², r³ are distinct; uploaded
  once per process) or the slice's shared list. **Out:** the *parent records*, sorted by (class, key), and `pseg`,
  the class boundaries.
- A *parent* is r = r4 + pip·2^24, the depth-9 bottom; it is valid when digits 0–8 of r² and r³ are 18 distinct
  digits (`parent()`, `:895`). About 1.04M per slice [measured]. Its record (`par`, one 16-byte vector,
  `gpu.rs:32–37`): the 64-bit mask, `r4` (24 bits), and `cacc` = the two digits and two step sizes from which
  each of its 64 children's digit 9 of r² and r³ follow: `(c2 + a2·d) mod 64`, `(c3 + a3·d) mod 64`.
- `hist2_kernel` (`:1020`) tests each root (over the shared list: 20.3 % of the roots [measured, field 77777]),
  `scan16` (`:1296`) scans, `scatter3` (`:1129`) moves the records and **counts the children of every listed
  parent** (`child_count`, `:1107`; used by the conservation law below), `hsort` (`:1174`, 16,128 buckets = 63
  classes × 256 key bytes) sorts each bucket.
- *Class*: n's residue mod 63 (the digit sum mod b − 1). A child's class is its parent's plus d, so one class
  partition of the parents serves all 64 units [proven].

### Stage 3. The main kernel (device; `g2_kernel`, `gpu.rs:283`)

- **In:** parent records, `pseg`, the tops' digit words and segments, the 8 roots, the job list. **Out:**
  *records*, and the *child lists* (every certified child's r4, in order).
- A *job* is (class c, unit d): one cube per job, 63 × 64 = 4,032 jobs per slice, each queued as two instances
  (probes [0, 576) and [576, 1,152); the second exits at once if there are none). A job's *probes* are the tops of
  unit d whose class pairs with c to one of the 8 roots, so every top is a probe of exactly one job per root
  [proven]; mean 473 probes per job, at most 619 seen [measured].
- Phases (the body's `phase 1`…`phase 4` comments, listed in the doc at `:272–279`): **1** append the certified
  children of 256 parents at a time to pending slots and to the job's child list, until 1,024 children (16 chunks)
  are pending; **2** transpose the round's chunks into per-digit 64-bit words with a shuffle transpose and take
  each chunk's common digits from registers; **3a** per probe, list the chunks the common-mask skip keeps; **3b**
  per (probe, chunk) kept, OR the words of the probe's digits: the complement is the *64-pair word*, one *record*
  per nonzero word into the plane's private slab of 256 records; **4** carry the rest to the front.
- Per slice [measured, slice 712012851]: 33.7M children, 529k chunks, 250M flat (probe, chunk) incidences, 123M
  kept after the skip (49 %), 10.9M records (175 MB), 11.77M *survivors* (bits set). A record is 16 bytes: `[top
  index, child-list position of the chunk's first child, word lo, word hi]` (`gpu.rs:58–62`); the top index rides
  in spare bits of the probe table (20 bits, checked by the host).
- Shared memory 21,504 B, 120 registers, 12 waves per SIMD on RDNA4 [measured offline with the AMD compiler].
  Launched in batches of classes: all 63 at once on CUDA and RADV (`Caps::b64`), 4 on lavapipe (its 128 MiB
  binding limit).

### Stage 4. Expansion and prefilter (device; `expand_kernel`, `gpu.rs:1675`)

- **In:** records, child lists, the tops' `thd` and prefilter masks. **Out:** *survivor entries* `(top index,
  r0)` in production's survivor-list layout, `r0 = n mod 2^30`, only for survivors that pass the prefilter.
- For each set bit it reads the child's r4, forms n mod 2^72 from r0 and the top, squares and cubes it, and
  tests the *prefilter*: digits 10 and 11 of n² and n³ are four distinct digits missing both the bottom's 20 and
  the top's certified digits at positions ≥ 12 (`cpu::prefilter`, `cpu.rs:232`, is the definition; the device
  mirrors it). 2.87 % pass [measured]. Two records per lane per step, their loads issued together (`keep_bits2`,
  `gpu.rs:1565`).
- Two arithmetic forms, the same predicate: `pf` (32-bit limbs; CUDA) and `pf24` (24-bit limbs, which RDNA's
  full-rate 24-bit multiplies take; every other runtime). Chosen by the runtime's type (`PrefilterForm`,
  `gpu.rs:2467–2487`); both are run by the tests on every compiler CI uses.

### Stage 5. The full check (production's `cubecl_join::check_kernel`, unchanged)

- **In:** the survivor list and the top records. **Out:** nice numbers. About 338,000 entries per slice.
  Imported, not copied (`gpu.rs:116–118`), with `CheckShape::new(64, 13, 26, 38, 5, 10, 10)`; `n = P·64^5 + r0`
  with `P` from the top record. Shown to rebuild the join's survivors exactly in probe mode [measured, CUDA].

### Stage 6. Done and the group read (host)

- `done_kernel` (`:1793`) adds 1 to the slice's done word and to the group's slice count. Slices are queued back
  to back on one stream with no synchronisation; once per group of 16 slices `finish_group` (`:3506`)
  synchronises, reads every small buffer in one call and runs every comparison (§4). Device buffers are allocated
  once and reused (the stream orders the reuse).

### Stage 7. The sampled CPU check, and the end of the field

- After the last group (`gpu.rs:4192–4237`): every reported nice n must be nice (`arith::unique_digits`, a
  separate implementation) and inside the field; the slices the device reports done must equal the field's slice
  count; then the sampled slice's counts from the field run must equal the CPU's, and the slice is run again
  alone on the device, unshared, and its prefiltered list must equal the CPU's **n for n** (`sample_compare`,
  `:3883`). Any difference is an error for the field. The result is `FieldOutcome` (`cpu.rs:702`): nice numbers,
  `survivors`, `checked`, slices.
- `survivors` and `checked` (survivors after the prefilter) are exact properties of (shape, field): equal on the
  CPU and on every device [measured: field 77777's 48,216,914,309 / 1,384,731,444 on CUDA at 32 lanes and on
  RADV at 64], but not comparable with today's join's counters, which is why telemetry carries the shape's label.

---

## 3. What a field is, and what that commits the project to

**The coordinate** (`common/src/midout/coord.rs`, the only part that would ever reach a server; it knows nothing
of the join). For a base with range [start, end) and digit positions k0 ≤ q0 < k1, write n = h·b^k1 + key·b^k0 +
low with key = digits [k0, k1); then

    v = start + key·(H·b^k0) + (h − h0)·b^k0 + low

with h0 = start div b^k1 and H the number of values h takes. v moves digits [k0, k1) above all the others and
keeps the rest in their order: one to one from the range into [start, start + H·b^k1) [proven; tested on random n
and both ends].

**The default at base 64 is (k0, k1, q0) = (4, 8, 5)** (`coord_digits`, `coord.rs:105`; `Coord::is_known`, `:181`, also accepts the older one): v is n with bits
24–47 (digits 4–7) moved up to bits 51–74, an exact bit permutation of [2^75, 2^76), no padding. A *quantum* is
H·b^q0 = 2^57 n: all n whose digits 5–7 take one value t. **A field is a whole number of quanta**, i.e. the n whose
digits 5–7 lie in a range [t0, t1), every other digit free. One quantum is 4,096 slices; 262,144 per base. A field
is written `(base, v_start, v_size)`; `range_size` on the wire is `n_count` (`coord.rs:307`), which differs from
v_size only at padded bases. The first coordinate, (4, 9, 6), fixing digits 6–8, is still known and searched.

**What that commits the project to:**

1. **Once a base's first field is handed out, its coordinate is fixed for that base.** A field is a set of n;
   fields cut along other digits are not unions of finished fields, so re-cutting a partly searched base leaves
   partly searched fields. The choice stays free per base, and between bases. [proven] (An earlier review and an
   earlier description said fields "can be re-cut later without redoing any search"; that is false as stated
   and is corrected in `DECISIONS.md` D2.)
2. **Fields are no longer intervals of n.** Anything that assumes they are breaks for base 64: "searched up to
   n = X", interval queries over the fields table, the stride path, today's join as a route. Every ordinary claim
   path must refuse such a field; the branch adds that refusal to the client (`wire::refuse_coordinate_space`,
   called from `client_api_async.rs`), and a server would need the matching filter. [proven]
3. **No field smaller than a quantum** (2^57) without a new coordinate. [proven: a v range inside a quantum cuts
   through the leading digits]

**What it leaves free** (each a change inside `midout/` only, never a field row):

- the join's shape: any (f0, k) with f0 ≤ 5 and k ≥ 9 can search a (4, 8, 5) field slice by slice
  (`Shape::fits`, `cpu.rs:90`) [proven]; the CPU reference searches the same small-base fields with two shapes
  and gets the brute-force answer with each [measured];
- chunking, key, sort, kernels, plane width, mask width, prefilter, device;
- work shared between slices inside a field: digits 4 and 8 are free inside a (4, 8, 5) field, so tops share
  across digit 4 (`tops5`) and parents across digit 8 (the shared lists). This is why 5–7 was chosen over 6–8:
  fixing 6–8 scatters the 64 slices that differ only in digit 8 over 64 fields. [proven; worth −3.1 %, measured]
- splitting a field across devices, or resuming part-way (slices are independent and their counters add).
- **Today's overlap join could still search such a field** by restricting its tops to the field's digits, at about
  ×1.9 of its normal cost without its leading-digit prune [judged, `G2/fs/REVIEW.md` §6]. So the commitment is
  to a set of n per field, not to this join.

**How much the field definition can cost at all** [judged]: only tops and parents depend on it (13 % of a slice at
base 64, 23 % at base 65, from measured stage times), so no other grouping of the same work can be more than
×1.15 (b64) or ×1.30 (b65) faster. For the long version: `G2/fs/REVIEW.md` (§1 and §2; its re-cutting sentence is
the one corrected above).

---

## 4. How the code knows the work ran

**The problem** [measured]: every counter starts at zero, and an all-zero slice is a legal result (slice 0 has no
survivors). On CUDA under CubeCL 0.10, a failed allocation panics on the runtime's own thread and every later
launch that binds the missing buffer silently does nothing; `sync()` still returns Ok. Before the accounts, a
failed allocation, a stop variable left in the environment, a dropped kernel, a dropped probe and a dropped parent
all produced `Ok` with fewer or zero survivors; all passed the plumbing checks of the time.

**The accounts** (`A_*`, one 20-word buffer per slice; table in `gpu.rs:11–18`, constants `:164–193`, compared in
`check_slice`, `:3680–3752`, and `finish_group`, `:3506–3673`): every stage writes **positive evidence of its own
work**, and the host compares it with a number it queued or a number another stage counted:

| stage | evidence | compared with |
|---|---|---|
| `tops5` | cubes done | its grid (8,192) |
| `tops1` | valid parents examined; tops certified | `tops5`'s list length; `tscan`'s total |
| `tscan`, `scan16` | ran | 1 |
| `tops2`, `tdigz2`, `toprec2` | rows written | the tops certified |
| `hist2` | cubes done; parents certified, counted by a ballot apart from the list | its grid; the list length |
| `scatter3` | rows moved; **children of the listed parents** | the list length; the main kernel's children |
| `hsort` | cubes done | 16,128 |
| main kernel | job instances finished; probes run; children seen | instances queued; **8 × tops**; `scatter3`'s count |
| expansion | cubes done; slabs walked; **survivor bits read** | 4,096; slabs used; **the main kernel's survivors** |
| check | entries checked, and their index sum | list length, n(n − 1)/2 |
| done | slice done; group's slice count | 1; slices queued |
| any kernel | plane-width error, guards (`C_ERR_*`) | 0 |

**The two conservation laws** tie stages together: the children the main kernel saw equal the children
`scatter3` counted from the same parents, and the survivor bits the expansion read equal the bits the main kernel
wrote. A plane sum with a lane-0 add is self-checking against a partly filled plane. [proven that each law holds
for a correct run; measured to hold exactly on every slice run, including a 100-slice sweep]

**What each catches** [measured by fault injection, `audit.rs`, on CUDA at 32 lanes and lavapipe at 8, and at
64 lanes on the RX 9070 XT]: a dropped main kernel ("job instances done: 0, want 8064"), dropped tops, a dropped
probe per job (−0.21 % of survivors), a dropped parent, a failed device allocation (9,216 MiB filled: "expansion
ran 0 of 4096 cubes"), a dropped shared-list build, a stop variable in the environment (now ignored by the
library), a lost record, a stale slab count, every cap overrun. No failed account is retried: it is an error for
the field, and the client submits nothing.

**The sampled CPU check** (`GpuOptions::cpu_check`, `gpu.rs:3816`; stage 7) is the only thing that sees a kernel
that does all its work and computes wrongly: a wrong certificate, a wrong `parent()` mask, a wrong child mask
(`scatter3` uses the same function, so the law holds), a false common-mask skip, a wrong transpose, a slice run
with the wrong digits, a prefilter that rejects too much (shown: `F_PF_DROP` passes every account and fails the
sampled check), a root wrongly left out of a shared list (the rerun is unshared on purpose). With one slice per
field, a defect touching a fraction f of slices is seen after k fields with probability 1 − (1 − f)^k [proven];
f = 1/1,000 is seen with 63 % probability after 1,000 fields, 0.4 % of the base [judged arithmetic].

**What nothing catches:**

- a defect shared by the device and the CPU reference (the join's predicate itself); covered only by the CPU
  reference against brute force on whole small bases (10–25 and 10–29 for nice numbers) [measured];
- production's check kernel judging a nice n not nice (production's own exposure, unchanged);
- a defect in slices the sample has not yet drawn;
- **at base 65 the sampled check is off** (its CPU slice takes 70–93 s against a 55 s field), so a wide kernel that
  computes wrongly while every account holds would be submitted;
- the host-tops path (benchmarks only, feature `midout-bench`) has no tops accounts.

Guards on widths (`C_ERR_IDX`: a class of more than 65,536 parents; a top index above 2^20; child-list positions
past the list, clamped; groups ≤ 256 slices) and the nice numbers' membership are listed in `gpu.rs:154–162` and
`:4202–4214`. For the long version: `G2/BUILD-NOTES.md` §10 and the soundness audit `G2/AUDIT-MO.md`.

---

## 5. Data that passes between stages

Written in the code (`gpu.rs:30–71`, and `gpu_wide.rs:39–60` where the wide path differs); summarised:

| between | what | size per slice (b64) |
|---|---|---|
| host → device, once per process | depth-4 roots (r4 values) | 9.30M × 4 B |
| host → device, once per field | key digits (8 words); 64 shared root lists | 870 MB (lists, allocated once) |
| tops → main kernel | `tseg` segments by (unit, `h mod 63`); `tdig` 4 words per top (20 6-bit digit fields, padded with the first digit, at most 17 read); `thd = h | d << 16`; `tmhi` (certified digits ≥ 12) | ~238k tops |
| tops → check | production's top record, 8 words per top | |
| parents → main kernel | parent record `[mask lo, mask hi, cacc, r4]` sorted by (class, key); `pseg` | ~1.04M × 16 B |
| main kernel → expansion | record `[top index, chunk's first child-list position, word lo, word hi]` in slabs of 256; child lists (r4 per certified child) | 10.9M × 16 B = 175 MB; 33.7M × 4 B |
| expansion → check | survivor entry `[top index, r0]`, production's layout | ~338k × 8 B |
| every stage → host | account `acc` (20 words); group counters `cnt` (64 units × 5 + error words + slice count) | |

Peak card memory [judged from buffer sizes and the 3080's measured 5.2 GB peak]: base 64 about 4.9 GB, base 65
about 8.3 GB; both ran on a 10 GB 3080 and on the 16 GB RX 9070 XT [measured].

---

## 6. The design decisions inside the join

Each: the decision, what else was tried or priced, the numbers, why this one. Costs are on the RTX 3080 unless
said; counts come from an exact CPU prototype on real slices.

### 6.1 The shape (f0 4, k 10)

- **Alternatives:** tops at f0 3 (today's); bottoms at k 11; (4, 9); f0 5.
- **Numbers:** f0 ≤ 3 tops cost at least 0.6 fs per admissible n at b64 (2.7 at b62) even if built once per base;
  k ≥ 11 bottoms need at least 5.4e-4 child generations per admissible n at b64 (5.2e-3 at b62) plus sorting
  2.4e-4 stored bottoms; (4, 9) tests ×1.9–2.0 the pairs and kept words of (4, 10) at b64 and b65 [measured
  counts]; f0 5 makes tops free but raises pairs to 6.3e-3 per admissible n [measured]. Pairs per admissible n
  are the product of the top and bottom certificate rates, measured within 10 % of the digit model [measured].
- **Why:** at b64, (4, 10) tests 3.5e-3 pairs per admissible n, exactly today's pruned pair count; nothing cheaper
  to build tests fewer [judged from measured counts]. The gain is per pair, not fewer pairs.
- **Long version:** `G2/RESULTS.md` §3–4.

### 6.2 Five middle digits (4–8) as the slice key

- **Alternatives:** contiguous ranges of n (today's fields); keys on low digits, residues or classes; four or six
  digits.
- **Numbers:** with contiguous ranges the bottoms are rebuilt per field; to keep the gain a range would have to be
  at least 1/10 of the base at b62 and the whole base at b64; with 1e17 fields nothing transfers beyond about ×1.05
  [judged, from measured counts]. Keys on low digits, residues or classes rebuild one side per field [judged]. Five
  digits make a slice 2^45 n: 2.4 ms on a 3080 when first estimated, 7.6 ms now with everything on the card.
- **Why:** the shape needs digits 4–8 fixed and every leading and low digit free inside the unit; that is exactly
  a slice. [proven, given the shape]

### 6.3 Tops on the device, with a hierarchy

- **Alternatives:** tops on the host in parallel with the card (the original plan); tops certified from scratch
  per slice; a further level once per field (f0 6).
- **Numbers:** host tops took 91 ms per slice on one thread and 18–19 ms on a rented box's 5-CPU quota, against a
  5.4 ms main kernel [measured]: the host cannot keep up. On the device, 0.46 ms per slice; with `tops5` once per
  64 slices, 0.36 ms (−0.13 per slice on the field) [measured]. The per-field level would save under 0.01 ms
  [judged]; not built.
- **Why:** the card is the only place fast enough on the hosts the fleet rents.

### 6.4 Parents shared across digit 8

- **Alternatives:** every slice tests all 9.30M roots; a shared parent *order* across the 64 slices (one sort).
- **Numbers:** a slice's parents depend on r mod 2^48, i.e. on digits 4–7 only for the depth-8 part, so one list
  per value of digits 4–7 is exact by containment [proven]. The lists hold 20.3 % of the roots; parents 0.728 →
  0.525 ms per slice; ten fields 1.6706 → 1.6189 fs, **−3.1 %**, every count equal with and without [measured,
  2026-11-19]. A shared order costs +4.2–7.0 % kept words [measured counts]; not built. Price: 870 MB.
- **Why:** it is free once fields fix 5–7 (§3), and measured.

### 6.5 Chunks of 64 and the common-mask skip

- **Alternatives:** no skip; chunks of 16–32; a tree over the chunks; 8-chunk probe lists; no sort, or a sort only
  inside each tile.
- **Numbers:** kept fraction 0.45–0.58 with the probe-weighted key, 0.57–0.77 unordered [measured counts]; chunks
  of 16–32 keep 0.39–0.52 but cost more per word; a tree over chunks visits 1.0–2.0× the flat count [measured
  counts]; sorting only inside a tile destroys the skip (0.58 → 0.72–0.89 kept), an 8-bit key over the whole class
  loses nothing [measured counts]. On the card the skip pays less than its count says: lanes are chunks, skipped
  chunks still occupy lanes, and only 60.5 % of lane slots do work; skip on is 10 % faster than off in the
  hand-written CUDA kernel, and finer 8-chunk lists were slower (5.27 against 4.89 ms) [measured].
- **Why:** 64 is the word and the plane; a chunk of 64 masks with 16–20 digits each shares at most 3–4 digits, so
  no group test removes much more than half [judged from measured densities].

### 6.6 Bit-sliced pairing against table lookups

- **Alternatives:** "four-Russians" byte tables (8 lookups per 64-pair word into a 2,048-entry table built per
  chunk); scalar ANDs per pair.
- **Numbers:** at b64 a table built per chunk is shared by only about 226 probes that survive the skip, so it costs
  8 + 2048/226 = 17.0 lookups per word against 16.4 bit-sliced [judged arithmetic on measured counts]; on a GPU the
  table reads are byte-indexed by lanes holding different probes (bank conflicts) and each table is 16 KB of
  shared memory [judged]. Measured cost of the bit-sliced word in the hand-written CUDA kernel: 32 ps all-in,
  bound by shared-memory issue (17 independent 8-byte loads per word) [measured].
- **Why:** fewer loads per word did not exist at these densities; the word's loads are the ones the transpose
  makes anyway.

### 6.7 The record format and the expansion

- **Alternatives:** the main kernel writes survivor entries itself; records that name the chunk's first parent
  (the host or a search re-walks it); single-bit records carrying the child's r4; u16 child lists.
- **Numbers:** entries written in the main kernel cost it +1.2 ms per slice for 0.67 ms saved after it
  [measured]; the first device expansion of parent-named records (a list kernel and a binary search) took 3.2 ms,
  the current one 0.92 ms (+0.13 ms in phase 1 to write the child lists) [measured]; single-bit records: kernel
  +0.3 ms, expansion +0.14 [measured]; u16 lists would save 67 MB of writes per slice, not built (needs evidence
  that the writes do not hide) [judged]. 92.8 % of records have one bit set [measured].
- **Why:** two ballots and one 16-byte store per record keep the main kernel's inner step short; the expansion is
  then a plain read with no search.
- **Not explained:** on the 3080 the expansion takes 1.1 ms where reading its 175 MB takes about 0.25 ms and its
  arithmetic about 0.2; a timing-only probe puts it at load latency (record → top → child → prefilter → write)
  [judged]. On the RX 9070 XT it measured 0.356 ms.

### 6.8 Where the prefilter sits

- **Alternatives:** no prefilter (every survivor to the check); production's prefilter, which lives inside its
  join walk; the bottom's mask gathered from the parent record.
- **Numbers:** in the expansion, before the list is written: check 2.42 → 0.52 s per field (−0.46 ms per slice),
  expansion +0.24 ms [measured]; gathering the parent's mask instead: 7.16 s against 5.10 s per field [measured];
  32-bit limbs then took the expansion to 4.63 s [measured]; on RDNA the 24-bit-limb form cut the prefilter loop
  from 240 to 197 cycles per wave-iteration [measured offline].
- **Why:** the check costs about 58 ps per entry and the prefilter removes 97 % before it; the expansion already
  holds n's pieces. The definition is production's test at the same digits, using the top's certificate above
  position 11, which is sound for every nice n and at least as strong [proven].

### 6.9 One narrow and one wide device path, not one generic path

- **Alternatives:** a mask-width parameter on the base-64 kernels; one generic kernel.
- **Numbers:** base 64 forced through the wide path costs +3.7 % (1.772 against 1.709 fs) [measured]. 27 % of
  `gpu_wide.rs` is a verbatim copy of `gpu.rs` and 19 host functions exist twice [measured by reading]. A generic
  kernel in CubeCL 0.10 is judged a trap (comptime branching across every kernel, generated code harder to
  verify) [judged].
- **Why:** base 64 pays nothing for width by construction; what the narrow path gains must be ported by hand,
  and the correspondence table at `gpu_wide.rs:62–80` is the map. Not ported: parent sharing, the host-tops
  path. The wide path has its own check kernel (production's holds digits in one 64-bit mask and refuses bases
  above 64), and that kernel has not been independently audited.

### 6.10 Per-stage accounts instead of a retry

- **Alternatives:** today's join's approach (detect a batch that did not run, refit the layout, retry); read back
  every large buffer at start.
- **Numbers:** the accounts cost +2.3 % per slice (7.714 → 7.891 ms), +2.5 % on ten fields; a first form with the
  checks at the end of the main kernel cost 0.55 ms per slice and was replaced by checks once per job before the
  rounds [measured].
- **Why** [judged]: the failures seen are a device that has stopped running launches (no retry helps; the field
  must fail) or a fixed cap (the layout is fixed per base, sized with margin, and an overrun has never been seen).
  A retry would add a second path to verify. Buffer read-back was not built: the accounts catch the same failure
  at the first group [measured].

### 6.11 A local coordinator instead of a server change

- **Alternatives** (priced in `G2/PROPOSAL.md` §2–4): A, base-64 fields in today's `fields` table as ranges of v,
  with a claim filter for old clients (about 150–250 lines); B, a separate table and endpoints (3–4× the work);
  C, no server change, a private coordinator.
- **What is built:** C. `scripts/midout_coordinator.py` (standard library, binds 127.0.0.1, state in files,
  never hands a field out twice) serves production's claim and submit format plus one key, `"coordinate":
  "midout:K0,K1,Q0"` (`midout/wire.rs`); the client flag `--midout-coordinator URL` (hidden from `--help`)
  refuses the production API by name and submits nothing after a failed account, a failed sampled check or a
  panic on any thread. The route costs nothing measurable: 1.6935 against the library's 1.6914 fs [measured].
- **Why:** nothing on the server needs to change until base 62 is done (late December) and a server design is the
  maintainer's decision (`DECISIONS.md` D4).

### 6.12 Smaller decisions

- **One stream, one synchronisation per 16 slices** [measured: driver overhead 0.04 ms per slice]. Launch batches
  of 63 classes on CUDA; 21, 9 and 3 classes were slower (32.2, 35.2, 47.6 s against 31.6 s per field) [measured].
- **Jobs over 576 probes run as a second instance**: 1 slice in 1,024 sampled has a 587-probe job (the
  prototype's kernel counted an error there) [measured]; more than 1,152 is an error (never seen).
- **Nice-ness rechecked on the host by a separate implementation** (`arith.rs` deliberately re-implements it: an
  oracle should not reuse the code it checks).

---

## 7. The CPU reference and the tests

- `midout/cpu.rs`: the join, exact, generic over the base (3–128) and the mask word (`u64`, `u128`), slow. It is
  the oracle for the device and for audits, not a route. Its nice numbers equal production's
  `process_range_niceonly` on whole bases 10–29; its survivors equal brute force on every field of bases 10–25
  in one or two shapes each; its roots equal production's residue filter for bases 3–128 [measured]. A mutation
  test of it (27 mutants) left 3 alive after three independent tests were added: two change only work counts,
  one edits an exemption no test base reaches [measured on the first cut branch; the same tests are on this
  branch since 2026-11-19 evening, the mutants were not rerun here].
- Device against CPU: 1,073 real base-64 slices equal n for n in an independent sweep (on the branch as it was on
  2026-11-18, before the accounts and the 5–7 coordinate) [measured]; since then, 100 of them again, the range's
  first and last slices, and every slice of one field under both coordinates [measured].
- Three test tiers (`mod.rs:25–47`): ordinary CPU tests in every `cargo test`; eight device tests named
  `cubecl_midout_*` that CI's lavapipe jobs select (both compilers, WGSL and SPIR-V; 3.1–3.7 minutes each on a
  5-CPU box, not timed on a GitHub runner); card-only and long tests behind the feature `midout-box-tests`, which
  CI never builds.

---

## 8. What is measured, and where

All end to end: tops, parents, kernel, expansion, check and the accounts on the card, whole fields of 2^57 n,
against v3.4.8's join (`be9cc923`, which is v3.4.8 plus a version bump; no join code changed between `7e0113fc`
and it) in the same session.

| card, base | middle-out | v3.4.8's join | ratio | date, conditions | exactness evidence | raw data |
|---|---|---|---|---|---|---|
| RX 9070 XT, b64 | **0.99 fs** (runs 0.995, 1.005, 0.971; median) | 4.762 fs | **×4.79** (best ×4.90) | 2026-11-19 13:55–14:29; trunk `66259bb0` (before the cleanup), RADV 64 lanes, 2.82–2.88 GHz, 303 W; five fields per run after a warm-up | 7 slices n for n at 64 lanes (4 through shared lists), wide b40 and b65, fault test, one field with the sampled check; counters equal the 3080's | `G2/build4s/window_1119/` |
| RX 9070 XT, b64, client route | 0.992 fs (12 fields, median 18.16 s each) | | | same session; local coordinator | 7 fields equal the bench's counts | `…/window_1119/route/` |
| RTX 3080 240 W, b64 | **1.619 fs** | 6.615 fs | **×4.09** | 2026-11-19 09:20–09:42; trunk with parent sharing; ten fields at 0.05–0.95 of the base; sampled check on | counts equal with and without sharing, field for field; every sampled slice equal | `G2/build5l/raw/m2/` |
| RTX 3080 240 W, b64, cleanup | head `5a048669` 1.6269 against trunk `66259bb0` 1.6242 (+0.17 %) | | | 2026-11-19 13:58–14:44; four alternating runs each | survivors, checked equal in all eight runs; 80 of 80 sampled checks | `G2/build6c/raw/ten_head`, `ten2_head` |
| RTX 3080 240 W, b65 | **3.468 fs** (×2.17 of b64's 1.600 in the same session) | none (production has no join above 64) | | 2026-11-19 10:21–10:33; five warm fields; sampled check off | slices n for n against the CPU reference incl. both range ends; whole small bases against brute force | `G2/build5l/raw/m4/` |
| RX 9070 XT, b65 | **3.12 fs** (two fields incl. warm-up; 3.02 the warm one) | none | | 2026-11-19 14:16; wide path untuned for this card | b40 and b65 slices at 64 lanes | `…/window_1119/w_65.log` |

How the baselines were measured: on the 3080, production's client against a local stub, the same ten 1e17 fields
three times in one day (6.615 fs each time, to 0.1 s). On the RX 9070 XT, production's join throughput harness:
the ten-field mean of 2026-11-18 (4.707 fs, from `7e0113fc`) scaled by two bracket fields measured in the same
session as the middle-out runs (×1.0118). The middle-out's fields each span the whole leading range; today's are
1e17 ranges at ten positions, three of them empty; dividing by admissible n puts both on one scale [judged].
Base 64 on the RX 9070 XT alone at 0.99 fs: about 55 days, against about 266 at 4.76 fs [judged arithmetic].

**The earlier ratios, and why they were wrong** (all reported before 2026-11-18 evening):

- **×8.3 to ×10** (the first model): GPU unit costs at or past the optimistic edge of every measured analogue,
  and one arithmetic error (the table-lookup cost amortised over all probes of a chunk instead of those that
  survive the skip). An independent review corrected it to about ×5 at b64 [judged, then].
- **×5.1** (hand-written CUDA kernel on a 3080), **×4.6** (the portable kernel on a 3080), **×4.7–5.5** (the
  portable kernel on the RX 9070 XT, pre-registered and pipelined): each was the kernel and parent preparation
  measured, **plus an assumed 0.085–0.115 fs for tops and survivor checks**. Once the whole path ran on the card,
  that part measured 0.45 fs (tops 0.10, turning 10.9M records into checkable entries 0.22, the unprefiltered
  check 0.13): about four times the assumption. The first end-to-end number was ×3.78 on the 3080; the
  expansion, the prefilter, the top hierarchy and parent sharing brought it to ×4.09 there. [measured]
- **"The prefilter adds 2.6 ms to the wide expansion"** was a difference against a different kernel on another
  card; with no prefilter at all the wide expansion takes 3.64 ms against 3.37 ms with it [measured].
- **The size of the branch** was reported as 6,500–7,000 lines; it was 13,525 insertions in 21 files against
  `origin/main` at `5a048669` and is 13,939 at `c2152084` (the wide path about 4,600, tests about 2,800) [measured by `git diff --stat`].

---

## 9. What is not done, or not known

- **Metal: never run.** The kernels pass production's Apple-miscompile lint (one site found and fixed); the
  paravirtual device on CI hangs above about 1 GiB of footprint and the join allocates several hundred MB with 4
  classes per batch; CI's 30-minute macOS job would gain about 2.5 minutes per step. Since 2026-11-19 evening the
  client route refuses a Metal device by its name (`is_metal`, `client/src/midout_route.rs:198`, unit-tested on
  device names) until the join has been checked on Apple hardware; **the refusal itself has not run on a Mac**.
- **The cleaned branch has not run on the RX 9070 XT.** ×4.79 is the trunk just before the cleanup; on the 3080
  the cleanup is +0.17 % and per-stage times are equal, and the main kernel's generated CUDA differs only by dead
  code removed [measured]; whether the same holds for RADV's code is not measured. The four commits after the
  cleanup (head `c2152084`) change no kernel: the generated CUDA of all 15 narrow and 14 wide kernels is identical
  to `5a048669`'s, and five warm fields timed 1.7162 against 1.7187 fs on a 3080 in one session [measured]. Byte-identical generated code
  cannot be shown on CubeCL 0.10 (two runs of one binary give different SPIR-V) [measured].
- **The wide path is untuned on the RX 9070 XT** (its main kernel's shared memory is 3 KB over the 12-wave
  threshold): base 65 is ×3.2 of base 64 there against ×2.17 on the 3080. **What the wide expansion spends ~3.3
  ms per slice on is not known** (narrow: 1.1 ms on the 3080); it is not the prefilter.
- **Bases 66–70: partly.** Base 68 was exact on two slices before the paths were merged (2.13 fs on a 20 GB card)
  and has not run since; it needs a 2D tops grid to launch on Vulkan. Bases 69 and 70 have never run; base 70
  needs the (4, 11) shape and a 64-bit slice key. The route refuses 66–70 (`route.rs:36–58`).
- **The sampled check does not fit base 65** (CPU slice 70–93 s against a 55 s field): off there, so base 65
  relies on the accounts alone for a kernel that computes wrongly. A multithreaded CPU slice would fix it; not
  built.
- **No server design is chosen**; nothing on the server exists. The coordinator has served one client at a time
  on the same machine; several clients, a remote coordinator and long runs are untested. A killed client leaves
  its field claimed unless `--reissue-after` is given. The client claims the next field only after submitting the
  last.
- **Fault bits are a runtime kernel argument** (`fault: u32`, 0 in production), not compile-time; making them
  compile-time changes every faultable kernel's generated code and needs the same verification again. No test
  switch can reach a release build [measured by reading].
- **The older field definition is still in the code.** The review fixes of the first two cut branches are on
  this branch since 2026-11-19 evening (private `Coord` fields with getters, three independent tests, the fixed
  brute-force test, true docs for the default coordinate). What the branch keeps beyond those cut branches: the
  older coordinate (4, 9, 6) as "also known" at bases 64 and 65, and the coordinates of bases 65 and 68–70, which
  the wide path and its tests use. Whether the older one is dropped is `DECISIONS.md` D2.
- **Smaller:** `run_slice` and `run_slice_dev` are public and return one slice, not a field; lavapipe at 16 lanes
  aborts in lavapipe itself; the 3080's unexplained 0.6 ms in the expansion (§6.7); the shared lists are sized
  for 3.4M roots each (an overrun is an error; the longest seen is 1.89M).

---

## 10. Where the code is, and how to run it

**Branch** `dev/mo-clean` on the fork `wasabipesto-bot/nice`, head `c2152084`, 18 commits on the development
trunk `66259bb0`; worktree `~/projects/nice/.worktrees/midout-clean`. The development history before the cleanup
stays on `dev/middle-out-join`. No pull request is open (`DECISIONS.md` D9).

| file | lines | what |
|---|---|---|
| `common/src/midout/mod.rs` | 62 | module map; the three test tiers |
| `common/src/midout/coord.rs` | 634 | the work unit: coordinate, quantum, field ↔ fixed digits, `n_count` |
| `common/src/midout/cpu.rs` | 1,150 | the exact CPU reference: shape, certificates, parents, slice join, prefilter, brute-force predicates |
| `common/src/midout/arith.rs` | 138 | 384-bit arithmetic and nice-ness for the reference (re-implemented on purpose) |
| `common/src/midout/mask.rs` | 75 | digit masks generic over `u64` / `u128` |
| `common/src/midout/gpu.rs` | 4,852 | base-64 device path: kernels (`kernels`, `prep`, `post`, `dtops`), driver `GpuJoin`, `search_field`, tests |
| `common/src/midout/gpu_wide.rs` | 4,594 | two-word-mask device path for bases 65–70 (and small bases in tests), its own check kernel |
| `common/src/midout/audit.rs` | 872 | parity sweep and fault injection (tests only) |
| `common/src/midout/route.rs` | 170 | one entry point per base for a client route, with telemetry |
| `common/src/midout/wire.rs` | 238 | the claim key, the route name, the production-host refusal, the ordinary-route guard |
| `common/src/cubecl_join.rs` | +2/−2 | two constants (`CHECK_CUBES`, `RAN_WORDS`) made `pub(crate)` so the check's grid and account are shared, not copied |
| `common/src/client_api_async.rs` | +50/−2 | the ordinary claim refuses a coordinate-space field (and its test) |
| `common/src/lib.rs`, `Cargo.toml` | +1, +19 | `pub mod midout`; features `midout-bench`, `midout-box-tests`, `midout-fault` |
| `common/examples/midout_bench.rs`, `midout_wide_bench.rs` | 203, 180 | whole-field timing (feature `midout-bench`) |
| `common/examples/midout_fields.rs` | 56 | a work list of fields for the coordinator |
| `client/src/midout_route.rs` | 451 | the route: claim, search, submit; guards; Metal refusal; panic hook |
| `client/src/main.rs`, `client/Cargo.toml` | +25, +3 | the hidden `--midout-coordinator` flag |
| `scripts/midout_coordinator.py` | 164 | the local coordinator (standard library, 127.0.0.1) |

**Run it on one machine** (CUDA shown; for Vulkan use `--features cubecl-spirv` and `--gpu-backend cubecl`):

```sh
cargo build --release -p nice_client --features cubecl-cuda
cargo build --release -p nice_common --example midout_fields
target/release/examples/midout_fields --base 64 --spread 12 > work.json
python3 scripts/midout_coordinator.py --worklist work.json --state ./mo-state --port 8471
target/release/nice_client niceonly --midout-coordinator http://127.0.0.1:8471 --repeat --username NAME
```

Records land in `mo-state/claims.jsonl` and `mo-state/submissions.jsonl`; `GET /status` gives counts. The timing
bench: `cargo build --release -p nice_common --features cubecl-cuda,midout-bench --example midout_bench`, then
`midout_bench --cuda --fields 13107,77777` (sampled check on by default). Tier (b) tests on a software device:
`cargo test --release --features cubecl -p nice_common -- --ignored cubecl_midout`.

**Terms.** *Slice*: every n sharing digits 4–8. *Unit*: digit 9 (`d`). *Top*: a lead value and unit, i.e. the
prefix n div 64^4 under a slice, with its certified digit mask. *Bottom*: n mod 64^10. *Parent*: a depth-9 bottom
(digits 0–8). *Child*: a parent plus a unit digit. *Class*: residue mod 63. *Job*: (class, unit), one cube.
*Probe*: a top run against a job's children. *Chunk*: 64 consecutive children of a class. *Record*: one nonzero
64-pair word. *Survivor*: a (top, child) pair with disjoint masks and compatible classes. *Quantum*: the smallest
field, 2^57 n at base 64. *Coordinate*: the renumbering v of n that makes fields ranges. *Admissible n*: n whose
residue mod b − 1 can be a nice number's.

**For the long version** (all under `~/projects/nice/scratchpad/2026-10-research-program/G2/`): `RESULTS.md` (the
original design and its cost tables), `REVIEW.md` (the first review of it), `BUILD-NOTES.md` (the build: §2 the
field, §3 decisions, §9–§14 the measured steps), `AUDIT-MO.md` (the soundness audit), `fs/REVIEW.md` (the field
structure), `BUILD-NOTES-CLIENT.md` (coordinator and route), `BUILD-NOTES-WIDE.md` (bases above 64),
`CLEAN-NOTES.md` (the cleanup), `MAINTAINABILITY.md` and `PR-PLAN.md` (the proposed series of pull requests),
`PR12-REVIEW.md` (the review of the first two), `CARRYBACK-NOTES.md` (that review's fixes brought onto this
branch, with every test tier re-run), and `../EXPERIMENTS.md` for every number with its raw data.
