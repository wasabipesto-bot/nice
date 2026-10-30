# Overlap join: size the bottom buffers by the pruned lists and run more partitions per launch

## What and why

At production size (1e14 fields) much of a field's GPU time is fixed per field: it does not grow with the field's top layer. On an RTX 3080 that is about 40–74 % of a 1e14 field at bases 58–64: the join kernel's floor per (partition, bucket) work item, the bucket kernel, and the launches. Each launched batch costs about 0.5 ms of fixed work on that card, however many partitions it holds. At 16 partitions per launch a 1e14 field is 211–256 batches, so the launches alone are 15–21 % of the field.

16 was the cap from when every slot's bottom side was sized by the full bottom list and 16 partitions took 0.3–0.9 GiB of a 1 GiB budget. Since #215 the kernels work on the bottom list pruned by the field's certificate (`FieldSetup::bp_r`). But `Footprint` kept sizing each slot's bottom-side buffers (`ext_m`, `ext_pk` and the bucket lists, most of a slot) by the unpruned list (`bp_all`), on purpose, so that #215 changed no layout. The pruned list is 37–48 % as long on a 1e14 field at bases 57–64. With #206's budget (2.5 GiB on a 10 GB card, 4 GiB from 16 GB) that leaves room for far more than 16 partitions per launch.

This PR:
- **Sizes the bottom-side buffers by the slice's own pruned list.** `Footprint::of` counts `fs.bp_r`, which is what the kernels index (`JoinDevice::nbp`). Every slice already gets its own plan: the first slice's plan is computed from the first slice's setup, and `run_slices` plans each later slice again with `JoinPlan::for_field`. `JoinDevice::new` allocates from that plan, so each slice's buffers hold the list its kernels index. Slices are still cut by the unpruned length (`max_slice_prefixes`), before any slice is built. That length bounds every slice's list, since a slice's list is the unpruned one filtered by the slice's certificate.
- **Raises the cap from 16 to 64 partitions per launch,** and never plans more than the field's partitions. 64 is the measured optimum on the RTX 3080 (sweep below). Taking as many as the budget holds (105–111 on a 10 GB card, 171–177 at 4 GiB) was 1–4 % slower than 64.
- **Adds `NICE_TEST_JOIN_MAX_BUFFER` (bytes), test builds only.** It stands in for the device's largest buffer when the join's tests and harnesses plan fields, so a larger card can run a smaller card's layouts. 2684354560 is a 10 GB card on CUDA, where CubeCL reports a quarter of the device.

## Soundness: what does not change

- The kernels, the AND, the prefilter, the full check and the reference `join_range` are untouched. The kernels already indexed each slot's bottom side by the pruned length; only the allocations shrink to it.
- These are unchanged: the survivor list's length, the expected-survivor bound on partitions per launch (`SURV_PER_PREFIX`), the overflow re-runs, the device ceiling, and how fields are cut into slices. At 1e16 the expected-survivor bound sets partitions per launch (4–13 on a 10 GB card), not memory or the cap. So 1e16 layouts are main's, except that the plans are smaller.
- A launch of more partitions does the same work per partition. One thing changes above 16–19 partitions per launch at bases 58–64 (65,535 cubes ÷ b(b−1) work items per partition): each join-kernel cube grid-strides over several (partition, bucket) work items. Its survivor stage then carries survivors from one work item into the next. That has two effects:
  - A few more survivors overrun the stage and reach the full check without the prefilter. This costs only those full checks: about 36 k per 20 fields at b64, 5e-7 of the survivors.
  - The stage's per-chunk flush now runs mid-cube, which exposes a race in the flush decision (below).

## Measured

RTX 3080 **20 GB**, power limit 320 W (= default = max, not capped by the host). Under load it ran at 1845–1950 MHz and 308–318 W, at the power cap. Field timings come from `cubecl_cuda_join_throughput_fixed_fields`, after a 1e14 warm-up per base, two fields in flight. Main is `d1ff798` plus this PR's harness commit. Interleaved main / PR rounds; medians, with the spread (max − min over median) in parentheses. Starts: b58 104400216587923470200, b60 1366406074057412100454, b62 7997740455941656911841, b64 41242006262957161709568.

