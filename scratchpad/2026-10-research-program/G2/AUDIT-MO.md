# The middle-out join: independent soundness audit of `dev/middle-out-join` at `91ac0761` (2026-11-18/19)

Brief: `G2/BUILD-BRIEF-3S.md`. Auditor: one agent, alone, 22:00–01:45 UTC. Box: Vast 61286074 (RTX 3080, CUDA, the
build engineers' box, hosts block checked before every client-type binary: production hosts → 127.0.0.1 and ::1).
Code read and tested: `common/src/midout/{coord,cpu,gpu}.rs` at `91ac0761`. Line numbers below are **of `91ac0761`**
(`gpu.rs` unless named). Tests and fault switches: branch **`dev/mo-audit`** (from `91ac0761`; `common/src/midout/audit.rs`
and switches in `gpu.rs` that only the audit tests set). Raw logs: `G2/audit1/`.

## Verdict

**The device equals the CPU reference on every slice tried (__SWEEPN__ slices, 0 differences), and no path was found by
which correct kernels on a healthy card lose a candidate. But the host's accounts only check the plumbing after the main
kernel: anything that stops the main kernel, the tops or the parents from running, or makes them compute less,
returns a field with fewer (or zero) survivors as a success. That is reproduced, not suspected: a device allocation
failure (CubeCL panics in its stream thread, the caller sees nothing) returns every slice with 0 survivors and all
accounts passed; so does the `MIDOUT_STOP` timing switch left in the environment.** Fix those two before any field is
reported (findings 1.1, 1.2), and add the conservation accounts of 1.3 so that the next defect inside the kernels is
loud rather than found by a parity sweep.

## 1. A candidate or a count can be lost silently

### 1.1 A device allocation failure returns a field with no survivors as a success (reproduced)

- **Where:** `GpuJoin::new` allocates every buffer with `client.empty`/`create` (2262–2297) and never reads one back;
  `finish_group` (2759–2834) trusts `client.sync()` (2760) to report device failures. On CUDA (cubecl-cuda 0.10) a
  failed allocation **panics inside CubeCL's stream thread** (`DSD-0-0`, `cubecl-cuda/src/compute/server.rs:124`,
  "can't allocate buffer of size 647127040"), and every later operation on that handle panics there too
  (`stream.rs:101`, "Memory page 0 doesn't exist"). The calling thread gets `Ok` from `new`, from every launch, from
  `sync` and from every read of the small buffers that did get allocated.
