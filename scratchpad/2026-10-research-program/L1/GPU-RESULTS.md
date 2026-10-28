# L1 GPU results: per-phase timing of the overlap join by base (RTX 3080)

2026-10-28, 04:56–05:45 UTC. Vast box `ssh2.vast.ai:30942`: an RTX 3080 10 GB (driver 580.126.09,
power limit 260 W, PCIe 3 x16) on a Xeon E5-2658A v3 host. The rental is 16 cores, but `nproc` shows 48 and
there is no cgroup CPU quota. Code: upstream main `85b5b4e` plus the instrumentation commit `0c4b880` on
branch `rp/gpu-profile` (`patches/0001-…patch`; the director pushes it). The `prof_1e16` and
`noprof_1e16` logs record `commit=85b5b4e` because they started before the commit. Their binary was built
from the same working tree, so the code is identical.

## Method

`NICE_EXP_GPU_PROFILE=1` (off by default; unset, the code paths are as before). In every
`JoinDevice::launch_batch`, the host synchronises the device (`client.sync()`) after each kernel group and
charges that group's wall time:

- **inputs**: the batch's small buffers;
- **top**: `top_kernel` + `top_scan_kernel` + `top_fill_kernel`;
- **bucket**: `bucket_kernel`;
- **join**: `join_kernel`, i.e. the AND scan plus the inline `mid_pass` prefilter;
- **check**: `check_kernel`.

It also times:

- **upload**: `JoinDevice::new`, synchronised before and after;
- **read**: the count and hit readbacks;
- **probe**: its own readback of the per-slot `top_count`/`work`/`counts` buffers, after the bucket kernel. This is excluded from every phase.

From those buffers it counts:

- certified **tops**;
- **listed** bottom entries (once per key digit);
- AND **pairs** = Σ over (partition, bucket) of tops × entries;
- **padded pairs**, with each bucket's entries rounded up to whole waves of `ENTRIES_PER_THREAD·JOIN_WG` = 1024.

AND survivors and prefilter survivors are the existing `JoinFieldStats` counters. Full checks equal
prefilter survivors, because `check_kernel` checks every list entry. The pipeline thread prints one
`GPU_PROFILE` line per field. "other" in the tables below is upload + inputs + read + probe + unattributed.

**Profiling overhead:** 3.9–6.3 % of device time. I measured it from the same fields with the variable unset
(table 1). The overhead is about 5,400 batches × 6 syncs per field, plus the probe reads. Phase shares are
from profiled runs. The unprofiled µs/prefix is the production-comparable number.

Fields are 1e16 at every base, 2 fields per base, consecutive. Each base runs one untimed 1e14 warm-up field
first, which compiles the kernels. Starts:

- b58: 104_400_216_587_923_470_200, the `b58_msd_weak` scenario field (grid index 7680 of 1e15 fields from the base start; base range [9.67e19, 1.90e20)).
- b60: 1_366_406_074_057_412_100_454, the `PLAN_FIELDS` start + 1e14. The unshifted start's warm-up window `[s−1e14, s)` has an empty top layer, so field 1 absorbed about 2.5 s of NVRTC compilation into "top" (13.7 vs 11.2 s; see `raw/prof_1e16.log`). The shifted run (`raw/prof_1e16_b60shift.log`) is the one in the tables.
- b62: 7_997_740_455_941_656_911_841 (`PLAN_FIELDS`).
- b64: 41_242_006_262_957_161_709_568 (`PLAN_FIELDS`).

Commands (on the box, `/root/run_join.sh`, copy in `work/run_join.sh`):

```
cargo test --release -j 16 -p nice_common --features gpu --no-run
NICE_EXP_GPU_PROFILE=1 NICE_TEST_JOIN_FIELDS=2 NICE_TEST_JOIN_SIZE=1e16 NICE_TEST_JOIN_BASES=58,60,62,64 \
  NICE_TEST_JOIN_STARTS=60:1366405974057412100454 \
  target/release/deps/nice_common-9ecbc10167c89963 --ignored --exact \
  cubecl_join::tests::cubecl_cuda_join_throughput_fixed_fields --nocapture --test-threads 1      # prof_1e16
# same, NICE_EXP_GPU_PROFILE unset, STARTS=60:1366406074057412100454                             # noprof_1e16
# same, profiled, base 60 only, STARTS=60:1366406074057412100454                                 # prof_1e16_b60shift
```

Run by run:

- **Layout.** At 1e16 the plan cuts every field into 5–8 slices, with 4–6 partitions per batch. Exception: b62 field 2 reaches 16 per batch, because most of its slices are empty.
- **Clean runs.** No re-runs, splits, or refused layouts. No hits.
- **SM clock.** Observed at 1830 MHz in both spot checks, about 230 W, 54–61 °C.
- **Counter drift.** The counts are deterministic to about 3e-9 between runs: b62 differs by 560 AND survivors out of 1.8e11. That is consistent with the documented stage-overflow path, where a few survivors go to the list unprefiltered and uncounted. That path is evidently timing-dependent, which the code comment does not say.

## 1. Seconds per field and phase shares