Most cards have 10 GB, so the primary numbers plan as a 10 GB card does (`NICE_TEST_JOIN_MAX_BUFFER=2684354560`: 2.5 GiB budget, 640 MiB list). This card's own budget (4 GiB, 1 GiB list) is alongside. The override changes only the join's planning, not CubeCL's memory pools.

**1e14 fields** (production size; 20 consecutive fields per base, 3 rounds), seconds per field:

| base | 10 GB budget: main | this PR | **×** | 20 GB budget: main | this PR | **×** |
|---|---|---|---|---|---|---|
| 58 | 0.705 (4.8 %) | 0.621 (0.8 %) | **×0.881** | 0.700 (1.9 %) | 0.629 (0.2 %) | **×0.899** |
| 60 | 0.597 (1.2 %) | 0.518 (1.2 %) | **×0.868** | 0.597 (1.5 %) | 0.518 (0.8 %) | **×0.868** |
| 62 | 0.579 (2.2 %) | 0.459 (0.4 %) | **×0.793** | 0.581 (1.9 %) | 0.457 (1.5 %) | **×0.787** |
| 64 | 0.686 (0.9 %) | 0.571 (1.9 %) | **×0.832** | 0.688 (0.4 %) | 0.568 (1.8 %) | **×0.826** |

**Layouts at 1e14**, as partitions per launch / batches per field / plan MiB (the largest of the 20 fields):

| base | 10 GB: main | this PR | 20 GB: main | this PR |
|---|---|---|---|---|
| 58 | 16 / 211 / 1234 | 64 / 53 / 2049 | 16 / 211 / 1618 | 64 / 53 / 2433 |
| 60 | 16 / 214 / 1226 | 64 / 54 / 2536 | 16 / 214 / 1610 | 64 / 54 / 3153 |
| 62 | 16 / 241 / 1381 | 64 / 61 / 2176 | 16 / 241 / 1765 | 64 / 61 / 2560 |
| 64 | 16 / 256 / 1426 | 64 / 64 / 2236 | 16 / 256 / 1810 | 64 / 64 / 2620 |

The whole process's GPU memory (`nvidia-smi` peak, including the stride pipeline and CubeCL's pools) went from 6945 to 7137 MiB under the 10 GB budget, and from 8225 to 8385 MiB under 20 GB. These runs used the 20 GB card's pool pages, so the first pair is not what a 10 GB card would show.

**The cap: partitions per launch swept** (1e14, 20 fields per base, 4 GiB budget, 2 rounds; the same binary with a cap override; no barrier, see below). Seconds per field:

| per launch | b58 | b60 | b62 | b64 |
|---|---|---|---|---|
| 16 | 0.704 | 0.607 | 0.574 | 0.687 |
| 32 | 0.645 | 0.536 | 0.481 | 0.597 |
| **64** | **0.626** | **0.518** | **0.460** | **0.575** |
| 96 | 0.631 | 0.524 | 0.466 | 0.579 |
| 128 | 0.627 | 0.530 | 0.474 | 0.584 |
| as many as fit (171–177) | 0.639 | 0.530 | 0.478 | 0.583 |

64 is the fastest at every base. I have not profiled why more is slower. The extra overruns are far too few to account for it. The A/B of the uncapped version (105–111 per launch at the 10 GB budget, 171–177 at 20 GB) gave ×0.895 / 0.876 / 0.801 / 0.842 and ×0.903 / 0.886 / 0.829 / 0.849, against the cap's ×0.881 / 0.868 / 0.793 / 0.832 and ×0.899 / 0.868 / 0.787 / 0.826.

**1e16 fields** (2 consecutive fields per base; 3 rounds at the 10 GB budget, 2 at 20 GB), seconds per field:

| base | 10 GB budget: main | this PR | **×** | 20 GB budget: main | this PR | **×** |
|---|---|---|---|---|---|---|
| 58 | 46.80 (0.9 %) | 46.73 (1.7 %) | **×0.999** | 47.21 (0.6 %) | 46.62 (0.1 %) | **×0.988** |
| 60 | 34.70 (1.8 %) | 35.09 (1.1 %) | **×1.011** | 34.84 (1.1 %) | 34.92 (1.4 %) | **×1.002** |
| 62 | 15.72 (1.3 %) | 15.76 (1.6 %) | **×1.003** | 15.49 (0.0 %) | 15.49 (0.2 %) | **×1.000** |
| 64 | 43.24 (2.7 %) | 42.91 (2.0 %) | **×0.992** | 42.87 (3.0 %) | 43.21 (0.7 %) | **×1.008** |