- **Reproduction** (`audit::audit_oom_is_silent`, `G2/audit1/oom.log`): fill the card's memory (4,544 MiB on top of a
  process holding 5 GiB), then `GpuJoin::new` and the production group path (`queue_dev` + `finish_group`, exactly
  `search_field`'s) on slices 712012851 and 318575442: **both return `Ok` with children 0, chunks 0, survivors 0,
  checked 0, tops 0** (only `tested`, from a buffer that existed, is non-zero), `nice()` returns `Ok([])`. Every
  account passed. A field run this way is reported searched and empty.
- **Found by accident first:** my own two-`GpuJoin` key test ran while the sweep held 5 GiB; the second join's 647 MB
  record buffer failed, its kernels were dropped, and its comparisons came out "equal" because both sides were the
  same nothing (`keys.log`; the test was re-run alone, `keys2.log`). The same thing would happen to a client sharing a
  card with another process, a second client on one card, or a smaller card.
- **Why production's join does not have this hole:** it counts the cubes every kernel ran against the launch
  (`T2/SOUNDNESS.md` §4: "Per-kernel cube counters against the launch"). The middle-out path dropped that: no kernel
  of its own reports that it ran.
- **Fix:** (a) per launch batch, a "cubes done" counter for the main kernel (each cube's thread 0 adds 1 at exit;
  must equal the batch's 2·classes·64 instances), the expansion (= `EXPAND_CUBES`) and the tops kernels; (b) per
  slice, plausibility floors that hold for every base-64 slice: tops > 0, children > 0, survivors > 0 (the sweep's
  minima are in §5); (c) in `GpuJoin::new`, write and read back one word of each large buffer (an allocation that
  failed then fails the read or reads wrong); (d) treat any panic of the runtime's thread as fatal (a panic hook
  that aborts the process; the client must never submit after one).

### 1.2 `MIDOUT_STOP` in the environment turns `search_field` into a no-op that succeeds (reproduced)

- **Where:** `GpuJoin::new` reads `MIDOUT_STOP` from the environment (2299–2302); `upto` (2313) skips launches;
  `finish_group` returns `DevCounts::default()` without any account when `stop != 6` (2761–2763);
  `search_field` then reports the field (`total.slices` is counted by the host, 2945, so the slice check at 3016
  passes).
- **Reproduction** (`audit::audit_stop_env_is_silent`, `stop_env.log`): stop 2 on field 77777: `search_field` returns
  `Ok` in 5 s with **survivors 0, checked 0, slices 4096, nice []**. Any value but 6 (e.g. 7, which launches
  everything) skips every account.
- **Fix:** read it only in the bench (pass it in `Caps` or a test-only constructor), and have `search_field` bail
  unless every stage runs and the accounts are on.

### 1.3 The accounts cannot see a kernel that computes less: shown by fault injection

The accounts (§4) are conservation laws on the records → list → check plumbing. Everything that decides *which* n
are survivors is outside them. Injected into the production group path on 2–3 slices (`audit::audit_faults`,
`faults1.log`–`faults3.log`; slices 502136830 (612 probes), 712012851, 806726610 (a 141-probe job), 0, 2^30 − 1):

| fault (switch) | what it models | accounts | counts |
|---|---|---|---|
| `F_SKIP_MAIN` (2) | main kernel launch dropped | **pass** | survivors 0 (of 23.5M) |
| `F_SKIP_TOPS` (4096) | tops kernel dropped | **pass** | tops 0, survivors 0 |
| `F_DROP_PROBE` (8) | each job's last probe not run (a probe-table or window defect) | **pass** | survivors −50,412 (−0.21 %) |
| `F_DROP_PARENT` (8192) | parents of 1 root in 997 wrongly uncertified (a `parent()` defect) | **pass** | survivors −23,963, children −68,072 |
| `F_PF_DROP` (1024) | prefilter wrongly rejects ~1/1024 of survivors | **pass** | checked −672 (survivors unchanged) |
| `F_DROP_REC` (32) | cube 0 loses a record between kernel and expansion | loud ("23525333 read, kernel counted 23525259") | — |
| `F_SLABCNT` (2048) | a slab's count never written (stale count read) | loud (read ≠ counted) | — |
| `F_SKIP_CHECK` (512) | check kernel dropped | loud ("0 of 338191 entries") | — |
| `F_PMAX300`, `F_POP12`, `F_SLAB_CAP`, `F_SCAP` | limits shrunk (§3) | loud | — |
| `F_IDX13` (16) | pending parent index read as 13 bits | loud **by accident** (garbage masks overflowed the slabs) | — |

By reasoning, also silent: any wrong mask in phase 2's transpose or the common-mask skip (`cmv`, 657–670: a false
"common" digit skips a probe-chunk pair), a wrong `cert_pow` digit in the device tops, a wrong segment table, a cube
that exits early, a slice that runs with the wrong `pip`. The device path's only evidence against these is the CPU
parity tests. (Prefilter note: `checked` would change, but nothing compares it with anything.)

- **Fix, in order of cost:** (1) the cube counters of 1.1 (catch dropped launches and early exits); (2) **probe
  conservation**: every top is a probe of exactly 8 jobs of its unit (one per root), so Σ over all instances of
  `nprobe` = 8 × tops of the slice; the kernel adds its `nprobe` to a counter, the host compares with `tstat[0]`
  (catches `F_DROP_PROBE`, a skipped job, a short probe window); (3) **children conservation**: count each parent's
  certified children in `hist2` (64 affine digit tests per parent) and compare with phase 1's count (catches
  parents lost between `hist2` and the kernel); (4) **a sampled CPU audit in the client** (piece G): the host waits on
  the card 30.5 of 31.7 s per field, so one CPU core can run the reference on one random slice per field (35 s) and
  compare survivors, checked and the prefiltered list. It is the only check that sees a kernel that computes wrongly;
  a defect touching 1 slice in 1,000 is found within ~1,000 fields (0.4 % of the base) instead of never.

## 2. A candidate or count is lost but detected (loud)