| base | roots | device s/field, profiled | unprofiled | profile overhead | top | bucket | join | check | other |
|---|---|---|---|---|---|---|---|---|---|
| 58 | 4 | 72.6 | 68.8 | +5.5 % | 19.5 % | 3.8 % | **64.8 %** | 4.7 % | 7.3 % |
| 60 | 2 | 47.9 | 45.2 | +6.0 % | 23.3 % | 5.1 % | **55.8 %** | 5.3 % | 10.5 % |
| 62 | 2 | 27.8 | 26.1 | +6.3 % | 21.9 % | 7.2 % | **57.9 %** | 3.6 % | 9.5 % |
| 64 | 8 | 86.4 | 83.1 | +3.9 % | 7.1 % | 3.3 % | **82.6 %** | 3.1 % | 3.9 % |

Per-field seconds are in `raw/` and in `work/analyze.py`'s output. The two fields of a base agree within 1 %
in shares. b62's second field is sparse (1.55 M prefixes against 3.69 M), but its shares match.

Host setup per field (top layer + bpre, on the CPU) was 5.1–5.4 s at b58, 4.3 s at b60, 1.5–3.6 s at b62,
and 3.2 s at b64. With two fields in flight it overlaps the previous field's device work. It is not in the
device seconds.

## 2. µs per top-layer prefix

| base | prefixes per field (mean) | **µs/prefix unprofiled** | profiled | top | bucket | join | check | other | RX 9070 XT (BACKLOG 68) |
|---|---|---|---|---|---|---|---|---|---|
| 58 | 6.01 M | **11.44** | 12.07 | 2.35 | 0.45 | 7.82 | 0.56 | 0.88 | 11.2 |
| 60 | 5.30 M | **8.51** | 9.03 | 2.11 | 0.46 | 5.04 | 0.48 | 0.94 | 6.8–7.3 |
| 62 | 2.62 M | **9.96** | 10.58 | 2.32 | 0.76 | 6.13 | 0.38 | 1.00 | 9.2–9.6 |
| 64 | 3.10 M | **26.84** | 27.89 | 1.98 | 0.91 | 23.05 | 0.87 | 1.09 | 19.5 |

Per prefix, the 3080 is 1.02× the 9070 XT at b58, about 1.2× at b60, 1.06× at b62 and 1.38× at b64.

The b64/b62 ratio is 2.70× here, against 2.0–2.1× on the 9070 XT.

Everything except the join kernel costs 4–5 µs per prefix at every base:

- top 2.0–2.4;
- bucket 0.5–0.9;
- check 0.4–0.9;
- other about 1.

The join kernel alone accounts for the b64 jump: 23.05 µs against 6.13 at b62 (3.76×).

## 3. Counts per field and per prefix

| base | partitions (b²) | tops/prefix | AND pairs/prefix | entries per probed bucket | padded/pairs | AND survivors/field | **AND survivors/prefix** | AND pass per pair | prefilter survivors (= full checks)/field | per prefix | prefilter keeps |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 58 | 3364 | 1178 | 4.53e6 | 961 | 1.07 | 3.83e11 | **63.7k** | 1.41 % | 2.31e10 | 3840 | 6.02 % |
| 60 | 3600 | 1303 | 2.43e6 | 931 | 1.10 | 2.32e11 | **43.8k** | 1.81 % | 1.65e10 | 3102 | 7.08 % |
| 62 | 3844 | 1264 | 3.01e6 | 1192 | 1.72 | 9.12e10 | **34.8k** | 1.15 % | 5.77e9 | 2202 | 6.33 % |
| 64 | 4096 | 1285 | 1.25e7 | 1212 | 1.69 | 4.33e11 | **139.8k** | 1.12 % | 2.72e10 | 8773 | 6.27 % |

How the columns are derived:

- "entries per probed bucket" = pairs ÷ (tops × roots): the mean occupancy of a bucket a top probes.
- "padded/pairs" is the lane overhead of rounding each bucket up to whole 1024-entry waves.

Bottoms:

- `bpre` is the bottom list, rebuilt per slice.
- "listed" counts the entries extended by each partition and put on bucket lists, once per key digit.
- Live buckets are those that some top probes. At 1e16 every bucket is live.

| base | slices/field | bpre entries per slice | listed entries/field | listed per prefix | live buckets/field | tops/field |
|---|---|---|---|---|---|---|
| 58 | 8 | 1.42e5 | 8.55e10 | 14.2k | 8.9e7 | 7.08e9 |
| 60 | 7 | 1.38e5 | 8.31e10 | 15.7k | 8.9e7 | 6.91e9 |
| 62 | 6 | 1.47e5 | 6.93e10 | 26.4k | 5.8e7 | 3.32e9 |
| 64 | 5 | 1.80e5 | 1.00e11 | 32.3k | 8.3e7 | 3.98e9 |

b62's figures are the mean of a dense field (3.69 M prefixes, 4.7e9 tops) and a sparse one (1.55 M
prefixes, 2.0e9 tops). The bucket kernel's cost follows partitions × slices × bpre, not prefixes. That is
why its per-prefix figure is highest at b62/b64, which have fewer prefixes per slice.