At 1e16 the expected survivors bound the partitions per launch. On both trees they are 5 / 4 / 13 / 6 (10 GB budget) and 5 / 6 / 16 / 10 (20 GB), except b62 at 20 GB, where main's cap of 16 bound one field and this PR takes 22 (334 → 302 batches). The plans shrink: 1877 → 1823, 1596 → 1561, 2064 → 1843 and 2169 → 2036 MiB at the 10 GB budget. At the 20 GB budget the process's peak GPU memory rose from 9473 to 10881 MiB, with plans of at most 3.5 GiB on both trees. That is CubeCL's pool keeping pages for the slightly different buffer sizes, not the join's plan.

**NiceMark nice-only** (`nice_client niceonly --gpu --benchmark --benchmark-secs 150`, 3 interleaved rounds, this card's own budget; every scenario took the join on both trees), median rate with spread:

| scenario | main | this PR | **×** | per launch |
|---|---|---|---|---|
| b58_msd_weak (1e15) | 2.044e14 (2.6 %) | 1.982e14 (2.1 %) | **×0.969** | 16 → 50 |
| b58_msd_strong (1e15) | 1.219e15 (5.1 %) | 1.275e15 (1.6 %) | **×1.046** | 16 → 64 |
| b60_msd_weak (1e16 sample) | 4.048e14 (1.1 %) | 3.975e14 (0.7 %) | **×0.982** | 6 → 6 |
| b62_msd_weak (1e16 sample) | 5.124e14 (1.0 %) | 5.214e14 (1.9 %) | **×1.018** | 9 → 9 |
| **score** | 4688 | 4698 | **×1.002** | |

NiceMark's scenarios are 1–9 s samples. The b60 scenario moves by 1.8 % with the same layout and the same counters, so ±2–3 % per scenario is noise here. b58_msd_weak is a 1e15 field, so the same comparison ran in the harness on 1e15 fields (2 per base, the same ranges as the 1e14 runs, 3 rounds):

| base | 10 GB budget: main | this PR | **×** | per launch | 20 GB budget: main | this PR | **×** | per launch |
|---|---|---|---|---|---|---|---|---|
| 58 | 5.071 (2.6 %) | 5.163 (2.3 %) | **×1.018** | 16 → 32 | 5.177 (0.6 %) | 5.240 (0.5 %) | **×1.012** | 16 → 51 |
| 60 | 3.432 (0.8 %) | 3.438 (1.3 %) | **×1.002** | 16 → 43 | 3.448 (1.9 %) | 3.441 (1.8 %) | **×0.998** | 16 → 64 |
| 62 | 2.503 (1.8 %) | 2.468 (0.1 %) | **×0.986** | 16 → 50 | 2.519 (1.7 %) | 2.480 (1.8 %) | **×0.985** | 16 → 64 |
| 64 | 3.733 (1.0 %) | 3.643 (2.3 %) | **×0.976** | 16 → 48 | 3.639 (4.3 %) | 3.659 (3.5 %) | **×1.005** | 16 → 64 |

At 1e15 the change is neutral, with b58 1–2 % slower. A 1e15 work item is about 10× heavier, so launches are only about 2 % of a b58 field. The likely cost on the other side, not profiled, is grid-striding cubes (above 19 per launch at b58) carrying heavier, uneven work items. It cancels what the fewer launches save.

**Counters.** At 1e14, main counts the same join survivors and full checks to the last digit in every run (b64: 65,747,036,999 survivors and 3,999,993,450 full checks per 20 fields). This PR differs from main only by the stage overrun of grid-striding cubes, where Δchecked ≈ −0.94 Δsurvivors (the overrun path skips the prefilter):

| base | survivors − main | full checks − main |
|---|---|---|
| 58 | −44 … −93 | +42 … +86 |
| 60 | −1,988 | +1,836 … +1,867 |
| 62 | 0 | 0 |
| 64 | −35,319 … −36,368 | +33,088 … +34,054 |

That holds in all 6 PR runs above. No field holds a nice number (found = 0 on both trees).

## Exactness

On the final code (the timed binary plus test prints and doc wording), on the RTX 3080:
- **Host tests:** `nice_common` with `--features gpu`, 209 passed. The new `join_plan::tests::bottom_buffers_follow_each_slices_pruned_list` checks three things:
  - On a b58 1e15 field cut into 4 slices, every slice's pruned list is no longer than the unpruned length the slices are cut by. Slices whose certificate holds prune; one whose certificate fails has no tops and prunes nothing.
  - Its `Footprint` sizes `ext_m`, `ext_pk` and the bucket lists by exactly that list, and its plan takes every partition per launch that fits.
  - At the 10 GB budget, every 1e14 `PLAN_FIELDS` field at b57–64 gets 64 per launch in 1750 / 1752 / 1831 / 2114 MiB. The unpruned sizing would fit 54 / 55 / 41 / 39, with 54,885 / 66,634 / 65,394 / 78,784 of 133,645 / 137,775 / 176,671 / 180,003 bottoms kept.

  `production_fields_get_the_full_layout` and `small_devices_get_smaller_layouts_or_none` now assert "as many as fit" instead of exactly 16.
- **CUDA parity:**
  - `cubecl_cuda_join_matches_the_cpu_reference` passes: every window, tight layouts with re-runs and splits, slices, refused layouts, and the production shape.
  - `cubecl_cuda_join_matches_the_reference_on_a_whole_field` (b42) passes.
- **Dense fields against the CPU join** (`cubecl_cuda_join_matches_the_cpu_join_on_a_dense_field`, with `NICE_TEST_JOIN_DENSE_FIELD`):
  - b58 1e15, 64 partitions: passes, 0 survivors overran the stage.
  - b64 1e16, 8 partitions: passes, 2.7e-5 overran.
  - b64 1e14, 1024 partitions at 64 per launch: passes, 5.7e-6 overran.
- **Join against stride:** `NICE_TEST_JOIN_COMPARE=1`, 5 fields of 1e14 per base at the A/B starts, under the 10 GB budget: the join and the stride pipeline agree at b58–64. These fields hold no nice numbers, so this check is weak on its own.
- **Counters:** see "Measured". Survivors and full checks equal main's to within the stage overrun in every A/B run at 1e14 and 1e16. No hits on either tree.
- **With the flush-decision barrier** (below) on top of this PR: `cubecl_cuda_join_matches_the_cpu_reference` and the b58 1e15 and b64 1e14 dense-field tests pass as well.
- **Lint:** `cargo fmt --all --check`, and `cargo clippy -p nice_common -p nice_client --all-targets -- -D warnings` with default features and with `--features nice_client/gpu`: clean.

## The extra full checks at 64 partitions per launch and more

Some runs at 64 or more partitions per launch count far more full checks than the stage overrun explains, while the join survivors still agree to within it. The excess was 0.4 M–77 M per 20 fields (0.01–2.1 % of the full checks), at b58 and b64. Without a fix, 10 of 98 base-runs at ≥ 64 per launch did this; at exactly 64, this PR's cap, 3 of 47 did, none of them among the 24 in the A/B tables above. None of the 76 base-runs at 16 or 32 per launch did (48 of them main's). **The cause is a race in `join_kernel`'s flush decision, not the stage overrun.**

