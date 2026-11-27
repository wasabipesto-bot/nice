# Base 65 on the wide path: tops and parents (2026-11-27, 05:48–08:53 UTC)

Brief: `BRIEF-LEVERS.md`. Machine: eventeo, RTX 3060 12 GB (nvidia-smi 1, wgpu `DiscreteGpu(1)`) for every timing
and test unless stated; GTX 1060 3 GB (index 0) only for the memory check and one Vulkan test after the timing.
Every process sourced `~/research/scripts/env.sh`; nothing contacted the production API. Logs: `runs/levers/` (one directory per run set, build logs, lint logs)
(per run `.log`, `.gpu` = nvidia-smi every 0.5 s, `.cpu` = vmstat). Scripts: `scripts/levers/`. Numbers are field
t 77777 after the warm-up field 13731 in the same process; ms per slice = field s / 4,225 (b65) or 4,096 (b64).

## Verdict

- **Branch `dev/mo-wide-b65` on the fork, 3 commits on `0b6e22e1`: base 65 is 6.3 % faster per field through CUDA
  (6.426 → 6.020 fs per admissible n) and 7.2 % through Vulkan/SPIR-V (6.201 → 5.754); base 64 on the wide path
  5.1 % (3.596 → 3.413).** Counts of both b65 fields and the b64 field equal yesterday's; all wide tests pass on
  both runtimes; fault messages unchanged (one account dump differs, see Tests).
- **Step 1 (tops): 2.57 → 2.22 ms per slice (CUDA), 3.04 → 2.39 (Vulkan). The 2.0 ms kill line is not met on
  CUDA**, so per the brief it stops there. The bound is not launch shape or latency (measured, below): the stage
  is the certificate arithmetic of `wtops1` (compute, ~0.94 ms) plus memory traffic of the placement.
- **Step 2 (parents): the narrow path's sharing ported; parents 2.83 → 1.73 ms per slice (CUDA, −1.10), 2.82 →
  1.80 (Vulkan, −1.01).** Cost: +0.96 GB of card memory at b65 (65 lists).

## Step 1: what bounds the tops stage

**Measured split** (baseline `0b6e22e1`, CUDA, scratch cumulative sub-stop `MIDOUT_TSTOP` inside `MIDOUT_STOP=1`,
one cold process each; `runs/levers/levers-tops/`):

| kernel (cumulative) | field s | ms/slice (stage) | card while it runs |
|---|---|---|---|
| host only (no top kernel: uploads, allocations) | 0.52 | 0.12 | 23 %, 34 W |
| + `wtops5` (once per 65 slices) | 0.73 | 0.05 | |
| + `wtops1` (certificates of the ~2.84M valid-parent prefixes) | 5.11 | **1.04** | 98 %, 157 W |
| + `wscan` | 5.16 | 0.01 | |
| + `wtops2` (scatter of ~1.70M tops into 4,160 segments) | 9.55 | **1.04** | 99 %, 144 W |
| + `wtdigz` (digit table) | 10.85 | 0.31 | 99 %, 148 W |
| **stage** | | **2.57** | below the 170 W cap |

What it is not, and what it is (each a measurement, `runs/levers/levers-tcap/`, `levers-tvar/`):
- **Not launch shape / too few threads:** capping the top kernels' grids at 4,096 / 1,024 / 256 cubes gives
  2.35 / 2.55 / 2.96 ms (the default has 13k cubes); fewer threads only hurt. Not launch latency: ~5 launches per
  slice, and the card is 98–99 % busy through the stage. No serial step: `wscan` (one cube) is 0.01 ms.
- **`wtops1` is compute-bound** (98 % busy, ~2,100 thread-instructions per prefix by the timing): squares and cubes
  of both interval ends in 7 base-b² limbs and the certificate walk. Its per-prefix writes cost ~0.1 ms
  (removed by the change below).
- **`wtops2` was bound by its five scattered writes per top**, not by work or atomics: with the writes made
  coalesced and the atomic kept it took 0.44 ms; with neither 0.36 ms; as built 0.87 ms (after compaction).