- **Probe table past 2·PMAX = 1,152** (`C_ERR_PMAX`, 288): loud (shown with the window shrunk to 300: "pmax 10").
- **Top popcount past MAXPOP** (tops1, 1689; the kernel reads 17 digits, so a longer top would *over*-report pairs,
  never lose one): loud ("238857 tops of more than 17 digits" with the limit at 12). See §3: 17 is a proven maximum
  at base 64, so this cannot fire there.
- **Records → expansion**: a lost record or a stale slab count is loud through Σ bits read = Σ survivors counted
  (2828). Caveat: the account is per *group* and by count only: a lost record and an extra stale record of equal
  popcount in one group would cancel (not observed; both injections changed the count).
- **Capacities** (tops 2799, parents 2814, slabs 2820 and `C_ERR_SLAB`, list 2783): loud, shown for slabs and list.
- **Check completeness** (`ran[5]`, `ran[6]`, 2790): loud.

## 3. Robustness (not a loss today; a margin, an unchecked width, a trap for the next change)

1. **The pending parent index is 16 bits, unchecked** (`pq` slots, 422 `idx - pb`, 426, 465–467 `& 0xFFFF`): a class
   of more than 65,535 parents would alias parent indices (the even slot's write also spills into its odd
   neighbour). Observed max class __CLSMAX__ (margin __CLSMARGIN__×), so not reachable at base 64; nothing would say so
   if a later shape or base changed it (the 13-bit injection was loud only because the garbage overflowed the slabs).
   Fix: an error counter when `pe − pb > 65,535` (one compare per cube).
2. **The top index rides in 20 bits** of the probe word (319, 340, 733): safe only because `Caps::tops` (480,000) <
   2^20 and the tops cap is checked. Fix: `ensure!(caps.tops <= 1 << 20)` in `new`.
3. **The child-list write is unbounded** (419; `lcap` 2259 = 64 × the batch's share of the parents cap with 1/16
   slack): with batches of 4 classes (lavapipe) a batch whose classes hold more than its share writes past `clst`
   before the parents account (checked only for the whole slice) can say so. Not reachable on CUDA (one batch).
   Fix: per-batch parent count against the share, or size `clst` by the parents cap.
4. **MAXPOP 17 has margin 0 and needs no more:** every one of 16,384 + __SWEEPN__ slices has a 17-digit top, and 17 is
   the maximum at base 64: over a top's interval (2^24 n, n ≥ 2^75) n² moves by ≥ 2^100 > 64^16 and n³ by ≥ 3·2^174 >
   64^29, so only digits 17–25 of n² (9) and 30–37 of n³ (8) can be certified. Write this proof next to the
   constant; it does not hold for other bases (the wide path must redo it).
5. **`search_field` checks the slice count against itself** (2945 vs 3016: both host loop counters). Make each slice
   report on the device (its `tstat` or a per-slice cube counter) and count those.
6. **Reported nice numbers are checked to be nice but not to lie in the field** (3010–3014). Cheap to add.
7. **u32 counters per unit per group** (`cnt`, 64 × 5): observed max per unit per slice: flat __FLATD__, survivors
   __SURVD__; at group 16 the margin is ~__FLATMARGIN__×. `C_LSLOTS` wraps but is unused. Fine; a group-size cap of
   ~500 slices would keep it so.

## 4. What the host's accounts catch, and what they cannot

Checked once per group (`finish_group`, 2759–2834) and per field (`search_field`, 3007–3018):

| account | catches | cannot catch |
|---|---|---|
| kernel error counters: plane layout (265), probes > 2·PMAX, slab overflow | wrong plane width or lane layout in the main kernel; capacity overflows | — |
| per batch: list ≤ cap; the check took every entry once (count + index sum) | list overflow; a check dropped or cut short | — |
| tops ≤ cap; no top > MAXPOP digits | capacity, popcount | tops missing or wrong (no lower bound, no recount) |
| parents ≤ cap; slabs ≤ cap | capacity | parents wrongly uncertified or missing |
| Σ bits read by the expansion = Σ survivors counted by the kernel (per group) | records lost or garbled between kernel and expansion; a stale slab count | which survivors the kernel found |
| slices = slices queued (host counters) | nothing (tautology) | a slice skipped |
| reported nice numbers are nice | a false positive | — |

### 4.1 A class of its own: a launch that did nothing leaves all-zero counters, and all zero is a legal result