After each chunk of 32 tops, the cube waits at `sync_cube()`, every thread loads the stage count `s_cnt`, and the cube flushes if the count has reached `SURV_FLUSH`. Nothing orders one plane's load against another plane's appends for the next chunk. A fast plane can read the count, run the next chunk's AND and walk, and append survivors before a slow plane has done its load. The slow plane then reads a larger count. If that count crosses 512 when the count at the barrier did not, the slow plane enters `flush_survivors` alone.

From then on, the cube's barriers pair up at different call sites for the rest of the cube. Inside the flush, each round does two things wrong:
- It sums plane totals that the other planes did not write for that round. The list count then covers entries nobody wrote in this batch: stale entries of earlier batches, which the full check reads. Those are the extra checks.
- The lone plane writes its passing survivors at a list offset (`s_base`) that thread 0 did not reserve for it. That can overwrite entries another flush did reserve, so in such a cube some prefilter survivors may never be fully checked.

The fields measured here hold no nice numbers, so these runs cannot show a missed one.

**Evidence** (an instrumented build of this PR):
- **A planes-per-flush counter.** Each plane's lane 0 counts its entries into `flush_survivors`, against 8 for every flush thread 0 enters. The two differed in 9 of the 50 instrumented base-runs at ≥ 64 per launch.
- **One more `sync_cube()` between the load and the next chunk** (so every thread has read the count before any thread appends): no mismatch and no extra checks in any of 18 base-runs at ≥ 64 per launch. Without it, 12 of the 50 instrumented base-runs showed one or the other. If the barrier changed nothing, 0 of 18 would happen by chance with probability ≈ 0.7 %.
- **At b64 1e14, 20 fields, 3 runs each** (full checks beyond the overrun; planes mismatch):

