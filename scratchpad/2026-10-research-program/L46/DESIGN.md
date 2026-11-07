# L46 DESIGN: a static bucket order for the top layer (2026-11-07)

Base: fork `pr/join-lean-prefilter` f3fb390 (main 6f060a9 + #241 + #246). Branch `exp/join-static-buckets`.

## The invariant it rests on

A kept top of slot v from prefix P0 goes, today, into the buckets `(key, cls_r)`, r over the digit-sum roots, with
`key = P0 mod b` (key level; 0 otherwise), `pc = (P0 mod m1 · pdiv_m1 + v) mod m1` and `cls_r = (root_r − pc) mod m1`
(`top_fd_kernel`/`top_kernel`; the CPU join's `run`: `c = (root + m1 − top.pc) mod m1`, the reference join's `bx =
key·m1 + (root + m1 − pc) mod m1`). `pdiv = b^p ≡ 1 (mod b − 1)`, so `c0 := P0 mod m1 · pdiv_m1 mod m1 = P0 mod m1`.
Define the prefix's **group** `g = key·m1 + c0` (`nb = nkeys·m1` groups, as many as buckets). Then, for every slot v,

  bucket `(key, cls)` of slot v = ⊔_r { kept tops of slot v from prefixes of group `key·m1 + (root_r − cls − v) mod m1` },

a disjoint union (the roots are distinct mod m1; at most 8 of them for every base 3–64, 2 at b60/b62, 4 at b58, 8 at
b64). Each kept top lands in exactly `nroots` buckets, one per root, as today. So the join needs no per-batch list of
top ids: it needs, per (slot, group), the kept tops' records contiguous.

## Data layout

- **Host, once per `JoinDevice::new` (slice, re-run, split):** a counting sort of the slice's top layer by group
  (stable, so P0 ascends within a group); `goff[g]` = prefix sums of the group sizes (`nb + 1` words, a new fixed
  table). The device `tlay` keeps 5 words per prefix: P0 lo, hi, **g**, **goff[g]**, P0 mod b^(k2−f0−p) (words 2 and 3
  were P0 mod m1 and the key, used only to form `pc`/`key`). The per-prefix mods move from u128 to u64 (P0 < 2^64 is
  already checked there), which pays for the sort.
- **`top_rec`**: unchanged size (`slots × ntlay` records); group g of slot s owns records
  `[s·ntlay + goff[g], s·ntlay + goff[g+1])`. A prefix gives at most one top per slot, so a segment cannot overflow.
- **`grp_cnt`** (was `bucket_cnt`, the same per-batch `nslots × nb` zeroed counters): kept tops per (slot, group).
- **Deleted:** `top_b`, `tl`, `work`, `cursor`, `top_count`, `top_scan_kernel`, `top_fill_kernel`; the top kernels'
  per-top `bucket_cnt` atomics (nroots per kept top) and `roots`/`pdiv_m1`/`key_level` arguments. `STAGES` 6 → 4.
  Nothing else reads them (the check reads `top_rec` by the record index the join stages, which keeps its meaning).

## Kernels

- **Append (both top kernels, one shared `#[cube] fn top_slot`):** the plane's kept tops of one group take one
  atomic: `g0` = lane 0's group; if every kept lane has `g == g0` (`plane_all`), lane 0 adds `plane_sum(kept)` to
  `grp_cnt[slot·nb + g0]` and each kept lane writes at `slot·ntlay + goff + at + plane_exclusive_sum`; otherwise each
  kept lane takes its own atomic on its own group (a plane straddling groups: ~31/740 of planes at b62 1e17; every
  plane at tiny test groups — correct, just slower). In `top_fd_kernel` it replaces the append block at the end of
  the slot loop (the stepped arithmetic above it is untouched, for L48); `top_kernel` (pow-2 bases, the clipped
  blocks) moves its record write out of its nested branches to the same uniform-flow append.
- **`join_kernel`:** work item w (no `work` array): `slot = w / nb`, `bx = w mod nb`, `dkey, cls` as today. Threads
  `r < nroots` put segment r's start `slot·ntlay + goff[g_r]` and count `grp_cnt[slot·nb + g_r]`, `g_r = dkey·m1 +
  (root_r + 2m1 − cls − v mod m1) mod m1`, into shared `s_sb[r]`, `s_sn[r]` (8 words each; barrier before and after).
  The bucket's tops are the segments' concatenation, `nt = Σ s_sn`; the batch load maps position `tc + u` to its
  segment (≤ nroots shared reads) and reads record `s_sb[r] + (tc + u − cum_r)`: consecutive threads read
  consecutive 32-byte records (coalesced) instead of gathering through `tl`. Batches still take 256 tops across
  segment boundaries, so the batch shapes (and the transposed-AND threshold) are as today. `v_part` (small test
  shapes) comes from `vs[slot]` (`v mod b^v_digits`, v_digits ≤ p) instead of the first top's record.
- **Launch:** top kernels → bucket → join → check (2 launches fewer per batch).
- **As built (changes found on the box):** `top_kernel` takes one plain atomic per kept top on its group's counter
  inside its branch (the plane-wide append held the record across the branches; either way the driver JIT gives it
  97–103 registers against the base's 80, see RESULTS); `nroots` is comptime in the join (the runtime segment loops
  were unrolled by ptxas and pushed the join to 60 registers or spills); thread 0 places the segments with a serial
  scan over ≤ 8 counts (no plane-size assumption; 3 barriers per work item, ~1 item per cube); the work item's list
  offset, entry base, entry count and key digit live in shared memory and are read per wave (registers).

## Plan footprint (`join_plan.rs`)

Per slot drops `top_b` (4 B/prefix), `tl` (4·nroots B/prefix), `work` (16·nb B), `cursor` (4·nb B); fixed adds
`goff` (4·(nb + 1) B); `scratch` (the counters) unchanged. `max_slice_prefixes`'s largest per-prefix buffer becomes
`top_rec`. A budget-limited plan may get more slots per launch or fewer slices: record both sides' slots/slices.

## Exactness argument

Same (entry, top) pairs per bucket: the bucket's top set is the union above, equal to today's (each top in the bucket
of each root) by the identity `c0 = P0 mod m1`; the order inside a bucket was atomic order and is now append order.
Every count (AND survivors, prefilter survivors, hits) is a function of the pair set. Records are written once per
kept top, at distinct indices within the top's own segment (atomic + exclusive prefix), so no record is lost or
overwritten.

## Test plan (CUDA box, then lavapipe)

1. `cubecl_cuda_top_fd_matches_the_top_kernel` adapted: per slot and group the same counts, per (slot, group) segment
   the same sorted records (both kernels append into the same segments; slot groups of 1 and several).
2. `cubecl_cuda_join_matches_the_cpu_reference` (incl. b50/b54, the b57 frontier), #235's certificate test, both
   dense fields, the whole-b42 field, `NICE_TEST_JOIN_COMPARE=1` at 1e14 for b57/60/62/64 (L38's counts), and the
   whole-field counts (b62 1e17 1,020,844,021,499 / 62,584,252,554; b62 1e16 163,513,599,082 / 10,027,698,695; b60
   1e16 460,847,952,346 / 30,871,838,404; b64 1e16 787,584,956,227 / 47,900,853,327).
3. Lavapipe: the `cubecl_join` wgpu tests (naga and direct SPIR-V), WGSL lint; fmt; clippy default,
   `nice_client/gpu`, gpu + cubecl-spirv.
4. Codegen: NVRTC→driver-JIT registers/spills of the join and top kernels (join ≤ 48, no spills; `ptxjit.py`).
5. A/B vs f3fb390 if time remains (interleaved, 3 rounds, clock per side).

Risks: (a) the sorted layer puts prefixes P0 ≡ g (mod b(b−1)) side by side in a plane, where today neighbouring P0
share their high digits; if `top_cert_fd`'s data-dependent loops diverge more, the FD kernel slows (measure the top
phase alone, `cubecl_cuda_top_fd_timing`). (b) b58-like tiny groups: per-lane atomics (correctness only).
(c) 15 storage bindings in the join (was 13): within every backend's per-stage limit (Metal 31).
