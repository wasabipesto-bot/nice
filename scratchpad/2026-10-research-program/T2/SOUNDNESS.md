# T2.4 soundness audit: can today's GPU overlap join lose a candidate unnoticed? (2026-11-13)

Scope: upstream main `a7a59c11`, and the three open fork branches `pr/check-d` (`bc9d87c7`, the fork's head; the
local branch `7d6956f8` is behind it), `pr/join-prefilter-shift-pow2` (`42d2afd9`) and `pr/join-survivor-stage-512`
(`0f6794a2`). Worktree `~/projects/nice/.worktrees/t2-soundness`. Line numbers are main's `common/src/cubecl_join.rs`
unless a file is named. Labels: **[read]** checked by reading, **[model]** a host model of mine (`T2/models/`),
**[host test]** a test that ran on ivory today, **[device test]** a test that needs a GPU (not run here),
**[assumed]** stated without a check.

## Summary

**No path that loses a candidate in production today was found.** The stop-and-hand-back condition did not trigger.

Gaps, by severity:

1. **Medium (production, by design): a device that runs every cube but computes wrongly is not detected.**
   `ensure_ran` (3778) only sees cubes that did not finish. A miscompiled or misbehaving kernel that over-rejects
   (the #222 race and the M4 division miscompile were both of this kind) gives a normal-looking submission with
   fewer survivors. No production path compares any kernel output with a known answer, and the CI parity tests run
   only on lavapipe and the macOS paravirtual Metal device, never on CUDA (the NVIDIA fleet) and never on RDNA4.
   Smallest scenario: any device-specific miscompile of one of the join's fixed digit tests (for example the
   prefilter's `mul_hi` or a 64-bit shift in `walk_pf_lean`, 3016-3053) on a fleet device. Every rejection becomes a
   lost candidate, and nothing in the client notices. The join's two counts, `survivors` and `checked`, are exact
   functions of (field, parameters), the same on every device and layout (3906-3916, and the tests rely on it).
   That makes a cheap check possible: run one fixed partition of a fixed field per base at client start and
   compare both counts with the CPU's. The server could also spot-check them. NiceMark already runs fixed join
   scenarios on each box it benchmarks and records `survivors` and `checked` (`client/src/bench.rs` 137-138,
   973-974), but compares them with nothing: pinning the CPU's counts per scenario would make it a known-answer
   check on every device that runs it.
2. **Medium (`pr/check-d` only, not in production): the new check kernel's work counter assumes full planes.**
   Lane 0 takes `PLANE_DIM` entries and lane i checks entry `cur + i` (check-d 3312-3322). A plane with fewer active
   lanes than `PLANE_DIM` skips the missing lanes' entries. Nothing records this: the counter's end value is the
   same, so the PR's own end-value assertion cannot see it. **[model]** `plane_models.py`: full planes check all
   100,000 entries once. 31 active of 32 lanes skips 3,125, and 32 of 64 skips 49,984. Planes are full on CUDA and
   Apple with 256-thread cubes. On Vulkan the API does not promise it: wgpu-hal 29/30 never sets the
   require-full-subgroups flag **[read]**, and drivers launch full subgroups for 256-wide groups **[assumed]**.
   Smallest fix, either one:
   - index by `plane_exclusive_sum(1)` and take `plane_sum(1)`;
   - or count the entries actually checked (one atomic per plane-round) and have the host compare that count with
     `min(checked, list_cap)`. This would also give main's grid-stride check (3122-3165) the end-to-end
     "every listed survivor was checked" signal it lacks now.
3. **Low (theoretical): the overflow detector is a 32-bit counter.** `surv_count` (the batch's `checked`) is a
   wrapping u32 (970, 3076). `overflowed` is `checked > list_cap` (3792). A batch with 2^32 or more prefilter
   survivors therefore reads as not overflowed, and everything past `list_cap` is dropped unchecked. Smallest
   scenario: with the largest layouts the planner gives (`index_bounds.out`, worst case: every top-layer prefix
   certified), a wrap needs at least 64 prefilter survivors per (top, partition) in one batch. Measured densities
   are 0.5-2.1 (`join_plan.rs` 70-93), and the most possible is `b^3` ≈ 2.6e5. Not reachable on any field measured,
   but it is a bound that is only "never reached in practice". Fix: saturate the count, or set a flag when
   `g >= cap`. The telemetry `survivors` count (`and_count`) is also a u32 per batch and could wrap the same way.
   That would mislead the submission audit, not the search.
4. **Low (liveness, loud): the top-stage grid can reach 65,536 cubes in x, one more than wgpu's usual limit.** This
   happens only if every prefix of a 2^24-prefix slice is certified, at 4 GiB wgpu budgets (`index_bounds.out`).
   Real slices certify a third to a half of them. A launch past the limit fails loudly (a wgpu validation error, or
   `ensure_ran` then `refit`, then an error), never as an empty result.
5. **Note (production, depends on a device property): `top_slot`'s ballot form needs planes of at most 32 lanes,
   and is chosen from the runtime's reported `plane_size_max` (135-137, 3421).** **[model]**: the ballot form on
   planes of 4-32 and the scan form on 4-128 have no violations. A 64-lane plane misreported as 32 gives 134,493
   slot violations in 2,000 trials, which means overwritten tops and so lost candidates. The report is right where
   checked **[read]**:
   - CUDA: 32.
   - cubecl-wgpu 0.10 on Apple silicon: hard-coded 32.
   - Other wgpu adapters: the adapter's `subgroup_max_size`, with 0/0 mapped to 128.

   RADV would report 64 for RDNA, so the fleet's 9070 XT takes the scan form **[assumed]**. Since the ballot form
   landed, CI runs only the ballot form: lavapipe has 8-lane planes and the Metal VM 32. The scan form, which RDNA
   and HIP wave64 run, has no CI coverage. `check_top_fd` could run both forms by toggling `dev.ballot`.

What "none found" rests on:

- A full read of the kernels and host driver against the five headings below.
- Three models:
  - the stage/flush protocol: reproduces the #222 class on the pre-#222 protocol and finds nothing on main's, over
    900 random interleavings;
  - the plane-size appends;
  - a big-integer mirror of the per-pair digit chain at the production shape, for every base 40-64. It shows 0
    mismatches, and 404-4,646 when mutated.
- Two audit tests of mine, run as host tests:
  - a bounds table of every u32 index product at the largest plannable layouts;
  - a brute check that the top layer's prune keeps the ancestor of every certified top on seven production-shaped
    fields.
- The existing host tests (all pass) and the brute-force certificate test on 240 real production tops (b58-64,
  13.7M locally viable n; this is an ignored test).

The kernels themselves (as opposed to their arithmetic) could not be run here; see the last section.

## 1. Bounded buffers and counters

| Item | Invariant | Enforced | Test | Verdict |
|---|---|---|---|---|
| Top records (`top_rec`, `grp_cnt`) | A slot's kept tops of group g fit `[goff[g], goff[g+1])` | Each prefix is appended at most once per slot. FD and `only_clipped` take disjoint blocks: both test `a_lt_s \|\| e_gt_e` the same way (1896, 2762/2830), and `clip_vs` matches it (3422-3431). | `check_top_fd` checks the sentinel and segment bounds [device test] | Sound by construction |
| Bucket lists, counts | Entry i is listed at most once per key; `at < clen` | `s_cnt[dk]` per key, one entry per thread per key (367-394) | `check_window` counts vs CPU [device test] | Sound by construction |
| Shared stage (1024; 512 on stage-512) | Every prefilter pass reaches the list exactly once | `at < SURV_SH_CAP` goes to the stage, else directly to the list (966-975). The flush clamps n to the stage (3072) and resets after a barrier. | `stage_model.py` [model]: 0/900 runs bad on main and stage-512 sizes; the pre-#222 protocol fails 36/900 | Sound by construction, modelled |
| Global survivor list | `checked` counts every pass; an overflow is seen | `g < cap` writes, and every pass counts (971, 3076-3083). `overflowed` (3792). | `check_tight_layouts`, `check_production_shape` [device test] | Sound, **except the u32 wrap (gap 3)** |
| Check input | The check reads `min(count, cap)` entries | 3122-3125 | [device test] | Sound |
| Hit list (`nice_cap` 1024 per device) | More hits error out; they are never truncated | `read_hits` ensure (3808-3814) | — | Sound (loud) |
| Transposed copy `t_tr` (8×64 words) | Chunk-major, chunks past `nt` are zero | 674-701, `cb ∈ {0,4}`, `c < 4` | `check_window` (≥192 tops) [device test] | Sound by construction |
| Re-run list | One top of one partition (≤ `b^f0` ≤ 2^18 pairs) fits | `MIN_RETRY_CAP` = 2^18 (`join_plan.rs` 54). Splits stop at `MAX_SPLITS`, or `tlay.len() < 2`, as an error (4329-4338). | `check_tight_layouts` [device test] | Sound; a failing re-run errors |
| u32 index products | All < 2^32 | Planner bounds (`join_plan.rs` 330-401). Worst values: `8·slots·ntl` 5.4e8, `slots·b·nbp` 4.6e7, `2·list` 2.7e8. | `audit_index_bounds.patch` → `index_bounds.out` [host test] | Sound, now tested |
| Top-stage grid x | ≤ the device's dispatch limit | — | `index_bounds.out` | Gap 4 (loud) |
| `and_count` (telemetry `survivors`) | Exact per batch | u32 atomic (1043-1046) | — | Telemetry only; can wrap like gap 3 |
| check-d work counter | Every entry taken once | Full planes (check-d 3312-3322) | `plane_models.py` [model] | **Gap 2** (PR) |

## 2. Concurrent accesses

| Kernel / array | Writes → readers, separating barrier | Verdict |
|---|---|---|
| `join_kernel` `s_cum`, `s_db`, `s_hd` | Threads < nroots write and thread 0 writes after 593, then barrier 608. Thread 0 prefix-sums, then barrier 618. Read in the batch and wave loops. The next item's writes wait for barrier 593. | Sound |
| `t_lo/t_hi/t_rlo/t_rhi/t_id/t_dm/t_glo/t_ghi` | Written in the batch load, barrier 673, read in transpose/AND/walk. Rewritten only after barrier 1024. | Sound |
| `t_tr` | Written after 673, barrier 702, then read | Sound |
| `s_cw` | `fetch_or` in the load, read after 673. Cleared at 1020, after barriers 1004/1006 (past the last read). Barrier 1024 comes before the next load. | Sound |
| `s_cnt` / `s_t` / `s_r` (stage) | Appends are atomic. Barrier 1004, every thread reads sc, barrier 1006, then a uniform decision. Flush: thread 0 reserves, barrier, copy, barrier, reset; barrier 1018. Final flush: barrier 1028, read; nothing appends after it, and the reset follows the flush's barrier. | Sound **[model]** (the #222 site) |
| Walk loop | `plane_any` keeps the loop plane-uniform. `sync_plane` (CUDA) sits outside the per-lane `if`. | Sound |
| `bucket_kernel` `s_cnt[64]` | Initialised, barrier 247, atomics, barrier 403, then counts written | Sound |
| `top_slot` (plane ops) | Every lane calls it (`live` lanes and dead lanes alike, 2666-2678, 2909). `g0` and `one` are plane-uniform. | Sound **[model]**; ballot depends on gap 5 |
| `top_kernel`, `top_fd_kernel` | No shared memory; one atomic per top or plane | Sound |
| `check_kernel` (main) | Per-thread scratch rows of `sv_s` (`svb`), no sharing | Sound |
| `check_kernel` (check-d) | Counter in `ran[4]`; `cur`/`nxt` broadcast; loop uniform | Sound only with full planes (gap 2) |
| Between kernels/batches | One queue: CUDA stream order; WebGPU dispatch scopes. Batches share every scratch buffer, and the next batch's top stage overwrites `top_rec` only after the previous check has run. | Sound by API order **[assumed for wgpu backends]** |

## 3. Filters that reject

| Filter | Exact? Proof / test | First input to break it | Verdict |
|---|---|---|---|
| Field certificate prune (`prune_bottoms`, bucket kernel 299-312, 380) | Digits at positions ≥ k certified for every nice n of the slice; a bottom's are < k. Tests: `the_field_prune_drops_exactly...` (CPU), `certificates_hold_for_every_distinct_digit_n...` (random, b ≤ 40), `cert_is_sound_on_real_tops`. | None: soundness needs only cert soundness | Sound, tested [host test] |
| Top layer at depth t−p (`overlap_join.rs` 905-928) | A dropped prefix has no certified child. `top_layer_keeps_every_viable_prefix` covers b ≤ 23. **New:** on seven production-shaped fields at b57-64, 1,400 dropped prefixes (5.3e6 children) have no certified child, and each of the 139,361 certified tops among 1.4e6 sampled has its prefix kept. | — | Sound, tested here [host test] (`top_layer_prune.out`) |
| Top certificates (`cert_power` 1210, `close_cert` 1670, FD `cert_power_fd` 2447) | Common digits come from monotonicity. The d/d+1 disagreement digit is closed as in `close_certificate`. Positions are ≥ c0 ≥ cap = k (cap = `self.k`, 3570/3600). The carry test is exact (sum < 2^(32·nl) argued at 1326-1328; FD by borrow). | e ≥ b^sp (impossible inside a constant-length field) | CPU form sound and tested (240 real tops brute-forced today). Device = CPU only by [device test]. |
| Prefilter seed (`floor >= k2`; unclipped blocks use `full_floor`) | `full_floor` is the floor of the first full block, a lower bound: `(a+w−1)^j − a^j` increases with a (`overlap_join.rs` 1174-1179). Clipped blocks use their exact c0s (1928-1936). The FD kernel has the same rule (2681-2684). | — | Sound by construction |
| Residue classes, groups, key | n ≡ P0·b^p + v + r0 (mod b−1); group `g = key·(b−1) + P0·b^p mod (b−1)`; bucket class = r0 mod (b−1) (595-598). | — | Sound; `sorted_layer_and_segments_match_the_cpu_buckets` [host test] |
| AND (transposed and direct) | Disjointness of the entry's positions 0..k−1 and the cert's positions ≥ k. Empty slots are masked by `vv`. | — | Sound; [device test] |
| Range clip | Only blocks P = plo, phi are clipped; their out-of-range bits are cleared (898-914). `rlo`/`rhi` are exact u32 differences (1946-1947). | — | Sound; `check_slices`, windows [device test] |
| Key-level digit chain + lean prefilter (743-805, 3016-3053) | Δ < 2b⁴ ≤ 2^25 < 2^32 (proof in the doc; `fx_digits_match_the_division` [host test]). Packing: q < M ≤ 2^18, c3 split 14/4 bits (336-337, 756). `JoinDevice::new` ensures M ≤ 2^18 (3327-3332). | b > 64, or mid ≠ 2: refused | Sound. **New:** `prefilter_chain.py` [model] mirrors bucket→join→lean on the 20 bases 40-64 that have a band (42,712 n, low digits biased to runs of 0 and b−1): 0 mismatches against big-integer digits; three single-point mutations give 404-4,646. |
| shift-pow2 (42d2afd9) | At b = 2^s, `F>>(32−s)` and `(F<<s)>>(32−s)` equal the `mul_hi` digits for every F | — | Sound by construction; `fx_digits_are_bit_fields_at_powers_of_two` [host test] |
| Full check (main: `candidate_check`) | The stride pipeline's own check | — | Out of scope; long in production |
| Full check (check-d) | Columns < `nl·(b⁴+b²)` < 2^31; magic quotients exact below 2^31; H by an exact inverse. n is rebuilt from `w6` (now load-bearing: `w6 = P mod b^5`, 1948 and 2918, correct). Hit iff gate and `uniq == b` (s2 + s3 = b at comptime). | — | Sound by construction; mirror tests [host test]; the kernel = mirror only by [device test] |

## 4. Device and runtime failures that could look like an empty result

| Failure | What catches it | Verdict |
|---|---|---|
| A dispatch dropped or partly run (cubes missing) | Per-kernel cube counters against the launch (3646-3658, 3778). Each batch has its own `ran`. | Caught → `refit` (4152) at half the layout; a device that runs nothing errors (test `check_refused_layouts`). |
| A kernel that fails to compile or to validate | cubecl-wgpu returns compile errors; the uncaptured validation errors of wgpu are fatal by default **[assumed]**; otherwise the cube counters fall short. | Loud |
| Lost device, read failure, fence failure | `?` on every read and fence (3796-3802, 4233, 4252) → field error → client `exit(1)` (`client/src/main.rs` 958-962, 986-991); nothing is submitted. | Loud |
| Read-back of the wrong size | `from_bytes(..)[0]` panics on empty; `ensure_ran` compares slices of unequal length as unequal. | Loud |
| Allocation failure | CubeCL panics or errors **[assumed]** | Loud |
| Kernel runs every cube but computes wrongly (miscompile, driver bug, broken barrier) | **Nothing** | **Gap 1** |
| Work counter on partial planes (check-d) | Nothing | Gap 2 |
| Overflow past 2^32 | Nothing | Gap 3 |

## 5. Host bookkeeping

| Item | Invariant | Where | Test | Verdict |
|---|---|---|---|---|
| Slices | Contiguous, cover `[s, e)` | `join_slices` (`overlap_join.rs` 340-350); each slice gets its own setup, certificate and `full_floor` (`sub_range`) | `slices_cover_the_field...` [host test], `check_slices` [device test] | Sound |
| Partitions | Every v in `0..b^p` runs in every slice; an empty top layer means no candidates | `run_field` 3948; `run_slice` 4091-4097 | — | Sound |
| Batches | `parts.chunks(slots)` covers all. Overflowed batches re-run at half size, and single partitions split their top layer. Batches that did not run go again in a refit layout with what overflowed. | 4101-4145, 4229-4271 | `check_tight_layouts`, `check_production_shape` [device test] | Sound |
| Re-run stats | A partition re-run after a refusal restores its counts and keeps (dedups) hits found | 4185-4192, 4057-4058 | — | Sound |
| Hits → submission | Read after every batch completed; deduped; any error → exit(1); results are ticketed in order (`redeem`, `gpu_route.rs`) and joined into the claim's submission (`main.rs` 1096-1100) | 4109, 4131, 4142, 4325 | `cubecl_niceonly_keeps_join_and_stride_apart_by_ticket` [device test] | Sound |

## What I could not check without a device

- That each kernel computes what its host model computes, on each runtime. The fleet runs CUDA (RTX), RDNA4
  through RADV and the direct SPIR-V compiler, and Apple M4. CI runs the parity suite on lavapipe (wgpu and SPIR-V)
  and the macOS paravirtual Metal device only. CUDA parity rests on manual `cubecl_cuda_*` runs.
- The top certificate on the device (`cert_power`, the FD state and its carried c0/dm). The B64 review mirrored
  them on the host; the comparison with the CPU is a [device test].
- The scan form of `top_slot`, which RDNA wave64 and HIP CDNA run: no CI device takes it now.
- Whether a fleet device ever launches partial planes (gap 2) or misreports its plane width (gap 5).
- check-d's `check_counts` and probe comparisons, and the work counter's end value.
- The 64-bit integer code each backend generates (WGSL u64 through naga, SPIR-V Int64, CUDA): the masks' shifts by
  32-63 and the reversed-mask sign test, on any device but lavapipe and the Metal VM.

## Artifacts (`T2/models/`)

- `stage_model.py`: the stage/flush protocol model. Main's protocol, at stage sizes 1024, 512 and 8: 0/900 runs
  bad. The pre-#222 protocol: 36/900 runs lose or stale-write.
- `plane_models.py`: the `top_slot` append and the check-d work counter.
- `prefilter_chain.py`: the per-pair digit chain at the production shape, b40-64.
- `audit_index_bounds.patch` and `index_bounds.out`: the u32 bounds table (an ignored test in `join_plan.rs`).
- `audit_top_layer.patch` and `top_layer_prune.out`: the top-layer prune check (an ignored test in
  `overlap_join.rs`).
- `cert_real_tops_60.out`: `cert_is_sound_on_real_tops` with 60 tops per field.
- `cpu_join_production_ref.out`: `cpu_join_matches_the_reference_on_production_fields` (an opt-in test), 4
  partitions each of the b42-64 production fields: passes.
- `stage_model.out`, `plane_models.out`, `prefilter_chain.out`: the three models' outputs.
- Host tests run today: on main, `cubecl_join::`, `overlap_join::`, `join_plan::`, `cpu_join::`, `cpu_check::` and
  `cpu_top_fd::` (all pass); on check-d, `join_check::` and `cubecl_join::`; on shift-pow2 and stage-512,
  `cubecl_join::` (all pass).

Nothing in the repository was changed. The audit patches live only in the worktree's stash and in the files above.