| per launch | without the barrier | with it |
|---|---|---|
| 16 | 0, 0, 0; 0, 0, 0 | 0, 0, 0; 0, 0, 0 |
| 32 | 0, 0, 0; 0, 0, 0 | 0, 0, 0; 0, 0, 0 |
| 64 | 0, 0, **+12.1 M**; 1, 2, 0 | 0, 0, 0; 0, 0, 0 |
| 171 | 0, **+2.0 M**, 0; 2, 7, 0 | 0, 0, 0; 0, 0, 0 |

**Why more partitions per launch make it frequent.** Up to 16–19 partitions per launch at bases 58–64, the join grid has one cube per work item, and the stage starts empty in every cube. A 1e14 work item has 7–27 tops on average (one chunk, or a few) and 80–300 survivors, so the stage rarely nears 512 at a chunk boundary inside a cube. A grid-striding cube carries its stage across work items, so the count is often near 512 at a boundary. At 1e16 a work item holds hundreds of tops (14–74 chunks), so the decision is taken many times inside each work item and the race is possible in main's layouts too. There, though, a chunk adds a few hundred survivors, so the stage passes 512 within a chunk or two and flushes. One instrumented 1e16 run in main's layouts (4–13 per launch, 2 fields per base) showed no mismatch.

**The fix** is that one barrier. Its cost at 1e14 was not resolved at this noise level, but it is at most about 2.5 %. In the instrumented build (with it against without, cap 64, 10 GB budget, 3 interleaved rounds) it was ×0.989 / 0.998 / 0.991 / 1.002 at b58/60/62/64. A clean build of this PR plus the barrier against this PR (2 interleaved rounds) gave ×1.025 / 1.016 / 1.007 / 0.998, where this PR alone moved 2.8 % between the two rounds at b58. At 1e16, interleaved with the A/B above, the instrumented build with the barrier ran ×0.987 / 1.009 / 1.005 / 1.005 against this PR, within the rounds' spreads, and the instrumentation adds atomics to every flush. One round of the clean build gave ×1.015 / 1.002 / 1.000 / 1.012. On wgpu (Vulkan, Metal) the divergence also puts a workgroup barrier in non-uniform control flow, which those APIs leave undefined. That is one more reason to fix it rather than tolerate the extra checks.

## Not in this PR

- **The flush-decision barrier.** It changes the join kernel, so it is a separate change. This PR makes the race far more frequent, so the barrier should land first or together with it.
- **The cap on other cards.** 64 was measured on an RTX 3080 only. More partitions per launch were slower there for a reason not yet profiled, so another card may have another optimum.
- **Fields of many slices** (1e17 and up) are still cut into slices by the unpruned bottom length. Cutting them by a pruned bound would give fewer, larger slices. One such bound is the list pruned by the whole range's certificate, since every slice's certificate contains that one.
- **A 2-D join grid.** One cube per work item at any number of partitions per launch, instead of grid-striding above 65,535 cubes. That would keep main's per-cube stage behaviour, with no carry-over, fewer overruns and the race back to main's exposure, and dynamic load balance at 1e15.
- **The rest of the 1e14 fixed cost:** the join kernel's floor per (partition, bucket) work item, and the bucket kernel.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
