# L46 RESULTS: a static bucket order for the top layer — built, exact, ×1.15–1.22 (2026-11-07)

Roadmap item 1 (L44 §3e), priced by L45 §A (scan + fill 9.7 % of b62 1e17, 9.0 % of b60 1e16). Design:
`DESIGN.md`. Branch **`exp/join-static-buckets`** on the fork (head `b058bb7`, six commits on `f3fb390`); the
PR-ready branch is **`pr/join-static-buckets`** (`8e0eb99` + the rider `b7feb89` after the review, §6–7). Box: Vast **59529576** (`nice-research-l46-static`), machine
**m139246**, RTX 3080 10 GB, driver 580.159.03, host cap **180 W** (every timed run at 176–180 W), Xeon (cgroup
9.6 CPUs). Raw logs `raw/box/` (the box's `/root/l46/logs`, SASS in `raw/box/sass/`), scripts `raw/scripts/`.

## Summary

- **The design works as planned:** sort each slice's top layer once on the host by group `(key, P0 mod (b−1))`;
  the top kernels append each kept top into its group's segment of the slot's records; a join work item reads its
  bucket's tops as `nroots` contiguous segments. `top_scan_kernel`, `top_fill_kernel`, `tl`, `top_b`, `work`,
  `cursor` and the per-top bucket atomics are gone. Exact by construction (same pairs per bucket) and in every test.
- **A/B against f3fb390 (#246), 3 interleaved rounds, same box, nothing else running** (device s per field):

  | field | f3fb390 | static buckets | speed-up (per round) | cycles | MHz |
  |---|---|---|---|---|---|
  | **b62 1e17** | 100.38 | **86.68** | **×1.158** (1.141, 1.158, 1.158) | ×1.174 | 1491 / 1482 |
  | b62 1e16 (2 fields) | 8.347 | 7.276 | ×1.147 (1.147, 1.152, 1.147) | ×1.151 | 1485 / 1506 |
  | **b60 1e16** (2 fields) | 19.675 | **17.049** | **×1.154** (1.154, 1.154, 1.146) | ×1.150 | 1483 / 1473 |
  | b64 1e16 (2 fields) | 28.335 | 23.189 | ×1.222 (1.222, 1.224, 1.215) | ×1.220 | 1462 / 1478 |
  | 1e14 b57 / b60 / b62 / b64 (3 fields each) | | | ×1.096 / ×1.056 / ×1.055 / ×1.028 | | |

  Above L45's ×1.107 / ×1.099 ceiling for deleting scan + fill alone: the join's batch load now reads consecutive
  records instead of gathering by id, and the top kernels lose nroots atomics per kept top (b64, 8 roots, gains
  most). Not clock: both sides ran at the same clocks, cycles ratios equal the time ratios.
- **The bar is met** (≥ 5 % at b62 1e17 and b60 1e16, no NiceMark scenario below ×0.98 over 6 rounds): NiceMark
  nice-only score **×1.119** (6 rounds, per round 1.103–1.138); b58 MSD-weak ×1.145, b58 MSD-strong ×1.043, b60
  MSD-weak ×1.153, b62 MSD-weak ×1.145. `PR-BODY.md` is written; no PR opened.
- **Exactness: every check passed** (§2), counts identical to the base and to L38's lists.
- **Registers** (driver JIT of the runtime's NVRTC PTX, `ptxjit.py`): the join is 46–48 registers and spill-free in
  30 of 37 kernel images; in 7 (about one in five) the JIT chose 40 registers with 8–32 B of spills in the per-item
  and per-wave code, not in the chunk loop. **That spilling variant is new** (the base: 47–48, 37 of 37 spill-free
  here, 100 of 100 in L45). The kernel is the same at every field size, so production processes will get it at about
  that rate; that the 12 timed production processes did not is chance (0.81^12 ≈ 8 %). Where it occurred (four 1e14
  A/B processes) the runs were −2.7 % to +1.8 % against the spill-free ones, inside the 2–4 % spread; it was not
  timed on a production field. So the "no spills" gate is not met in every process (review item 2). `top_fd_kernel` 108–112 (base 108–111),
  `top_kernel` 97–103 (base 80), neither spills (§3).
- **The rider** (survivor stage checked once per top batch, `exp/join-static-buckets-s15`) is another **×1.022–1.030**
  on top (b62 1e17 ×1.029, b60 1e16 ×1.022; NiceMark ×1.019 over 2 rounds), exact (§5). Folded into the PR branch as its second commit after the review (§6).
- **Remaining:** nothing for this item's build. Open: the rebase
  against L48 (it changes `top_fd_kernel`'s append too, its level 2: the conflict is the append block, which this
  branch replaces by `top_slot(...)`, plus the kernel's argument list and the FD device test's helper).
- **The box (59529576) can be destroyed:** nothing is running on it and every log, SASS dump and script is in
  `raw/` (pulled 08:35 UTC). Box time used: ~2 h 45 min of the 7 h.

## 1. What was built (`exp/join-static-buckets`)

Six commits (squashed into one for `pr/join-static-buckets`); 2 files, +304 / −344:

- `sorted_layer` (host, per `JoinDevice::new`): counting sort of the slice's top layer by group `g = key·(b−1) +
  P0·b^p mod (b−1)`, group offsets `goff` (nb + 1 words, a new fixed buffer); tlay words 2–3 carry `g` and `goff[g]`
  (were P0 mod (b−1) and the key). The per-prefix mods are u64 (P0 < 2^64 was already required).
- `top_fd_kernel`: the append block at the end of the slot loop becomes `top_slot(...)` (one plane-aggregated atomic
  on `grp_cnt[slot·nb + g]` when the plane's kept tops share a group — sorted prefixes almost always do — else one
  per kept lane) and the record write; the bucket-count loop and `top_b` store are gone. The stepped arithmetic above
  it is untouched (L48 touches only that part).
- `top_kernel` (pow-2 bases, the clipped blocks): one atomic per kept top on its group's counter, inside its branch
  (a uniform-flow plane append held the record across the branches; both forms compile to ~100 registers, §3).
- `join_kernel`: implicit work items (`slot = w / nb`); per item, threads `r < nroots` read their group's offset and
  count (`g_r = dkey·(b−1) + (root_r − cls − v) mod (b−1)`), thread 0 places the segments (serial scan, ≤ 8), and
  the batch load maps bucket position q to `s_db[r] + q` for the last segment starting at or before q (comptime
  `nroots`, unrolled). The item's list offset, entry base, count and key digit live in shared memory and are read
  per wave (keeps the kernel at ≤ 48 registers, §3). 3 barriers per work item (≈ 1 item per cube in production).
- `launch_batch`: top → bucket → join → check; `STAGES` 6 → 4; `top_scan_kernel`, `top_fill_kernel` deleted.
- `join_plan.rs`: the footprint drops `top_b`, `tl`, `work`, `cursor`, adds `goff`. Layouts shrink 11–29 %
  (b62 1e17 1671 → 1463 MiB, b62 1e16 2050 → 1825, b60 1e16 1566 → 1367, b64 1e16 2151 → 1519); slots per launch,
  slices and batches are unchanged on every field measured (6,439 / 532 / 1,350 / 683 batches).
- Test: the FD-vs-top-kernel device test compares per (slot, group) counts and the sorted records of every segment,
  and checks that every record's prefix belongs to its segment's group and no segment overruns.

## 2. Exactness (CUDA unless marked)

Tree S5 = `b058bb7` (the branch head; the squash has the same tree).

- `cubecl_cuda_join_matches_the_cpu_reference` (b10's 69, windows b20–b64 incl. b50/b54 after refused layouts, the
  b57 frontier partitions, sliced windows, the production shape): ok.
- `cubecl_cuda_top_fd_matches_the_top_kernel` (adapted): ok, 26 fields, 279 batches (23 with a clipped block),
  237,907,266 tops — the same totals as L38's run on the old layout.
- `cubecl_cuda_top_certificates_match_the_lockstep_scan_and_the_cpu`: ok, 102,365 intervals, 33,582 kept, 203,413
  above c0, 69,824 with the carry.
- Dense fields equal to the CPU join: b58 1e15, 32 partitions, 254,938,965 / 14,396,829; b62 1e16, 4 partitions,
  120,013,475 / 7,355,827.
- Whole b42 field: 417,789,835 join survivors, 16,879,877 checked, no hits; join = stride = CPU reference.
- `NICE_TEST_JOIN_COMPARE=1` at 1e14 (b57/60/62/64): join = stride, found 0; 4,850,227,888 / 268,123,373;
  2,694,700,282 / 180,517,288; 1,439,469,648 / 88,159,810; 5,702,041,796 / 346,647,759 (L38's).
- Every timed field, every round, both sides: b62 1e17 1,020,844,021,499 / 62,584,252,554; b62 1e16
  163,513,599,082 / 10,027,698,695; b60 1e16 460,847,952,346 / 30,871,838,404; b64 1e16 787,584,956,227 /
  47,900,853,327; the 1e14 set identical per side.
- `join_plan` and `cubecl_join` unit tests: ok.
- lavapipe (llvmpipe, LLVM 20.1.2, Mesa 25.2.8, 8-lane subgroups), every wgpu test of `cubecl_join` (CPU-reference
  parity incl. b50/b54, the FD-vs-top-kernel test on 21 fields / 142 batches / 1,018,088 tops, the certificate test,
  the production-field sample, the ticket test): ok with the naga (WGSL) compiler and with CubeCL's direct SPIR-V
  compiler (8 passed each).
- CI's WGSL lint (`wgsl_dump_for_lint` on lavapipe + `scripts/wgsl-lint.py` with the workflow's 13 `--require`s):
  14 shaders, 0 flagged (the two deleted kernels' shaders are gone; JoinKernel b57: 29 constant divisions).
- `cargo fmt --all --check`; `cargo clippy -p "*" --all-targets -- -D warnings`, default, with `--features
  nice_client/gpu` and with `--features nice_client/gpu,nice_client/cubecl-spirv` (rustc 1.99.1): clean.

Earlier trees S1–S4 (same design, other register shapes) passed the same CUDA list; their exactness logs are in
`raw/box/logs/` (S1) and were superseded only for registers.

## 3. Registers and spills (the runtime path)

Each process compiles its kernels through NVRTC; `ptxjit.py` replays the driver's JIT on its PTX cache. CubeCL's
source differs slightly from process to process, so the allocation moves; samples are per process.

| kernel | f3fb390 | static buckets (S5) |
|---|---|---|
| `join_kernel` | 47–48, no spills: 37 of 37 images (24 A/B processes, 3 sampling processes × 3 bases, one 4-base process) | 46–48 no spills in 30 of 37 (A/B 20 of 24, sampling 7 of 9, 3 of 4); 40 + 8–32 B spills in 7 |
| `top_fd_kernel` | 108–111 | 108–112 |
| `top_kernel` (b64 full; clipped blocks elsewhere) | 80 | 97–103 |
| `top_scan_kernel` / `top_fill_kernel` | 35–38 / 22–24 | gone |

- The join sits at the driver's 48-register line. The first build (runtime loops over the roots) went to 60
  registers or spilled; comptime `nroots` brought it back; moving the work item's header to shared memory took it to
  46–48. In some processes the driver JIT then allocates 40 registers and spills 8–32 bytes, in the per-work-item
  header and the per-wave entry load (in the b64 image read: `STL`/`LDL` at 0x0080–0x02a0 and 0x1240–0x12d0 of
  0x4d00, none in the chunk loop or the walk). Occupancy does not move either way: the join's shared memory (18.5 KB
  per cube, +84 bytes here) holds it at 5 cubes per SM.
- `top_kernel`'s 80 → ~100 registers is the same with either append form; it runs whole only at b64 (pow-2 base),
  where the field is ×1.22 faster anyway.

## 4. NiceMark and the top stage alone

NiceMark nice-only (`nice_client niceonly --gpu --benchmark --benchmark-secs 150`; each run took ~35 s), 6 rounds,
order alternating (B S5, S5 B, ...), clients built from the two trees (`client_B` md5 `bfe977d3`, `client_S5`
`41313eac`):

| | f3fb390 | static buckets | speed-up |
|---|---|---|---|
| **score** | 6626.3, 6639.7, 6654.9, 6681.4, 6594.3, 6637.0 (median **6638.4**) | 7385.0, 7415.9, 7460.6, 7372.2, 7501.0, 7446.0 (median **7431.0**) | **×1.119** (per round 1.114, 1.117, 1.121, 1.103, 1.138, 1.122) |
| b58 MSD-weak (whole field), n/s | 3.076e14 | 3.523e14 | ×1.145 |
| b58 MSD-strong (whole field) | 1.354e15 | 1.413e15 | ×1.043 |
| b60 MSD-weak (sampled) | 6.357e14 | 7.333e14 | ×1.153 |
| b62 MSD-weak (sampled) | 7.869e14 | 9.007e14 | ×1.145 |

The whole-field scenarios' join survivors are identical in all 12 runs (b58 MSD-weak 33,590,315,220, MSD-strong
4,027,773,430, as in L38); the sampled scenarios sample a different number of partitions per run (370–762), so their
survivor totals are not comparable, only their rates. MSD-strong gains least (×1.043); its top layer is the most
pruned, so its groups are the smallest and the most planes straddle two (a guess at the cause, not measured).

**The top stage alone** (`cubecl_cuda_top_fd_timing`: the first 40 batches of a production plan's first slice,
ns per top prefix and partition, 2 processes × 3 rounds per side, medians): the FD kernel with the sorted layer
and the group append is **×1.054–1.060 faster** on consecutive partitions (×1.032–1.036 with a seed every slot):
the nroots counting atomics and the `top_b` store it lost cost more than any divergence the sorted layer adds.
`top_kernel` is neutral despite its ~100 registers.

| field | kernel | f3fb390 ns/slot | static buckets | speed-up |
|---|---|---|---|---|
| b62 1e17 | `top_fd_kernel`, consecutive | 0.2291 | 0.2173 | ×1.054 |
| b62 1e17 | `top_fd_kernel`, every other | 0.3566 | 0.3456 | ×1.032 |
| b62 1e17 | `top_kernel`, consecutive / every other | 0.3629 / 0.3564 | 0.3610 / 0.3550 | ×1.005 / ×1.004 |
| b60 1e16 | `top_fd_kernel`, consecutive | 0.2283 | 0.2153 | ×1.060 |
| b60 1e16 | `top_fd_kernel`, every other | 0.3302 | 0.3187 | ×1.036 |
| b60 1e16 | `top_kernel`, consecutive / every other | 0.3403 / 0.3279 | 0.3424 / 0.3304 | ×0.994 / ×0.992 |

**Where the 13.7 s at b62 1e17 come from** [D, rough]: scan + fill 9.69 s (L45 §A, now gone) + the FD kernel ~1.3 s
(×1.054 on its 25.2 s) leaves ~2.7 s for the join's batch load (consecutive records instead of the `tl` read and the
id gather; L37 priced the gathers at 18.6 s on main, #241 took the first part) and two fewer launches per batch.

## 5. The rider (survivor stage once per top batch)

Branch `exp/join-static-buckets-s15` (`4b27507`, one commit on `b058bb7`): the join checks its shared survivor
stage once per top batch, after the batch's last wave, instead of after every chunk of 32 tops (two barriers and a
shared load per chunk). The first of its two barriers also orders the clip-word clear after every thread's last
chunk. Exact by construction (a full stage still sends its overflow straight to the list, as before).

Same box, after the main A/B; static buckets (S5) against S5 + rider (R), 3 interleaved rounds (S5 R, R S5, S5 R):

| field | S5 s/field (rounds) | R s/field (rounds) | speed-up (per round) | cycles | MHz S5 / R |
|---|---|---|---|---|---|
| **b62 1e17** | 86.27 (85.39, 86.58, 86.27) | **83.86** (83.60, 83.86, 84.60) | **×1.029** (1.021, 1.032, 1.020) | ×1.060 | 1504 / 1455 |
| b62 1e16 (2 fields) | 7.244 | 7.071 | ×1.024 (1.023, 1.032, 0.996) | ×1.037 | 1490 / 1485 |
| **b60 1e16** (2 fields) | 17.116 | **16.745** | **×1.022** (1.025, 1.008, 1.022) | ×1.034 | 1461 / 1448 |
| b64 1e16 (2 fields) | 23.144 | 22.465 | ×1.030 (1.031, 1.028, 1.035) | ×1.045 | 1466 / 1458 |

NiceMark, 2 rounds: score ×1.019 (per round 1.024, 1.014); b58 MSD-weak ×1.030, MSD-strong ×1.014, b60 ×1.009, b62
×1.024; whole-field join survivors identical. Counts identical in every timed run. Exactness on R: 1e14 COMPARE
(b57/60/62/64, L38's counts), CPU-reference parity, both dense fields (254,938,965 / 14,396,829; 120,013,475 /
7,355,827), the whole b42 field (417,789,835 / 16,879,877, no hits), the FD-vs-top-kernel and certificate device
tests (same totals), lavapipe naga and SPIR-V (8 passed each, FD test 21 / 142 / 1,018,088), WGSL lint (14 shaders,
0 flagged), fmt, clippy ×3 (re-run after `cargo clean -p`: the first run reused S5's artifacts from the shared
target dir and checked nothing). It repeats L45's ×1.020–1.023 on the new base. Since the review it is the second
commit of `pr/join-static-buckets` (`b7feb89`).

## 6. Review and fixes (after the GPU session; ivory only)

`REVIEW.md` (independent): merge with small fixes; the algebra re-derived, a host simulation of the segment
arithmetic against `cpu_join`'s rule on 24 fields matched. Applied on ivory (no box), branch `pr/join-static-buckets`
force-pushed with lease from `318fdae` to **`8e0eb99`** (the static bucket order, amended) + **`b7feb89`** (the rider,
retitled "Overlap join: check the survivor stage once per top batch", with a body):

- CHANGELOG: one line under Unreleased per commit, `#NNN` placeholders.
- `TOP_REC_WORDS` doc (the join reads records in order; only the check reads one by index); `top_fd_kernel`'s
  `let g = top_slot(..)` renamed `rec` (a record index); `top_slot`'s doc now says why keying on lane 0's group is
  harmless (lane 0 holds the plane's lowest index: a dead lane 0 is a dead plane; only planes straddling a group
  boundary can fall back to per-lane atomics needlessly). The review's "last partial plane" case does not fall back:
  its dead lanes are not kept, so they never fail the `plane_all`. No kernel code changed (no box to re-measure).
- The rider's stage comment no longer claims "none did on the production fields measured"; it states the overflow
  path instead.
- `run_tops`: a test-only `fill_sentinel` kernel writes `u32::MAX` over `top_rec` before each kernel's run; every
  counted record must have its seed word ≤ 1. Not run on a device yet (CI's lavapipe job is first).
- New host test `sorted_layer_and_segments_match_the_cpu_buckets` (trimmed from the review's patch): b10, the 17
  windows, b62 and b64 1e14; ~12 partitions each, two slots; 492,116 buckets; 8 s in debug on ivory. A mutation
  (`− v` → `+ v` in the segment formula) makes it fail.
- PR body: registers reworded as above; the rider has its own section (table, NiceMark, the overflow argument) and is
  out of "Not in this PR"; the `nroots ≤ 8` check marked new; `top_kernel`'s 80 → ~100 registers not timed alone at
  b64 (the whole-field ×1.222 covers it).
- Run on ivory (`CARGO_TARGET_DIR` in the worktree, `nice -n 19`, removed after): `cargo check -p nice_common
  --features gpu --all-targets`; `cargo test -p nice_common --features cubecl --lib -- join_plan:: cubecl_join::`
  (12 passed, 8 device tests ignored) on both commits; `cargo fmt --all --check`; `cargo clippy -p nice_common
  --all-targets -D warnings` with `--features cubecl` and with `--features gpu`, both commits: clean. Not run: any
  device test (no GPU, no lavapipe on ivory), clippy of the other crates (unchanged).

## 7. Files and branches

- Fork branches: `exp/join-static-buckets` (`b058bb7`, the six working commits), `pr/join-static-buckets`
  (`8e0eb99` + `b7feb89` on `f3fb390` after the review fixes, PR body `PR-BODY.md`; no PR opened),
  `exp/join-static-buckets-s15` (the rider as measured, `4b27507` on `b058bb7`).
- `DESIGN.md`; `raw/scripts/` (setup, build, run, test, chain_x/post/ab/lvp/lint/rider, regsample, ptxjit, ab.py,
  nm_table.py, topt.py); `raw/box/` (logs, SASS).