- On the 3080 claim: the stage scales with work here (b65 has 6.4× the prefixes of b64: 13.4M vs 2.1M, and costs
  6× b64's 0.43 ms). I could not test a 3080; the 11-19 "same 2.6 ms" was first code and is not reproduced as a
  latency bound on this card.

**The change** (`19be987c`): `wtops1` appends each certified top to a compact list (ballot, one atomic per plane;
the grid-stride loop runs whole cubes per round so every ballot has all lanes active); `wtops2` places each listed
record whole (one 32-byte write per top); `wtdigz` unpacks the placed records into the per-slot arrays in slot
order beside the digit table. Per-prefix arrays (375 MB at b65) replaced by two lists of the tops cap (2 × 96 MB).

Tried and dropped: **squaring the prefix's 5 limbs instead of the ends' 7** (`wtops1` fast path for unclipped
prefixes, exact on every test incl. brute force on CUDA): 2.282 / 2.289 ms against 2.213 / 2.227 without it, i.e.
**slower** (more live registers, I assume; not profiled: `ncu` needs admin counters). Kept as
`runs/levers-patches/0001-…patch`, not on the branch. That the multiply count does not move the time says
`wtops1` is bound by register pressure / instruction mix rather than limb products; the next try would be a
profile with counters (needs the owner to set `RmProfilingAdminOnly=0`) before any rewrite. `nsys` 2023.4 is
installed but its importer fails on this machine ("Wrong event order"), so the split above is by sub-stops.

## Step 2: parents shared across the slice's top digit

**The change** (`a7ea3890`): a port of `anc8_kernel` and its field driver. `wanc_kernel` is `parent_w` one digit
shallower: per value of the slice digits [f0, k − 2) (b keys per (4, 8, 5) field) it lists the roots whose
depth-(k − 2) ancestor is valid; `whist` runs over the list. Exact by containment (digits 0..k − 3 of r², r³ depend
only on r mod b^(k−2)). Built at the field's start, one sync, accounts checked (cubes, examined, listed, plane
errors); `whist`'s cube account follows the list length (`WHead.hn`); new fault `F_SKIP_ANC`. `rank_of`,
`run_slice` and hence the sampled check's device rerun stay unshared (an independent check of the shared path in
production). Bench flag `--no-share-parents`. It was a port, not a redesign (kill criterion not met).