Every counter the host reads starts at zero (`mk(vec![0; ..])` per group or batch), and **every account on the trunk
is satisfied by all zeros**: error counters 0; list 0 ≤ cap; check took 0 of 0 entries with index sum 0; tops 0 ≤
cap; 0 tops past MAXPOP; parents 0 ≤ cap; slabs 0 ≤ cap; bits read 0 = survivors counted 0; slices = slices queued
(host); no nice numbers. None asks for positive evidence that anything ran. That is why 1.1 (allocation failure),
1.2 (`MIDOUT_STOP`), `F_SKIP_MAIN` and `F_SKIP_TOPS` all pass. (The wide branch found the same thing independently
tonight with another process holding the card's memory, `G2/build2e/raw/m2_oom_failed/`, and added `C_JOBS`, job
instances that reached their end = instances queued; on the trunk I reproduced it in-process, `oom.log`, and by
accident with a second process holding 5 GiB, `keys.log`.)

Positive evidence each stage should return, compared with what the host queued:

| stage | evidence to return | compared with |
|---|---|---|
| `tops5` (per 64 slices) | cubes done; `l5n` > 0 | grid size; a floor (the sweep's minimum valid parents) |
| `tops1`/`tscan`/`tops2` | cubes done; tops placed by `tops2` | grid; = `tstat[0]` (Σ segment counts) and > 0 |
| `tdigz2`, `toprec2` | rows written | = min(`tstat[0]`, cap) |
| `hist2`/`scan16`/`scatter3`/`hsort` | cubes done; `pseg[63]` | grid; = `lcnt` and > 0 |
| main kernel | **job instances that reached their end** (the wide branch's `C_JOBS`); Σ `nprobe`; children | = 2·classes·64 per batch; = 8 × tops; = an independent count in `hist2`, > 0 |
| expansion | cubes done; slabs walked | = `EXPAND_CUBES`; = `min(slabn, cap)` |
| check | production's own work counter (`ran`) against its grid | as production does (T2 §4) |
| per slice | one "slice done" word written by the last kernel of the slice | the host counts slices from these, not from its loop |

Not seen by any account (shown silent in §1.3, or by reasoning): a dropped launch of the main or a tops kernel
(and therefore any device allocation or runtime failure, §1.1), a probe not run, a chunk not probed, a parent
dropped, a false common-mask skip, a wrong certificate, a prefilter that rejects too much, a slice run with the
wrong digits, a partly filled plane in any kernel but the main one (the expansion, `hist2` and the tops kernels have
no plane check; the main kernel's check, 265, is `PLANE_DIM != w || t % w != lane`).

## 5. The parity sweep

`audit::audit_sweep`: per slice, the device (production kernels, device tops, `run_slice_dev`, the slice's own key)
against the CPU reference (`cpu::slice_join`): device tops = host tops (h, d, mask); the prefiltered list = the
reference's survivors that pass, **n for n**; with the prefilter switched off (`F_NOPF`, a second `GpuJoin`), the
**whole survivor set** = the reference's (count and an order-independent 3-word hash of every n); children, chunks,
flat, survivors, checked equal; `kept` too where the keys agree. One JSON line per slice with the limits' values.

- **Slices:** __SWEEPDESC__
- **Result:** __SWEEPRESULT__
- **Also:** the base's first and last fields whole on the device (`fields_ends.log`, `midout_bench`, group 16):
  every account passed, survivors 47,417,055,193 and 48,000,609,298, checked 1,361,908,290 and 1,378,233,015, 33.9 s
  and 30.5 s. Key independence (`audit_key_and_group_independence`, `keys2.log`): 10 slices × 5 foreign keys
  (identity, reversed, three other slices'): prefiltered list and survivor-set hash unchanged (kept changes, as it
  should); the group path (one group of 10, two of 5) = the per-slice sums. Group path vs single slices
  (`audit_group_vs_single`, `group_vs_single*.log`): the first 128 slices (two 64-slice parent groups) of fields 0,
  77777 and 262143, groups of 16 against one at a time: survivors, checked, children, chunks, flat, tops, tested equal.
  Coordinate (`audit_coord_slices_partition`): §6.

### The limits (observed over the sweep and the tops scan of 16,384 seeded slices, `tops_scan.jsonl`)

__LIMITS__

## 6. The coordinate layer

`coord.rs` is exact as far as I can test or read: `audit_coord_slices_partition` (base 64 and the padded base 65):
the slices of all 64³ (65³) fields are a partition of the slice keys (each value of digits 4–8 in exactly one field,
once), and 200,004 n per base (both ends of the range, their neighbours, random n) map to the field their v names,
to a slice of that field, and to a lead inside the leads the tops enumerate (`[2^15, 2^16)` on the device). With the
existing tests (bijection of v, quantum = digits 6–8, small padded bases exhaustively, b65 counts) every n of the
range is in exactly one field and one slice, and the slice covers every (lead, digit 9, low 4 digits) of it.
`n_count` for H ≤ 2 and the clipped first/last h are covered by the small-base test. No finding.

## 7. The known classes of defect, read

- **Plane width, lane 0:** the main kernel's W 64 branches (phase 2's `j == 32` half swap, the 64-bit ballots, the
  W 64 common-mask test, the `sl` row stores) read consistent with the W 32 path that the sweep exercises, but have
  **never run** (no W 64 device here; lavapipe runs 8 or 16). Lane-0 reductions (`pl` 252, slab ids 776–778,
  `hist2` 976–979, the expansion 1454–1457) are all in uniform control flow with the whole plane active; NT 256 is a
  multiple of every W, so planes are full on any driver that packs them. A Vulkan driver choosing wave32 under
  `plane_size_max` 64 is caught by the main kernel's plane check (loud); the other kernels take `PLANE_DIM` or are
  correct at 32 too.
- **Atomics and barriers:** phase 1's odd-slot OR after the next barrier (405, 434), the `wcnt` double buffer, the
  probe list reusing `pq` (3a/3b) with the carried slots in registers, the phase-4 rewrite after the barrier at 821:
  no race found. `comm`/`cmv` are reset per round before phase 2 and read after barriers.
- **The SPIR-V atomic-store merge defect:** no basic block in these kernels holds two atomic stores of the same
  value (the stores of 0 and `u32::MAX` at 292/298 and 838/841 are in separate `if` blocks; `stat` 1411–1412 stores
  two different loads). Not present.
- **The two-break loop defect:** no `loop`/`break` in any kernel (the main kernel's `going` flag, 367, avoids it).
- **Shared memory read before written:** `pq` slots, `sl` rows for `q < nch` (all 64 rows written for every live
  chunk; rows of dead chunks are masked by `vlo/vhi = 0`), `prob_d` (read only below `nprobe`; past-list entries
  read slot 0 and are masked), `hsort`'s `sk` (filled to `n4`/`p`): none found.
- **Overflow at the range ends:** `parent()` (mod 2^60 via u64 wrap), `tops1`/`tops5` limbs (a < 2^76 in 3 limbs,
  squares in 6, cubes in 9), the top record (P < 2^46), `pf` (n mod 2^72, every carry term present), the child-list
  positions (64 × 2.23M < 2^32): no overflow at n = 2^75 or 2^76 − 1; the sweep includes slices 0 and 2^30 − 1 and
  the first and last fields.

## 8. Gaps in the tests (and what I did not get to)

1. **W 64 never executed** (the RX 9070 XT's width, 86 % of the planned work): the first W 64 run must be a parity
   run (`gpu_slices_equal_cpu` and this sweep) before any field.
2. **SPIR-V only on lavapipe W 8, 2 slices** (the engineers'); I ran none (the box's CPU was the sweep's). W 16 aborts.
3. **The sweep compares against the CPU reference, not against brute force, at base 64.** Shared conceptual errors
   (the shape's predicate) are covered only by the small-base brute-force test; the b64-only arithmetic of the
   reference (`mm`'s slow path at m = 2^72 in the prefilter, unused below base ~41) is checked by reading and by the
   device's independent limb arithmetic agreeing on every slice.
4. **No test of the host-tops path** (`run_slice`, `queue_prep`; not the default) beyond the engineers'.
5. Not done: production's check kernel itself (unchanged production code), lavapipe, the wide-mask work (excluded),
   other CubeCL failure modes than allocation (kernel compile or launch failure: I expect the same silent path, not
   shown).

## 9. Proposed order of fixes

1. Device failures must be loud (1.1): cube counters per kernel per batch, per-slice floors, a panic hook that
   aborts, a read-back of each buffer at start.
2. `MIDOUT_STOP` out of the library path (1.2).
3. Probe and children conservation accounts plus a sampled CPU slice per field in the client (1.3).
Then the guards of §3 (16-bit class index, 20-bit top index, per-batch `clst` bound) and the W 64 parity run.
