# L53 RESULTS: #249's layer sort off the device thread (RTX 3080 at 150 W, 2026-11-09)

Brief: `BRIEF.md` (L51.1's lever). New commit **`80a103e`** "Overlap join: sort the top layer off the device thread"
on `pr/join-static-buckets` (third commit on `87958fd`). Box: Vast **59842980** (`nice-research-l53-sort`), RTX 3080
10 GB, driver 580.159.03, CUDA 12.8 toolkit, **power limit 150 W** (default 320 W; every timed run sat at 147–150 W),
Xeon **E5-2630 v4 @ 2.2 GHz** (20 threads visible, cgroup quota 19.2 CPUs), **7.7 GB RAM**, rustc 1.99.1. Host load
during the timed chains: load1 median 1.1–1.2 (max 1.5 / 2.0), i.e. the harness's own threads and nothing else.
Raw logs `raw/box/logs/`, scripts `raw/scripts/`, tables `raw/analysis_ab.txt` (`analyze53.py`) and
`raw/analysis_alt.txt` (`analyze_alt.py`).

## Summary

- **Where the sort sat:** not in the slice-preparing thread at all. `run_slices_with` overlapped only the next slice's
  `sub_range`; `sorted_layer` ran at the top of `run_slice` (`JoinDevice::new`) on the device thread, after the
  previous slice had read everything back, so the GPU idled through it on every slice, slice 0 included (§1).
- **The fix (`80a103e`, third commit on #249):** `sorted_layer` moves to `join_plan`; `plan_join` sorts the first
  slice (the client overlaps it with the previous field), the slice-preparing thread sorts every later slice, and
  `JoinDevice::new` only uploads. The residues come from the previous prefix's by an addition (99.8 % of steps are
  below b), u64 divisions only after larger gaps (§2).
- **The sort's own time** (b62 1e17 field, host timers): **#249's 2.05 s standalone, 2.28 s in situ on the device
  thread → the new sort 1.02 s, off the device thread** (the device thread keeps a 0.04 s clone of slice 0's layer;
  it never waited for the preparing thread). b60 1e16: 0.37 / 0.41 s → 0.18 s. The rest of the new sort is the
  counting sort's scatter (§3).
- **A/B against 87958fd** (§4): separate interleaved processes (the brief's 3 + 2 rounds, spill-free kernels only;
  6 of 26 processes compiled the spill variant and were re-run) are inside this 150 W card's ±4 % clock spread:
  device time / clock-normalised b62 1e17 ×1.009 / ×1.036, b60 1e16 ×1.023 / ×1.037, b62 1e16 ×1.021 / ×1.015,
  b64 1e16 ×1.023 / ×0.992 (wall ×1.006, ×1.016, ×1.007, ×1.019). **In one process alternating the old and new path on the same field (same kernel image,
  same temperature): b62 1e17 ×1.022 (1.020–1.024), b60 1e16 ×1.016 (1.013–1.019), b62 1e16 ×1.020, b64 1e16
  ×1.007** in wall time; the device thread saves 2.13 s of the 2.28 s sort per b62 1e17 field.
- **Verdict:** kept (b62 1e17 ≥ ×1.02), but below the brief's ×1.03–1.04: this box's 150 W cap makes the field 103 s
  (L51's 79 s) and the sort was 2.28 s here (L51 2.55–2.84). On L51's box it would be about ×1.027 (estimate).
- **Exact:** the same words and offsets on every slice of the four fields; every count identical (timed fields, 1e14
  compare, dense fields, whole b42, CPU-reference parity, #249's sentinel FD-vs-top test on the device, the
  certificate test, the host test incl. a reversed layer); lavapipe naga + SPIR-V 8 passed each; WGSL lint 0 flagged;
  fmt, clippy ×3 clean (§5).
- **Heads:** `pr/join-static-buckets` **`80a103e`** (fast-forward on 87958fd), `pr/top-fd-round2` **`5d0c8cf`**,
  `pr/check-d` **`e28b79f`** (rebased, one commit each). Conflicts: two adjacent-line ones in round 2 (CHANGELOG,
  `top_fd_runs` beside the removed `sorted_layer`) and one semantic one in check-d (its new device test's
  `JoinDevice::new` call takes the layer) (§6). All three pushed to the fork (08:12–08:13 UTC): #249's branch fast-forward, the other two with lease; no PR or GitHub edit.
- `L46/PR-BODY.md`: intro now says three commits; new section "Third commit: the top layer sorted off the device
  thread" (numbers above); "Not in this PR" gains the per-slice buffers.

## 1. Where the sort sat, and why the GPU idled (87958fd)

1. `run_slices_with` runs each slice's `run_slice` on the thread that drives the device; beside it a scoped thread
   prepares only the *next* slice's `FieldSetup` (`field.fs.sub_range`: its top layer unsorted, its bottoms pruned),
   and the loop joins that thread after `run_slice` returns.
2. The sort was not in that thread: `run_slice` begins with `JoinDevice::new`, whose first host step was
   `sorted_layer(fs, nkeys)` (a counting sort of the slice's top layer by group, two passes of 3 u64 divisions per
   prefix plus one more for `P0 mod b^(k2−f0−p)`, ~2.8 M prefixes per b62 1e17 slice), before any buffer or launch.
3. By then the previous `run_slice` had read every batch back (`run_pass` drains its fences, then `read_hits`), so
   the device queue was empty: the GPU idled for the whole sort, 11 times per b62 1e17 field (2 per b60 1e16).
4. Slice 0 was the same: `run_field` → first `run_slice` → `JoinDevice::new` → sort, on the pipeline thread that had
   just finished the previous field; `plan_join` (which the client does overlap with the previous field) built the
   first slice's `FieldSetup` but not its sorted layer.
5. So the overlap that existed covered `sub_range` only; the sort sat on the critical path between one slice's last
   read and the next slice's first launch, and `device_secs` (timed from the top of `run_slice`) counted it.

## 2. What changed (commit `80a103e`, 3 files, +161 / −85)

- **`join_plan::sorted_layer(fs) -> SortedLayer`** (moved from `cubecl_join`, same output: words, `goff`, plus the
  sort's host seconds). `JoinField` carries the first slice's layer; **`plan_join` sorts it** (the client runs
  `plan_join` on its own thread beside the device's work on the previous field), and **the thread that already
  prepared each next slice's `FieldSetup` now also sorts that slice's layer**. `JoinDevice::new` takes the layer
  (`SortedLayer`, by value) and only uploads it; `run_slice` passes it through. `st.setup_secs` adds the sort's time
  (so the benchmark's setup, which it treats as overlapped on GPUs, now holds it instead of `run_secs`).
- Rare paths sort on the device thread as before: a refit after a refused layout, and the overflow re-run's
  partitions on halves of the layer (`run_partition`). Slice 0's layer is cloned out of the `JoinField` on the device
  thread (one memcpy: 0.03–0.05 s per field, below).
- **Division-free residues:** the layer is ascending and 99.81–99.84 % of consecutive steps are below b on the four
  fields, so each prefix's residues mod b, b−1 and b^(k2−f0−p) are the previous prefix's plus the step (one
  conditional subtract each, u64 adds); a gap of b or more (or a first / out-of-order prefix) takes the three
  divisions. The class `P0·b^p mod (b−1)` is a table lookup by `P0 mod (b−1)`. Pass 1 stores (group, residue) per
  prefix (8 B), pass 2 scatters as before.
- Host test `sorted_layer_and_segments_match_the_cpu_buckets` also runs on the b62 1e14 field's layer **reversed**
  (every residue by division): 21 fields, 582,884 buckets agree. CHANGELOG: one line under Unreleased (#249).
- Anything else per slice that does not need the device: the bit-mask words, field bounds and power table are
  0.2 ms a slice (L51 §1.1) and stay; the buffers' creation (0.10 s a slice, L51) needs the device (bundle C).
- A first version stored P0 with each pass-1 entry (16 B) to skip re-reading `tlay` in pass 2: slower (1.15 against
  1.02 s per b62 1e17 field, `sort_timing2.log`), dropped.
- The first push candidate (`39a495a`) failed clippy (`similar_names`: `layer` beside the existing `later`); the
  binding is `sorted` in `80a103e`, nothing else changed. The CUDA exactness list passed on both trees (§5).

## 3. The sort's own time (host timers)

**Standalone** (`l53_sort_timing`, `patch53x.py`: every slice of each field planned for this card, #249's sort copied
verbatim against the new one on the same `FieldSetup`, nothing else running; `raw/box/logs/sort_timing.log`):

| field | slices | prefixes | #249's sort | new sort | ratio | steps by division |
|---|---|---|---|---|---|---|
| b62 1e17 | 11 | 30,636,533 | **2.052 s** | **1.021 s** | ×2.0 | 47,854 (0.16 %) |
| b60 1e16 | 2 | 5,281,726 | 0.368 s | 0.177 s | ×2.1 | 10,113 (0.19 %) |
| b62 1e16 | 2 | 3,620,628 | 0.237 s | 0.120 s | ×2.0 | 5,618 (0.16 %) |
| b64 1e16 | 1 | 3,053,841 | 0.209 s | 0.102 s | ×2.0 | 5,024 (0.16 %) |

- **Words and offsets identical on every slice of all four fields** (and the `JoinField`'s slice-0 layer equals #249's).
- The divisions were half the sort. Of the new sort's 1.0 s at b62 1e17, pass 1 (residues, groups, counts) is about
  0.3 s (a replica timed in `sort_timing2.log`); the rest, ~23 ns per prefix, is the counting sort's scatter (20-byte
  records into ~3,800 group streams, 56 MB a b62 slice) and the second read of `tlay`'s 32-byte entries, as before.
- **In situ, on the device thread** (the in-process A/B's "old" fields, §4.2): **2.28 s per b62 1e17 field**
  (2.26–2.32), 0.41 s b60 1e16, 0.27 s b62 1e16, 0.23 s b64 1e16, about 10 % above standalone (L51 measured
  2.55–2.84 s on the same CPU model with its profile timers in).
- **After:** on the device thread 0 s plus the slice-0 clone (0.033–0.047 s per field); off it, the new sort's
  1.0 s per b62 1e17 field rides on the slice-preparing thread beside `sub_range` (1.3 s a slice) and the device's
  ~9.3 s per slice: the device thread never waited for it (`prep_wait` 0.0000 s in every field, §4.2). `plan_join`
  takes 2.0 s per field here (the probe's bottom list and the first slice's top side; the doc's "20–300 ms" is
  stale for this CPU, and the sentence lost the number), +0.13 s for the first slice's sort.

## 4. A/B against 87958fd

### 4.1 Separate processes, interleaved (the brief's design; `chain_ab.sh`, 06:08–06:36)

`B` = 87958fd, `N` = 87958fd + the commit (as `39a495a`/`80a103e` minus a match arm's shape and a doc line: same
code path). Harness `cubecl_cuda_join_throughput_fixed_fields` at L30's starts, one untimed 1e14 warm-up field per
process; order B N / N B / B N; 3 rounds at b62 1e17 (1 field) and b60 1e16 (2 fields), 2 at b62 1e16 and b64 1e16.
"device" = `device=` (mean run_field device seconds per field), "wall" = `per_field=` (the harness's wall time per
field, which at one field includes that field's `plan_join`, not overlapped), "cycles" = s × mean SM MHz over 5-s
samples at ≥ 90 % utilisation. Every process's join kernel replayed through the driver's JIT (`ptxjit.py`): **6 of 26
processes compiled the 40-register spill variant** (B 2, N 4) and were re-run once each; every compared process is
spill-free (46–48 registers). Counts exact in every run (32 processes incl. the spilled).

| field | B device s (rounds) | N device s (rounds) | device × (per round) | wall × (per round) | cycles × | MHz B / N |
|---|---|---|---|---|---|---|
| **b62 1e17** | 102.33 (98.33, 104.53, 102.33) | 101.41 (101.41, 103.24, 100.70) | ×1.009 (0.970, 1.013, 1.016) | ×1.006 (0.967, 1.010, 1.014) | ×1.036 | 1158 / 1150 |
| **b60 1e16** | 20.46 (20.77, 20.46, 20.46) | 20.01 (20.42, 20.01, 19.98) | ×1.023 (1.017, 1.023, 1.024) | ×1.016 (1.011, 1.016, 1.016) | ×1.037 | 1112 / 1112 |
| b62 1e16 | 8.64 (8.75, 8.52) | 8.45 (8.53, 8.37) | ×1.021 (1.025, 1.018) | ×1.007 (1.008, 1.006) | ×1.015 | 1148 / 1155 |
| b64 1e16 | 27.85 (28.15, 27.55) | 27.23 (27.99, 26.46) | ×1.023 (1.006, 1.041) | ×1.019 (1.002, 1.036) | ×0.992 | 1146 / 1184 |

**This card's clock is the noise floor here:** at the 150 W cap the SM clock moved 1,086–1,252 MHz between processes
(temperature: the chain's first process started at 36 °C, later ones at 54–57 °C), ±4 % against a ~2 % effect;
round 1 at b62 1e17 (B cold at 1,234 MHz, N at 1,150) went the wrong way in time and the right way in cycles.
nvidia-smi cannot lock clocks in this container (`-lgc`: no permission; nothing changed). Hence 4.2.

### 4.2 One process, the same field repeated, alternating old and new (`patch53y.py`, `chain_alt.sh`, 06:57–07:22)

Binary `Y` = the commit + an experiment switch: every other field runs **exactly 87958fd's path** (the next slice's
`sub_range` beside the device, no sort there; #249's sort, copied verbatim, at the top of `run_slice` on the device
thread, inside `device_secs`), the others the commit's. The harness repeats the same field n times
(`NICE_EXP_L53_REPEAT`); old fields are odd, new even (the 1e14 warm-up is field 0). Both sides share the process's
kernel images (one JIT allocation, spill-free in all 4 processes: 46–48 registers) and the card's thermal state;
neighbouring fields are seconds apart. Speed-up = each interior field against the mean of its two neighbours (a
linear drift cancels), median and range; nvidia-smi every 1 s. "wall" = `run_slices_with`'s own duration (the
device thread's whole field, waits included); "device" = its `device_secs`. `raw/analysis_alt.txt`.

| field (fields run) | sort on the device thread, old fields (s/field) | old wall s/field | new wall s/field | **wall ×** median (range) | device × median | prep wait, new |
|---|---|---|---|---|---|---|
| **b62 1e17** (7: 4 old, 3 new) | **2.281** (2.256–2.321) | 103.86 | 101.73 | **×1.022** (1.020–1.024) | ×1.023 | 0.0000 s |
| **b60 1e16** (13) | 0.406 (0.395–0.415) | 20.34 | 20.04 | **×1.016** (1.013–1.019) | ×1.018 | 0.0000 s |
| b62 1e16 (21) | 0.274 (0.262–0.284) | 11.56 | 11.33 | ×1.020 (1.015–1.038) | ×1.024 | 0.0000 s |
| b64 1e16 (9; 1 slice) | 0.231 (0.221–0.241) | 27.80 | 27.62 | ×1.007 (1.005–1.008) | ×1.008 | 0.0000 s |

- **The device thread saves 2.13 s of the 2.28 s sort per b62 1e17 field** (0.30 of 0.41 s at b60 1e16, 0.23 of
  0.27 at b62 1e16, 0.18 of 0.23 at b64); the rest is the slice-0 clone (0.03–0.05 s) and run-to-run spread.
- Every field's counts: the totals of each process are n × one field's (b62 1e17: 7 × 1,020,844,021,499 /
  62,584,252,554 exactly).
- The first form of this chain (06:45–06:53, logs `diffields_alt_*`) ran consecutive *different* fields (the
  harness's default), whose times differ by up to 3× at 1e16; discarded, kept for the record.

**Verdict:** not killed (the kill needs < ×1.02 at both fields; b62 1e17 is ×1.022), but below the brief's
×1.03–1.04: at this box's 150 W cap a b62 1e17 field takes 102–104 s (L51's 180 W box: 79 s), and the sort cost
2.28 s in situ here (L51: 2.55–2.84 s). The same 2.1 s saving on L51's 79 s field would be ×1.027 (estimate).

## 5. Exactness

On the final tree `C` = `80a103e` (CUDA unless marked; logs `raw/box/logs/x_C_*`, `cmp_C_e14.log`, `lvp_*`, `fmt_C`,
`clippy_*_C`). The test binary of `80a103e` is byte-identical to that of `39a495a` (md5 `22af4cc4…`, and the
lavapipe binaries too: the rename changed no code), whose identical run is in `raw/box/logs/prerename/`.

- **Host test** `sorted_layer_and_segments_match_the_cpu_buckets`: ok, **21 fields, 582,884 buckets agree** (b10, the 17
  windows, b62 and b64 1e14, and the b62 1e14 layer reversed). `join_plan::` 7 passed; `cubecl_join::` 5 passed
  (15 device tests ignored there, run below).
- **Every slice of the four timed fields** (§3): the new sort's words and offsets equal #249's (30.6 M + 5.3 M + 3.6 M
  + 3.1 M prefixes), and `plan_join`'s slice-0 layer equals #249's.
- `cubecl_cuda_join_matches_the_cpu_reference`: ok (78 s).
- **#249's sentinel FD-vs-top device test** `cubecl_cuda_top_fd_matches_the_top_kernel` (with `fill_sentinel` before
  each kernel's run; its first device run): ok, 26 fields, 279 batches (23 with a clipped block), **237,948,545 tops**.
  L46 had 237,907,266 on b058bb7: this box cuts the b60 1e16 test field's slices 1,024 prefixes differently (first
  slice 4,347,381 against 4,348,405; total equal), and 87958fd's own binary cuts it the same way here, so the
  difference is the device's limits, not this commit. (87958fd's run here, `x_B_topfd2.log`: 237,948,545 tops, the same.)
- `cubecl_cuda_top_certificates_match_the_lockstep_scan_and_the_cpu`: ok, 102,365 intervals, 33,582 kept, 203,413
  above c0, 69,824 with the carry (L46's).
- Dense fields, equal to the CPU join: b58 1e15, 32 partitions, **254,938,965 / 14,396,829**; b62 1e16, 4 partitions
  (2 slices), **120,013,475 / 7,355,827** (L46's).
- **Whole b42 field**: 1,764 partitions, **417,789,835** join survivors, **16,879,877** checked, no hits; join =
  stride = CPU reference (L46's).
- **1e14 COMPARE** (b57/60/62/64, join = stride, found 0): **4,850,227,888 / 268,123,373; 2,694,700,282 / 180,517,288;
  1,439,469,648 / 88,159,810; 5,702,041,796 / 346,647,759** (L38's).
- Every timed field in §4: b62 1e17 **1,020,844,021,499 / 62,584,252,554**; b60 1e16 **460,847,952,346 /
  30,871,838,404**; b62 1e16 **163,513,599,082 / 10,027,698,695**; b64 1e16 **787,584,956,227 / 47,900,853,327**, in
  every process of both sides (incl. the spill-variant ones), and the repeated-field processes' totals are n × one
  field's.
- **lavapipe** (llvmpipe, LLVM 20.1.2, Mesa 25.2.8, 8-lane subgroups): every wgpu test of `cubecl_join` (CPU-reference parity incl. b50/b54, the
  FD-vs-top-kernel test with the sentinel on 21 fields / 142 batches / 1,018,088 tops, the certificate test, the
  production-field sample, the ticket test): **ok with naga (8 passed, 214 s) and with direct SPIR-V (8 passed,
  424 s)**.
- CI's WGSL lint (`wgsl_dump_for_lint` on lavapipe + `scripts/wgsl-lint.py`, the workflow's 13 `--require`s): **14
  shaders, 0 flagged** (JoinKernel b57: 29 constant divisions).
- **`cargo fmt --all --check`**: clean. **`cargo clippy -p "*" --all-targets -- -D warnings`**: default, with
  `--features nice_client/gpu`, with `--features nice_client/gpu,nice_client/cubecl-spirv` (rustc 1.99.1): **clean**
  (on `80a103e`; `39a495a` failed all three on `similar_names`, §2).

## 6. Branches

| branch | old head | new head | how |
|---|---|---|---|
| `pr/join-static-buckets` (#249) | `87958fd` | **`80a103e`** | third commit on top (fast-forward, no force) |
| `pr/top-fd-round2` | `d813aea` | **`5d0c8cf`** | `d813aea` rebased onto `80a103e` (one commit, force-with-lease) |
| `pr/check-d` | `7d6956f` | **`e28b79f`** | `7d6956f` rebased onto `5d0c8cf` (one commit, force-with-lease) |

**Conflicts (the brief expected none):**
- `pr/top-fd-round2`, two textual ones, both adjacency: CHANGELOG (FD round 2's `#NNN` line sits where the new #249
  line was added: both kept, #249's first) and `cubecl_join.rs`, where `d813aea` adds `top_fd_runs` directly above
  the old `sorted_layer`, which this commit removes (kept `top_fd_runs`, dropped `sorted_layer`). `d813aea`'s
  `join_plan.rs` changes (`vram_budget`, `SURV_PER_PREFIX_VRAM`) merged cleanly beside the new `SortedLayer`
  (`with_plans` gets both). Same diffstat as `d813aea` (3 files, +548 / −187).
- `pr/check-d`: no textual conflict, but one **semantic** one: its new device test helper `check_counts` calls
  `JoinDevice::new(client, &fs, &plan)`; the rebased commit adds `let layer = sorted_layer(&fs)…` and passes it
  (+1 line: 5 files, +1572 / −115 against 7d6956f's +1571 / −115).
- Checks on the rebased heads: built on the box (`chain_rebased.sh`, logs `rb_*`), both heads: host unit tests ok
  (`join_plan::` 8 passed, `cubecl_join::` 7 passed), the 1e14 compare at b57/60/62/64 (L38's counts, join =
  stride), `cubecl_cuda_join_matches_the_cpu_reference` ok; on `e28b79f` also check-d's own device test
  `cubecl_cuda_check_counts_match_the_cpu` (the one whose call site changed) ok; `cargo fmt --all --check` and
  `cargo clippy -p nice_common --all-targets -D warnings` default and `--features gpu`: clean. Not run on them: the
  long exactness list, lavapipe, timed runs (their own sessions measured those; the rebase moves no code of theirs).

## 7. Files

- `RESULTS.md` (this), `BRIEF.md`.
- `raw/analysis_ab.txt` (`python3 raw/scripts/analyze53.py raw/box/logs`), `raw/analysis_alt.txt`
  (`python3 raw/scripts/analyze_alt.py raw/box/logs`), `raw/commit-msg.txt`.
- `raw/box/logs/` (the box's `/root/l53/logs`): `trees.txt`, `box-info.txt`, `nvidia-smi.txt`, `power.txt`,
  `build_*.log`; `sort_timing.log`, `sort_timing2.log` (§3); `ab_<B|N>_<field>_r<n>.{log,smi}` + `_jit.txt`
  (`*_spill0*` = the spill-variant processes, re-run); `alt_<field>.*` (§4.2), `diffields_alt_*` (the discarded
  different-fields form); `loadavg_*.txt`; `cmp_C_e14.*`, `x_C_*` (CUDA exactness), `x_B_topfd*.log` (87958fd's FD
  test here: the first run was OOM-killed beside a build, 7.7 GB box), `fmt_C.log`, `clippy_*_C.log`, `lint_dump_C.log`,
  `wgsl_lint_C.log`, `wgsl_C.log.gz`, `lvp_device.txt`, `lvp_{naga,spv}_C.log`; `rb_<R2|CD>_*` (rebased heads);
  `prerename/` (the same exactness and lint on `39a495a`, and the run logs of that tree).
- `raw/box/*.out`: chain outputs.
- `raw/scripts/` (run on the box from `/root/l53`): `setup.sh`, `addtree.sh`, `addN.sh` (a tree = 87958fd + a diff
  [+ a patch script]), `build.sh`, `run.sh`, `run1.sh` (1-s nvidia-smi), `test.sh`; `chain_ab.sh` (§4.1),
  `chain_alt.sh` + `patch53y.py` (§4.2), `patch53x.py` (the sort timing test, §3); `chain_x.sh`, `chain_lint.sh`,
  `chain_lvp.sh` (§5), `chain_rebased.sh`, `final.sh`, `reset_final.sh`; `ptxjit.py`, `cbor_min.py`, `jitlog.py`
  (L45/L51's); `analyze53.py`, `analyze_alt.py`.
- Trees on the box: `B` 87958fd, `N` the commit's code as A/B'd (§4.1), `X`/`X2` timing experiments, `Y` the
  in-process A/B, `C` = `80a103e`, `R2` / `CD` the rebased heads.

## 8. The box

**Vast 59842980 can be destroyed:** nothing of this session is running on it (GPU idle, no build or test
processes), and every log, chain output and script is in `raw/` (pulled 08:16 UTC; the PTX caches under
`/root/l53/ptx` are summarised in the `*_jit.txt` files and were not pulled). Box time used: ~05:46–08:16 UTC.