**Memory at base 65:** 10,892,331 roots; a list holds 20.9 % (longest 2,279,681; mean/longest equal to 0.1 %);
capacity per list 3/8 of the roots = 4,088,719 → 65 lists = 1.06 GB. Peak card memory (nvidia-smi, whole-field runs):
CUDA 4,910 → 5,870 MiB, Vulkan 5,393 → 6,379 MiB (the tops change gives back ~0.7 GB at stop 1, measured 4,910 →
4,174 MiB). GTX 1060 3 GB (`runs/levers/levers-1060/`): tops + parents (stop 2) fit, 2,623 of 3,072 MiB with the lists, and run faster there too (stop 2: 99.2 → 63.1 s per field; unshared head 81.9 s; stop 1: 57.2 → 41.3 s). **A whole b65 field does not fit a 3 GB card before or after** (baseline, head and head unshared all fail loudly, "0 of 133120 job instances ran", the allocation-failure account), so sharing removes no card that could run b65. The capacity could drop to ~1/4 of the roots (−0.33 GB) since the
lists vary by < 0.1 %; not done (base 70's expected 23.6 % would then be close to the cap).

## Before / after (same session 07:33–08:22, alternating; RTX 3060; `runs/levers/levers-final-ab/`)

Baseline `0b6e22e1`; "step 1" = `19be987c`; "1+2" = `a7ea3890`. Two rounds each; per-slice ms of the stage from
the cumulative stops, fs per admissible n of the whole field.

| runtime | measure | baseline | step 1 | steps 1+2 | change |
|---|---|---|---|---|---|
| CUDA | tops (stop 1) ms/slice | 2.559, 2.575 | = 1+2 | 2.213, 2.227 | **−0.35 (−13.5 %)** |
| CUDA | parents (stop 2 − stop 1) ms/slice | 2.842, 2.826 | — | 1.742, 1.726 | **−1.10** |
| CUDA | **whole field fs** | 6.4274, 6.4241 | 6.3426, 6.3425 (−1.3 %) | 6.0174, 6.0234 | **−6.3 %** |
| Vulkan/SPIR-V | tops ms/slice | 3.051, 3.032 | = 1+2 | 2.400, 2.386 | **−0.65 (−21 %)** |
| Vulkan/SPIR-V | parents ms/slice | 2.800, 2.831 | — | 1.792, 1.810 | **−1.01** |
| Vulkan/SPIR-V | **whole field fs** | 6.2009, 6.2017 | — | 5.7507, 5.7579 | **−7.2 %** |
| CUDA, b64 wide | whole field fs (once) | 3.5960 | — | 3.4133 | −5.1 % (narrow b64: 3.27) |

- Card beside every run (`ab_table.py`): whole fields CUDA 100 % busy, 162–164 W (at the 170 W cap), 1,777–1,785
  MHz; Vulkan 97–98 %, 164–165 W. Stop-1 runs 99 % / 135–150 W; stop-2 runs 99–100 % / 140–148 W.
- Counts (survivors, checked, tops, children, chunks, flat, kept, slices) of every whole-field run, both b65 fields,
  equal `runs/reads-bench/c_reads_q.log` (yesterday); the b64 field equals `c64_base.log`.
- Step 1 alone on the whole field is −1.3 % (just above the 1 % line); the stage gain is larger on Vulkan.
- One timing caveat: `cu_fin_s2_1` ran while I copied a 1.3 GB target dir on the host for ~10 s; it equals its
  round-2 repeat (3.955 vs 3.953 ms).

## Tests (say which runtime)

| test | CUDA (RTX 3060) | Vulkan/SPIR-V (RTX 3060) |
|---|---|---|
| tier `cubecl_midout_wide*` (3) | ok (c2, c3) | ok (c3) |
| `wide_slices_equal_cpu` (b65 slice; now also **tops = `cpu::unit_tops`, unit, lead and mask**) | ok (c1 alone, c2, c3) | ok (c3) |
| `wide_faults_are_loud` | ok (c2, c3) | ok (c3) |
| `wide_field_parent_sharing_is_exact_and_loud` (new: 130 slices equal shared/unshared, 5 faults loud) | ok (c3) | ok (c3; the process segfaults at exit after "1 passed", the known SPIR-V exit crash) |
| `wide_whole_small_bases_vs_brute_force` | ok (c3; also the dropped fast path) | ok on the GTX 1060 through Vulkan (c3) |
| narrow `gpu_slices_equal_cpu`, `accounts_faults_are_loud`, `field_parent_sharing_is_exact_and_loud` | ok (c3) | — |

c1 = `8f8ab3c1`, c2 = `19be987c`, c3 = `a7ea3890` (eventeo built the same trees from patches: tree hashes checked).
Runs: `runs/levers/levers-{s1a,s1b,s2a,c4,final}-tests/`.

- **Fault messages:** byte-identical to yesterday's `reads-tests` on both runtimes except one: `F_SKIP_TOPS` fails
  on the same check with the same text, and its account dump's word 3 (`wtops2` placed) is now 0 instead of
  1,693,682 — the old `wtops2` placed stale per-prefix flags left by the previous slice; the compact list is empty.
- **Lint** (ivory, `nice -n 19`, own target dir): `just lint` (fmt check, clippy default, clippy
  `nice_client/gpu,nice_client/cubecl-spirv`) and clippy `-p nice_common --all-targets` with
  `cubecl-cuda,midout-box-tests,midout-bench` and with `cubecl-spirv,midout-box-tests,midout-bench`: all pass on
  `a7ea3890` (only the existing `web-sys` manifest warning).

## Step 3 (note): wide vs narrow expansion

Same record walk, same plane-sized take, same per-bit prefilter family. The wide kernel does per **record** what the
narrow one reads ready-made:
1. `wrec_top`: the record holds (probe slot, unit, class), not the top index, so each record loops over the roots'
   classes reading `tseg` twice per root and `pseg` three times (dependent loads) to find its top and child-list
   position. The narrow record carries the top index (and `thd[top]`) directly.
2. `wtop_ctx`: a division and a modulo by the runtime `nlead`, u64 prefix arithmetic and the clip compares per
   record; narrow reads the top's (h, d) packed.
3. Per **bit**, the h-digit split (`h % b`, `(h − h0)/b % b`) and `pf_w2_fixed` are recomputed though they depend only
   on the record's top.
Closing it: (a) hoist the per-top values out of the bit loop (kernel-local, small); (b) a per-slot top context
(h digits, unit, clip bounds, small-n flag, prefilter mask) written once per top by `wtdigz` — the new slot-order
pass makes this cheap — so the expansion does one 16-byte load instead of `wtop_ctx`; (c) the main kernel writing
the top index into the record (record layout change, main kernel touched) to drop `wrec_top`. (a)+(b) are a day;
(c) more. Worth at most the b64 gap (2.58 vs 2.00 ms, +29 %), i.e. ~4 % of the b65 field.

## Not done

- Tops under 1.5 ms (and under 2.0 on CUDA): not reached; the bound is `wtops1`'s arithmetic, needs counters.
- The fast path (dropped, slower). Tightening the list capacity. The 3080 re-measure (no such card).
- Brute-force small bases through Vulkan on the RTX 3060 (it ran on the 1060 instead, after the timing).
- No pull request; nothing pushed to `origin` or `dev/mo-mode`.

## Energy and eventeo state

- Wall energy over 05:47–08:53 UTC (`scripts/energy.py`): **0.556 kWh** (counter 1.56 → 2.11), mean 178 W, peak
  297 W; about $0.10.
- **eventeo powered off at 08:52:31 UTC** by `off_if_idle.sh` (nothing of mine running, nobody else logged in);
  ssh from ivory gone 5 s later and timed out on a re-check.
- Every process I stopped was mine and killed by recorded PID (`runs/levers/pids.txt`: the waiting first A/B
  driver, the deferred Vulkan brute-force test of the dropped variant). No `pkill`/`pgrep -f`.
- Added there (one changelog line in `~/SYSTEM_STATE.md`): worktrees `.worktrees/{levers,b65l,b65l2}`, target dirs
  `research/t/{levers,levers-rel,b65l,b65l-rel,b65l2}` (8.1 GB, deletable), binaries `research/bin/{l-,s1a-,s1b-,
  s2a-,c1-,c2-,c4-,fin-}*`, runs `research/runs/levers-*`, scripts `research/b65l/`.
- Branch `dev/mo-wide-b65` pushed to `fork` only (new branch, no force, no amend of a pushed commit, no PR); the
  local fast-path commit was dropped before the push. Ivory worktree: `~/projects/nice/.worktrees/mo-wide-b65`.