Against the 9070 XT's survivors per prefix:

- b62: 27–44k there, 33–35k here.
- b64: 112–176k there, 140k here.
- b60: about 26k there, 43–44k here. This b60 window is denser in survivors than the windows the 9070 XT used. µs/prefix depends on survivors per prefix (section 5), so this window likely overstates b60's per-prefix rate a little.

## 4. Root-count check

Each certified top probes one bucket per digit-sum class root. Survivors per prefix factor as:

> tops/prefix × roots × entries per probed bucket × AND pass rate per pair

Measured, the factors are:

- **tops/prefix**: 1180–1300 at all four bases, about 31–36 % of the b² partitions.
- **entries per probed bucket**: 930–1210. Both are flat in base.
- **roots**: so the AND pairs per prefix follow the roots. b64/b62 = 4.15× pairs, with roots 8/2 = 4.
- **survivors per prefix**: b64/b62 = 139.8k / 34.8k = **4.02×**. The product of the factors gives 1.017 × 4 × 1.017 × 0.97 = 4.01, so **the root count explains b64 against b62 completely**.
- **b58 against b60**: survivors per prefix are 1.45×, not the roots' 2×. Pairs are 1.86× (roots 2 × occupancy 1.03 × tops 0.90). The AND passes fewer pairs at b58: 1.41 % against 1.81 %. The factor product is 1.45, so roots × pass rate explains it.

So the expected root counts (4, 2, 2, 8) set the pair volume, and survivors follow pairs × a base-dependent pass rate of 1.1–1.8 %.

## 5. What the join kernel's time is made of

I fitted `join_secs = a·padded_pairs + c·AND_survivors + d·listed_entries` over the 10 profiled 1e16 fields
(4 bases), using `work/fit.py`. Treat it as a strong hint, not a measurement: there are only four distinct
bases. The fit gives:

- a = 0.577 ps per padded lane-pair;
- c = 73.7 ps per AND survivor (set-bit walk, shared stage, `mid_pass`, flush);
- d = 19 ps per listed entry (register loads of `ext_m`);
- max error 1.9 %.

Pairs alone fit to within 12 %, and padded pairs alone to within 37 %.

At b64, of 71.4 s of join per field:

| component | seconds | share of join |
|---|---|---|
| padded AND | 37.5 | 52 % |
| survivor handling | 32.0 | 45 % |
| entry loads | 2.0 | 3 % |

**Wave padding is a measurable, base-dependent waste.** Mean bucket occupancy is 930–960 at b58/b60, under
the 1024-entry wave (padded/pairs 1.07–1.10). At b62/b64 it is 1190–1210, just over one wave, so most
buckets run two waves (padded/pairs 1.69–1.72). At 0.577 ps per lane-pair, the padding beyond real pairs
costs:

- b64: about 15 s of 83 s per field (18 %);
- b62: about 4.6 s of 38.8 s on field 1 (12 %).

Padding explains two things in the per-prefix table:

- **b62 against b60.** b62 costs more per prefix than b60 (9.96 against 8.51 µs) despite equal roots and fewer survivors per prefix, because its buckets spill into a second wave.
- **b64 against b62.** b64 is only 2.7× b62 overall although its pairs are 4.15×. Both pay the same 1.7× padding, so the join is 3.76× and the 4–5 µs of non-join work per prefix does not scale.

It is also consistent with #205 (EPT 6 = 1536-entry waves, +14 % at b64 on the 9070 XT). A per-base EPT
(4 at b58/b60, 5–6 at b62/b64) or an occupancy-sized tail wave is the direct lever.

The survivor term (45 % at b64) is the other lever: fewer AND survivors per pair, or a cheaper walk and stage.

## 6. Interpretation for L1 and neighbours

- **The climb.** The b64 per-prefix climb is the join kernel, and inside it the pair volume set by the 8 roots, partly irreducible. Top, bucket and check cost the same per prefix at every base.
- **b62.** b62 already pays the padding share (1.7×) that EPT tuning could recover. That is the "whether b62 already pays part of it" answer, and it is the 5–20 % lever on b62/b64.
- **L4 (post-join filter bundle).** The final check is 3–5.5 % of device time, and 3.8–9.8 % of join time. L4's kill criterion ("final check under 15 % of join time") is met on this card at all four bases.
- **Top kernel.** The top kernel is 7–23 % of device time: about 2 µs per prefix, which is b² certifications of both endpoints' squares and cubes. At b58/b60/b62 it is the second-largest phase.

## Raw data

`raw/` holds:

- `prof_1e16.log`: profiled, all four bases.
- `noprof_1e16.log`: unprofiled.
- `prof_1e16_b60shift.log`.
- `sanity_b60_1e14.log`.

`work/` holds:

- `cubecl_join.rs`: the instrumented file.
- `run_join.sh`.
- `analyze.py`: tables.
- `fit.py`: the join fit (`uv run --with numpy python3 work/fit.py raw/prof_1e16.log raw/prof_1e16_b60shift.log`).
